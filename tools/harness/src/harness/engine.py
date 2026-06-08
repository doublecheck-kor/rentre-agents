"""Engine — state machine that wraps a child process."""

from __future__ import annotations

import os
import signal
import socket
import subprocess
import sys
import threading
import time
import uuid
from collections import deque
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Any

from . import jsonl
from .config import Config
from .debounce import DebounceStore
from .models import AlertEvent, Report, RunMeta, RunResult, Status


KST = timezone(timedelta(hours=9))


def now_kst() -> datetime:
    return datetime.now(KST)


def make_run_id() -> str:
    return str(uuid.uuid4())


def detect_trigger() -> str:
    if os.environ.get("CRON") == "1" or os.environ.get("INVOCATION_ID"):
        return "cron"
    # heuristic: no tty + parent isn't shell-y → cron-ish
    if not sys.stdin.isatty():
        return "cron"
    return "manual"


def run(
    task: str,
    command: list[str],
    cfg: Config,
    timeout_s: int | None = None,
    grace_secs: int = 5,
    trigger: str | None = None,
    no_notion: bool = False,
    no_alert: bool = False,
    labels: dict[str, str] | None = None,
) -> int:
    """Execute the wrapper state machine. Returns the child's exit code."""

    run_id = make_run_id()
    started = now_kst()
    host = socket.gethostname()
    user = cfg.identity.user
    trig = trigger or detect_trigger()

    meta = RunMeta(
        run_id=run_id,
        task=task,
        started_at=started,
        host=host,
        user=user,
        trigger=trig,  # type: ignore[arg-type]
    )

    # Backend (lazy import so tests can skip requests dependency)
    backend: Any
    if no_notion or cfg.backend.type != "notion":
        backend = _NullBackend()
    else:
        from .backends.notion import NotionBackend
        backend = NotionBackend(cfg.backend.token, cfg.backend.data_source_id)

    state_file = cfg.state_dir / "state.jsonl"
    log_dir = cfg.state_dir / "logs" / task
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / f"{started.strftime('%Y%m%dT%H%M%S')}-{run_id[:8]}.log"

    # [BASELINE]
    row_id = backend.open(meta)
    jsonl.append(
        state_file,
        {
            "type": "open",
            "run_id": run_id,
            "task": task,
            "start_ts": started.isoformat(),
            "host": host,
            "user": user,
            "trigger": trig,
            "backend_row_id": row_id,
        },
    )

    # Env for child
    child_env = os.environ.copy()
    child_env["HARNESS_RUN_ID"] = run_id
    child_env["HARNESS_TASK"] = task
    child_env["HARNESS_START_TS"] = started.isoformat()
    child_env["HARNESS_HOST"] = host
    if row_id:
        child_env["HARNESS_BACKEND_REF"] = row_id

    # [EXEC]
    tail: deque[str] = deque(maxlen=200)
    log_fh = log_path.open("w", encoding="utf-8", buffering=1)

    def _drain(stream, prefix):
        for line in iter(stream.readline, ""):
            tail.append(line.rstrip("\n"))
            log_fh.write(line)
            # tee to parent (so cron logs still see it)
            (sys.stderr if prefix == "stderr" else sys.stdout).write(line)
        stream.close()

    proc = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=child_env,
        text=True,
        bufsize=1,
    )

    t_out = threading.Thread(target=_drain, args=(proc.stdout, "stdout"), daemon=True)
    t_err = threading.Thread(target=_drain, args=(proc.stderr, "stderr"), daemon=True)
    t_out.start()
    t_err.start()

    timed_out = False
    try:
        if timeout_s:
            try:
                proc.wait(timeout=timeout_s)
            except subprocess.TimeoutExpired:
                timed_out = True
                proc.send_signal(signal.SIGTERM)
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()
        else:
            proc.wait()
    except KeyboardInterrupt:
        proc.send_signal(signal.SIGINT)
        proc.wait()

    t_out.join(timeout=1)
    t_err.join(timeout=1)
    log_fh.close()

    ended = now_kst()
    exit_code = 124 if timed_out else (proc.returncode or 0)
    duration_s = int((ended - started).total_seconds())

    # 1차 status
    if timed_out:
        status: Status = "timeout"
    elif exit_code != 0:
        status = "fail"
    else:
        status = "ok"  # may be downgraded after GRACE

    # [GRACE] — poll for self-report (only when exit_code == 0)
    if status == "ok" and grace_secs > 0:
        deadline = time.time() + grace_secs
        report = None
        while time.time() < deadline:
            report = backend.poll_report(row_id)
            if report and report.summary:
                # Self-report present; respect its status if worse
                if report.status == "fail":
                    status = "fail"
                elif report.status == "warn":
                    status = "warn"
                break
            time.sleep(1)
        if not report or not report.summary:
            status = "missing-report"

    result = RunResult(
        ended_at=ended,
        duration_s=duration_s,
        exit_code=exit_code,
        status=status,
        stdout_tail=list(tail)[-5:],
        log_file_url=f"file://{log_path}",
    )

    # [FINALIZE]
    backend.close(row_id, meta, result)
    jsonl.append(
        state_file,
        {
            "type": "close",
            "run_id": run_id,
            "end_ts": ended.isoformat(),
            "duration_s": duration_s,
            "exit_code": exit_code,
            "status": status,
            "log_file": str(log_path),
        },
    )

    # [ALERT]
    if not no_alert and status in {"fail", "timeout", "missing-report", "warn"}:
        from .alerters.slack import SlackAlerter
        alerter = SlackAlerter(
            bot_token=cfg.alerter.bot_token,
            webhook_url=cfg.alerter.webhook_url,
            dm_channel=cfg.alerter.dm_channel,
            broadcast_channel=cfg.alerter.broadcast_channel,
        )
        # warn은 broadcast 빼고 DM만 — SlackAlerter 내부에서 처리
        debounce = DebounceStore(
            cfg.state_dir / "alerts.json",
            cfg.alerter.debounce_window_secs,
            cfg.alerter.hourly_rate_limit,
        )
        decision = debounce.decide(task, status)
        # Get report summary from final row
        final_report = backend.poll_report(row_id) if row_id else None
        event = AlertEvent(
            run_id=run_id,
            task=task,
            status=status,  # type: ignore[arg-type]
            started_at=started,
            ended_at=ended,
            duration_s=duration_s,
            exit_code=exit_code,
            host=host,
            summary=final_report.summary if final_report else None,
            detail=None,
            stdout_tail=list(tail)[-5:],
            backend_row_url=backend.row_url(row_id),
            repeat_count=decision.repeat_count,
        )
        try:
            if decision.action == "new":
                refs = alerter.notify(event)
                if refs:
                    debounce.record_refs(task, status, refs)
            elif decision.action == "update" and decision.message_refs:
                alerter.update(decision.message_refs, event)
            else:
                print(f"[alert] skipped (rate-limited or no-op)", file=sys.stderr)
        except Exception as e:
            print(f"[alert] dispatcher error: {e}", file=sys.stderr)

    return exit_code


class _NullBackend:
    def open(self, meta): return None
    def close(self, row_id, meta, result): pass
    def patch_report(self, row_id, report): pass
    def poll_report(self, row_id): return None
    def row_url(self, row_id): return ""
