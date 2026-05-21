"""CLI entry points for harness-run and harness-heartbeat."""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

from . import config as cfgmod
from . import engine, jsonl
from .models import Report, RunMeta, RunResult


def run_main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:]) if argv is None else list(argv)
    # Split on '--' first to keep argparse from eating child-side flags
    if "--" not in argv:
        print(
            "Usage: harness-run <task> [OPTIONS] -- <command> [args...]",
            file=sys.stderr,
        )
        return 2
    sep = argv.index("--")
    pre, child_cmd = argv[:sep], argv[sep + 1 :]
    if not child_cmd:
        print("Error: no child command after '--'.", file=sys.stderr)
        return 2

    parser = argparse.ArgumentParser(
        prog="harness-run",
        description="Wrap a child process with observability (Notion + Slack).",
        usage="harness-run <task> [OPTIONS] -- <command> [args...]",
    )
    parser.add_argument("task", help="Task name (e.g., morning-brief)")
    parser.add_argument("--timeout", type=int, default=None, metavar="SEC")
    parser.add_argument("--label", action="append", default=[], metavar="K=V")
    parser.add_argument(
        "--trigger", choices=["cron", "manual", "schedule", "event"], default=None
    )
    parser.add_argument("--grace-secs", type=int, default=5)
    parser.add_argument("--no-notion", action="store_true")
    parser.add_argument("--no-alert", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--config", type=Path, default=None)

    args = parser.parse_args(pre)

    cfg = cfgmod.load(args.config)

    # Kill switch — transparent passthrough
    if cfgmod.is_disabled(cfg):
        if not args.dry_run:
            os.execvp(child_cmd[0], child_cmd)
        print(f"[dry-run] kill switch ON → would exec: {child_cmd}", file=sys.stderr)
        return 0

    labels = _parse_labels(args.label)

    if args.dry_run:
        print(
            f"[dry-run] task={args.task} timeout={args.timeout} grace={args.grace_secs} "
            f"no_notion={args.no_notion} no_alert={args.no_alert} labels={labels}",
            file=sys.stderr,
        )
        print(f"[dry-run] would exec: {child_cmd}", file=sys.stderr)
        return 0

    return engine.run(
        task=args.task,
        command=child_cmd,
        cfg=cfg,
        timeout_s=args.timeout,
        grace_secs=args.grace_secs,
        trigger=args.trigger,
        no_notion=args.no_notion,
        no_alert=args.no_alert,
        labels=labels,
    )


def heartbeat_main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="harness-heartbeat",
        description="Self-report helper for harness-wrapped automations.",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    rep = sub.add_parser("report", help="Submit a self-report")
    rep.add_argument("--status", choices=["ok", "warn", "fail"], required=True)
    rep.add_argument("--summary", required=True)
    rep.add_argument("--detail", action="append", default=[], metavar="K=V")
    rep.add_argument("--detail-json", default=None)
    rep.add_argument("--task", default=None, help="Required if no HARNESS_RUN_ID")
    rep.add_argument("--config", type=Path, default=None)

    args = parser.parse_args(argv)

    if args.cmd != "report":
        parser.error("Only 'report' subcommand is supported in v1.")

    cfg = cfgmod.load(args.config)
    if cfgmod.is_disabled(cfg):
        print("[harness] disabled, helper no-op", file=sys.stderr)
        return 0

    detail = _parse_labels(args.detail)
    if args.detail_json:
        try:
            detail.update(json.loads(args.detail_json))
        except json.JSONDecodeError as e:
            print(f"[harness-heartbeat] bad --detail-json: {e}", file=sys.stderr)
            return 1

    report = Report(status=args.status, summary=args.summary, detail=detail)

    row_id = os.environ.get("HARNESS_BACKEND_REF")
    run_id = os.environ.get("HARNESS_RUN_ID")

    from .backends.notion import NotionBackend
    backend = NotionBackend(cfg.backend.token, cfg.backend.data_source_id)

    if row_id and run_id:
        # Mode A — wrapped
        backend.patch_report(row_id, report)
        jsonl.append(
            cfg.state_dir / "state.jsonl",
            {
                "type": "report",
                "run_id": run_id,
                "status": args.status,
                "summary": args.summary,
                "detail": detail,
            },
        )
    else:
        # Mode B — standalone
        if not args.task:
            print(
                "[harness-heartbeat] standalone mode requires --task",
                file=sys.stderr,
            )
            return 1
        import socket
        from datetime import timezone, timedelta
        kst = timezone(timedelta(hours=9))
        now = datetime.now(kst)
        meta = RunMeta(
            run_id=engine.make_run_id(),
            task=args.task,
            started_at=now,
            host=socket.gethostname(),
            user=cfg.identity.user,
            trigger="manual",
        )
        rid = backend.open(meta)
        backend.patch_report(rid, report)
        result = RunResult(
            ended_at=now,
            duration_s=0,
            exit_code=0,
            status=args.status if args.status != "ok" else "ok",  # type: ignore[arg-type]
            stdout_tail=[],
        )
        backend.close(rid, meta, result)

    return 0


def _parse_labels(items: list[str]) -> dict[str, object]:
    out: dict[str, object] = {}
    for item in items:
        if "=" not in item:
            continue
        k, v = item.split("=", 1)
        # Try to interpret as number
        try:
            out[k] = int(v)
        except ValueError:
            try:
                out[k] = float(v)
            except ValueError:
                out[k] = v
    return out
