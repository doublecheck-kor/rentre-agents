#!/bin/bash
# rentre-agents/install.sh — 루트 래퍼
# 실제 스크립트: shared-commands/install.sh
exec bash "$(dirname "${BASH_SOURCE[0]}")/shared-commands/install.sh" "$@"
