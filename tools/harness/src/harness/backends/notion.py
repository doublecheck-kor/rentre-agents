"""Notion backend — stores rows in a Heartbeat database via REST API."""

from __future__ import annotations

import json
import sys
from datetime import datetime
from typing import Any

import requests

from ..models import Report, RunMeta, RunResult, Status

NOTION_API = "https://api.notion.com/v1"
NOTION_VERSION = "2022-06-28"
TIMEOUT_S = 10


class NotionBackend:
    """Pages-as-rows backend. Expects a database with columns defined in the design doc.

    Property name conventions (must match the DB schema):
      - 실행 (title)
      - 작업 종류 (select)
      - 상태 (select)
      - 시작 시각 (date)
      - 종료 시각 (date)
      - 소요(초) (number)
      - Exit Code (number)
      - 사용자 (rich_text)
      - 호스트 (rich_text)
      - 트리거 (select)
      - 요약 (rich_text)
      - 도메인 컨텍스트 (rich_text)
      - stdout 마지막 5줄 (rich_text)
    """

    def __init__(self, token: str | None, data_source_id: str | None):
        self.token = token
        self.data_source_id = data_source_id
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {token}" if token else "",
                "Notion-Version": NOTION_VERSION,
                "Content-Type": "application/json",
            }
        )

    def _enabled(self) -> bool:
        return bool(self.token and self.data_source_id)

    def open(self, meta: RunMeta) -> str | None:
        if not self._enabled():
            print("[notion] disabled (no token or data_source_id)", file=sys.stderr)
            return None

        title = f"{meta.task} — {meta.started_at.strftime('%Y-%m-%d %H:%M')} — running"
        body: dict[str, Any] = {
            "parent": {"type": "data_source_id", "data_source_id": self.data_source_id},
            "properties": {
                "실행": {"title": [{"text": {"content": title}}]},
                "작업 종류": {"select": {"name": meta.task}},
                "상태": {"select": {"name": "running"}},
                "시작 시각": {"date": {"start": meta.started_at.isoformat()}},
                "사용자": _rich(meta.user),
                "호스트": _rich(meta.host),
                "트리거": {"select": {"name": meta.trigger}},
            },
        }
        if meta.rentre_version:
            body["properties"]["rentre-agents 버전"] = _rich(meta.rentre_version)

        try:
            r = self.session.post(f"{NOTION_API}/pages", json=body, timeout=TIMEOUT_S)
            r.raise_for_status()
            return r.json().get("id")
        except Exception as e:
            print(f"[notion] open failed: {e}", file=sys.stderr)
            return None

    def close(self, row_id: str | None, meta: RunMeta, result: RunResult) -> None:
        if not row_id or not self._enabled():
            return

        title = f"{meta.task} — {meta.started_at.strftime('%Y-%m-%d %H:%M')} — {_status_emoji(result.status)}"
        body: dict[str, Any] = {
            "properties": {
                "실행": {"title": [{"text": {"content": title}}]},
                "상태": {"select": {"name": result.status}},
                "종료 시각": {"date": {"start": result.ended_at.isoformat()}},
                "소요(초)": {"number": result.duration_s},
                "Exit Code": {"number": result.exit_code},
                "stdout 마지막 5줄": _rich("\n".join(result.stdout_tail[-5:])),
            }
        }
        if result.log_file_url:
            body["properties"]["로그 파일"] = {"url": result.log_file_url}

        try:
            r = self.session.patch(
                f"{NOTION_API}/pages/{row_id}", json=body, timeout=TIMEOUT_S
            )
            r.raise_for_status()
        except Exception as e:
            print(f"[notion] close failed: {e}", file=sys.stderr)

    def patch_report(self, row_id: str | None, report: Report) -> None:
        if not row_id or not self._enabled():
            return

        body: dict[str, Any] = {
            "properties": {
                "요약": _rich(report.summary),
            }
        }
        # 도메인 컨텍스트는 JSON으로 직렬화
        if report.detail:
            body["properties"]["도메인 컨텍스트"] = _rich(
                json.dumps(report.detail, ensure_ascii=False, indent=2)
            )
        # status는 악화 방향만 — 여기선 worsen logic은 engine 측에서 처리, 그냥 patch
        # 단, ok로 회복은 막아야 함: 우선 현재 row의 상태를 읽어서 비교 (best-effort)
        new_status = _worsen_only(self._read_status(row_id), report.status)
        if new_status:
            body["properties"]["상태"] = {"select": {"name": new_status}}

        try:
            r = self.session.patch(
                f"{NOTION_API}/pages/{row_id}", json=body, timeout=TIMEOUT_S
            )
            r.raise_for_status()
        except Exception as e:
            print(f"[notion] patch_report failed: {e}", file=sys.stderr)

    def poll_report(self, row_id: str | None) -> Report | None:
        if not row_id or not self._enabled():
            return None
        try:
            r = self.session.get(f"{NOTION_API}/pages/{row_id}", timeout=TIMEOUT_S)
            r.raise_for_status()
            props = r.json().get("properties", {})
            summary = _read_rich(props.get("요약"))
            if not summary:
                return None
            status_obj = props.get("상태", {}).get("select") or {}
            return Report(
                status=status_obj.get("name", "ok"),  # type: ignore[arg-type]
                summary=summary,
                detail={},  # not needed for grace polling logic
            )
        except Exception:
            return None

    def row_url(self, row_id: str | None) -> str:
        if not row_id:
            return ""
        return f"https://www.notion.so/{row_id.replace('-', '')}"

    def _read_status(self, row_id: str) -> Status | None:
        try:
            r = self.session.get(f"{NOTION_API}/pages/{row_id}", timeout=TIMEOUT_S)
            r.raise_for_status()
            props = r.json().get("properties", {})
            s = props.get("상태", {}).get("select")
            return s.get("name") if s else None
        except Exception:
            return None


def _rich(text: str) -> dict[str, Any]:
    return {"rich_text": [{"text": {"content": text[:2000]}}]}


def _read_rich(prop: dict | None) -> str:
    if not prop:
        return ""
    items = prop.get("rich_text") or prop.get("title") or []
    return "".join(seg.get("plain_text", "") for seg in items)


def _status_emoji(s: Status) -> str:
    return {
        "ok": "✅",
        "warn": "⚠️",
        "fail": "❌",
        "timeout": "⏱️",
        "missing-report": "🟠",
        "running": "🔄",
    }.get(s, s)


_STATUS_RANK = {"ok": 0, "warn": 1, "fail": 2, "missing-report": 2, "timeout": 2}


def _worsen_only(current: Status | None, new: str) -> str | None:
    """Return the new status only if it's same-or-worse than current."""
    if current is None:
        return new
    if new not in _STATUS_RANK:
        return None
    if _STATUS_RANK.get(new, 0) >= _STATUS_RANK.get(current, 0):
        return new
    return None
