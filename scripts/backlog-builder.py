#!/usr/bin/env python3
"""Rentre 백로그 빌더 — 페이로드 생성, 프로퍼티 검증, 품질 체크, 제목 검증, content 템플릿.

Usage:
    python3 scripts/backlog-builder.py payload --type Task --title "제목" [--priority Medium] [--props '{"SP":"3"}']
    python3 scripts/backlog-builder.py validate --payload '{"properties": {...}}'
    python3 scripts/backlog-builder.py check-title --type Task --title "제목"
    python3 scripts/backlog-builder.py template --type Task
    python3 scripts/backlog-builder.py quality --type Task --title "제목" --payload '{"properties": {...}}'
"""

import argparse
import json
import os
import re
import sys

# === Config ===

CONFIG_PATH = os.path.expanduser("~/.claude/rentre-config.json")


def _load_datasource_id():
    """Load notion_backlog_datasource from rentre-config.json."""
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH) as f:
            cfg = json.load(f)
        ds = cfg.get("notion_backlog_datasource", "")
        if ds and not ds.startswith("{{"):
            return ds
    return None


# === Schema ===

TEMPLATE_IDS = {
    "Initiative": "2a848a03-3208-8031-b35b-c8c63a4b1fa9",
    "Epic": "13c48a03-3208-80b5-ae14-f6b3304cb3b1",
    "Story": "13c48a03-3208-808d-8672-c40c7e13fb30",
    "Task": "13c48a03-3208-80d7-89c6-d67325faa791",
    "Discovery": "2fc48a03-3208-807b-9035-d5e438994ef8",
    "Sub-Task": "13c48a03-3208-80ed-9b36-e3c2b84017cd",
    "Bug": "13c48a03-3208-80c2-9f00-f25f13cf9910",
    "Doc": "13c48a03-3208-8009-8179-fabd82f884fd",
}

VALID_TYPES = list(TEMPLATE_IDS.keys())

PRIORITIES = ["Highest", "High", "Medium", "Low", "Lowest"]

LABELS = ["디자인", "기타개발", "CS", "Technical", "운영자동화", "SEO", "FE", "QA"]

SQUADS = ["Activation", "Conversion", "Product", "Tech", "PD"]

PROCESSES = ["Sprint", "Kanban"]

TEAMS = ["디자인", "기획", "개발", "커머스", "FE", "BE"]

SP_VALUES = ["0", "0.5", "1", "2", "3", "5", "8"]

REQUEST_DEPTS = [
    "사업", "경영", "마케팅", "기획", "오퍼레이션",
    "커머스", "디자인", "기타", "개발", "세일즈포스",
]

STATUSES = [
    "Draft", "Backlog", "In progress", "Testing",
    "Review", "Ready for Release", "Done", "Archive",
    "Blocked", "Cancel",
]

OPTIONAL_PROP_ENUMS = {
    "레이블": LABELS,
    "스쿼드": SQUADS,
    "프로세스": PROCESSES,
    "팀": TEAMS,
    "SP": SP_VALUES,
    "요청 부서": REQUEST_DEPTS,
}

CONTENT_TEMPLATES = {
    "Initiative": ["## 목표\n\n", "## 핵심 KPI\n\n", "## 기간\n\n"],
    "Epic": [
        "## 비즈니스 목표\n왜 이 작업을 해야 하는가? 기대 효과\n\n",
        "## 작업 범위\n사용자, 주요 서비스, 핵심 기능, 정책, 산출물\n\n",
        "## 완료 기준\n구체적 결과물, 측정 가능한 기준\n\n",
    ],
    "Story": [
        "## 사용자 시나리오\n수행 이유, 기대 효과\n\n",
        "## 작업 범위\n기능 요구사항, UI/UX 요구사항, 완료 기준, 영향도 체크\n\n",
        "## 완료 기준\n사용자가 무엇을 할 수 있는지\n\n",
    ],
    "Discovery": [
        "## 배경 및 가설\n데이터/VOC 기반 문제, 가설([A]하면 [B]가 된다), 검증 목적\n\n",
        "## 탐색 범위\nIn-Scope(집중 검토), Out-of-Scope(제외)\n\n",
        "## 완료 기준\nGo/Conditional Go/No-Go 판단 기준\n\n",
    ],
    "Task": [
        "## 목적\n왜 이 작업이 필요한지, 기대 효과\n\n",
        "## 작업 내용\n- [ ] \n- [ ] \n- [ ] \n\n",
        "## 완료 기준\n측정 가능한 완료 상태\n\n",
    ],
    "Sub-Task": [
        "## 작업 목적\n상위 Task/Story와의 연관성\n\n",
        "## 작업 내용 및 단계\n구체적 구현 내용 (API, FE, 테스트 등)\n\n",
        "## 완료 기준\nPR 머지, QA 통과 등 구체적 기준\n\n",
    ],
    "Bug": [
        "## 발생 환경\n기기, OS, 브라우저, 발생 위치, 계정 유형\n\n",
        "## 실제 동작\n1. \n2. \n3. \n\n",
        "## 완료 기준\n기대되는 정상 동작\n\n",
        "## 기타 의견\n빈도, 스크린샷, 관련 로그\n\n",
    ],
    "Doc": [
        "## 배경 및 목적\n문서가 필요한 이유\n\n",
        "## 주요 내용\n핵심 정보 (표, 코드, 다이어그램 활용)\n\n",
        "## 완료 기준\n문서 활용 가능 상태\n\n",
    ],
}

FILLER_WORDS = re.compile(
    r"(정확하게|체계적으로|효율적으로|적절하게|효과적으로|원활하게|안정적으로)"
)


# === Commands ===


def cmd_payload(args):
    """Generate a Notion API payload for creating a backlog item."""
    item_type = args.type
    if item_type not in VALID_TYPES:
        _fail(f"유효하지 않은 유형: {item_type}. 허용: {VALID_TYPES}")

    priority = args.priority or "Medium"
    if priority not in PRIORITIES:
        _fail(f"유효하지 않은 우선순위: {priority}. 허용: {PRIORITIES}")

    properties = {
        "일감명": args.title,
        "일감 유형": item_type,
        "상태": args.status or "Backlog",
        "우선순위": priority,
    }

    # Merge extra properties
    if args.props:
        extra = json.loads(args.props)
        # Validate extra props
        errors = _validate_optional_props(extra)
        if errors:
            _fail(f"프로퍼티 검증 실패: {'; '.join(errors)}")
        properties.update(extra)

    page = {
        "template_id": TEMPLATE_IDS[item_type],
        "properties": properties,
    }

    ds_id = _load_datasource_id()
    if not ds_id:
        _fail(
            "notion_backlog_datasource가 설정되지 않음. "
            "~/.claude/rentre-config.json 확인 또는 /rentre:setup 실행 필요"
        )

    payload = {
        "parent": {"data_source_id": ds_id},
        "pages": [page],
    }

    _out({"status": "ok", "payload": payload})


def cmd_validate(args):
    """Validate a backlog payload against the schema."""
    payload = json.loads(args.payload)
    errors = []

    pages = payload.get("pages", [])
    if not pages:
        errors.append("pages 배열이 비어있음")

    for i, page in enumerate(pages):
        props = page.get("properties", {})
        prefix = f"pages[{i}]"

        # Required properties
        if not props.get("일감명"):
            errors.append(f"{prefix}: 일감명 누락")
        item_type = props.get("일감 유형")
        if not item_type:
            errors.append(f"{prefix}: 일감 유형 누락")
        elif item_type not in VALID_TYPES:
            errors.append(f"{prefix}: 유효하지 않은 유형 '{item_type}'. 허용: {VALID_TYPES}")
        if not props.get("상태"):
            errors.append(f"{prefix}: 상태 누락")
        elif props["상태"] not in STATUSES:
            errors.append(f"{prefix}: 유효하지 않은 상태 '{props['상태']}'")
        if not props.get("우선순위"):
            errors.append(f"{prefix}: 우선순위 누락")
        elif props["우선순위"] not in PRIORITIES:
            errors.append(f"{prefix}: 유효하지 않은 우선순위 '{props['우선순위']}'")

        # Optional property enum validation
        errs = _validate_optional_props(props)
        errors.extend(f"{prefix}: {e}" for e in errs)

        # Template ID check
        if item_type and item_type in TEMPLATE_IDS:
            tid = page.get("template_id")
            if tid and tid != TEMPLATE_IDS[item_type]:
                errors.append(
                    f"{prefix}: template_id 불일치. "
                    f"'{item_type}'의 올바른 ID: {TEMPLATE_IDS[item_type]}"
                )

    _out({"status": "ok" if not errors else "error", "errors": errors})


def cmd_check_title(args):
    """Check a title against type-specific conventions."""
    item_type = args.type
    title = args.title
    warnings = []

    if not title or not title.strip():
        _fail("제목이 비어있음")

    # Filler words
    found = FILLER_WORDS.findall(title)
    if found:
        warnings.append(f"불필요한 수식어 발견: {', '.join(found)}")

    # Type-specific checks
    if item_type == "Discovery" and not title.endswith("?") and "?" not in title:
        warnings.append("Discovery 제목은 질문(?) 형태를 권장합니다")

    if item_type == "Bug" and "문제" not in title and "오류" not in title and "에러" not in title:
        warnings.append("Bug 제목에 문제 상황이 명시되지 않음. [대상]+[문제 상황] 형식 권장")

    # Too short
    if len(title) < 5:
        warnings.append("제목이 너무 짧음 (5자 미만)")

    # Too vague
    vague = re.search(r"^.{0,3}(개선|적용|변경|수정|처리|검토)$", title)
    if vague:
        warnings.append(f"제목이 모호함: '{title}'. 구체적 대상+행동+목적 포함 필요")

    _out({"status": "ok" if not warnings else "warning", "warnings": warnings})


def cmd_template(args):
    """Return the content template skeleton for a given type."""
    item_type = args.type
    if item_type not in CONTENT_TEMPLATES:
        _fail(f"유효하지 않은 유형: {item_type}")

    sections = CONTENT_TEMPLATES[item_type]
    content = "\n".join(sections)

    _out({"status": "ok", "type": item_type, "content": content})


def cmd_quality(args):
    """Run the full quality checklist against a backlog item."""
    results = {"title": [], "content": [], "properties": []}

    # Title checks
    title = args.title or ""
    if not title.strip():
        results["title"].append({"check": "제목 존재", "pass": False})
    else:
        results["title"].append({"check": "제목 존재", "pass": True})

        found = FILLER_WORDS.findall(title)
        results["title"].append({
            "check": "불필요한 수식어 없음",
            "pass": not found,
            "detail": f"발견: {', '.join(found)}" if found else None,
        })

        results["title"].append({
            "check": "5자 이상",
            "pass": len(title) >= 5,
        })

    # Property checks
    if args.payload:
        payload = json.loads(args.payload)
        props = payload.get("properties", payload)

        item_type = props.get("일감 유형")
        results["properties"].append({
            "check": "유형 유효",
            "pass": item_type in VALID_TYPES if item_type else False,
        })
        results["properties"].append({
            "check": "우선순위 설정",
            "pass": bool(props.get("우선순위")),
        })
        results["properties"].append({
            "check": "상태 설정",
            "pass": bool(props.get("상태")),
        })

        # Enum validation
        errs = _validate_optional_props(props)
        results["properties"].append({
            "check": "선택 프로퍼티 유효",
            "pass": not errs,
            "detail": "; ".join(errs) if errs else None,
        })

    # Content checks
    content = args.content or ""
    if content:
        item_type = args.type
        if item_type and item_type in CONTENT_TEMPLATES:
            expected = CONTENT_TEMPLATES[item_type]
            for section in expected:
                header = section.split("\n")[0]
                results["content"].append({
                    "check": f"필수 섹션: {header}",
                    "pass": header in content,
                })

        has_checklist = "- [ ]" in content or "- [x]" in content
        if item_type in ("Task", "Sub-Task"):
            results["content"].append({
                "check": "체크리스트 형태 작업 내용",
                "pass": has_checklist,
            })

        results["content"].append({
            "check": "완료 기준 포함",
            "pass": "완료 기준" in content or "## 완료" in content,
        })

    all_checks = results["title"] + results["content"] + results["properties"]
    passed = sum(1 for c in all_checks if c.get("pass"))
    total = len(all_checks)

    _out({
        "status": "ok",
        "passed": passed,
        "total": total,
        "all_passed": passed == total,
        "results": results,
    })


# === Helpers ===


def _validate_optional_props(props):
    """Validate optional property values against allowed enums."""
    errors = []
    for key, allowed in OPTIONAL_PROP_ENUMS.items():
        val = props.get(key)
        if val is None:
            continue
        # Multi-select: check each value
        if key == "팀" and isinstance(val, list):
            for v in val:
                if v not in allowed:
                    errors.append(f"'{key}' 값 '{v}' 유효하지 않음. 허용: {allowed}")
        elif isinstance(val, str) and val not in allowed:
            errors.append(f"'{key}' 값 '{val}' 유효하지 않음. 허용: {allowed}")
    return errors


def _out(data):
    json.dump(data, sys.stdout, ensure_ascii=False, indent=2)
    print()
    sys.exit(0)


def _fail(msg):
    json.dump({"status": "error", "error": msg}, sys.stdout, ensure_ascii=False, indent=2)
    print()
    sys.exit(1)


# === CLI ===


def main():
    parser = argparse.ArgumentParser(
        description="Rentre 백로그 빌더 — 페이로드 생성, 검증, 품질 체크"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # payload
    p = sub.add_parser("payload", help="Notion API 페이로드 생성")
    p.add_argument("--type", required=True, help="일감 유형")
    p.add_argument("--title", required=True, help="일감명")
    p.add_argument("--priority", help="우선순위 (기본: Medium)")
    p.add_argument("--status", help="상태 (기본: Backlog)")
    p.add_argument("--props", help="추가 프로퍼티 JSON")

    # validate
    p = sub.add_parser("validate", help="페이로드 유효성 검증")
    p.add_argument("--payload", required=True, help="검증할 JSON 페이로드")

    # check-title
    p = sub.add_parser("check-title", help="제목 형식 검증")
    p.add_argument("--type", required=True, help="일감 유형")
    p.add_argument("--title", required=True, help="검증할 제목")

    # template
    p = sub.add_parser("template", help="유형별 content 템플릿 생성")
    p.add_argument("--type", required=True, help="일감 유형")

    # quality
    p = sub.add_parser("quality", help="품질 체크리스트 실행")
    p.add_argument("--type", help="일감 유형")
    p.add_argument("--title", help="일감명")
    p.add_argument("--payload", help="프로퍼티 JSON")
    p.add_argument("--content", help="content 텍스트")

    args = parser.parse_args()
    {
        "payload": cmd_payload,
        "validate": cmd_validate,
        "check-title": cmd_check_title,
        "template": cmd_template,
        "quality": cmd_quality,
    }[args.command](args)


if __name__ == "__main__":
    main()
