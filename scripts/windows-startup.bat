@echo off
REM ============================================
REM Windows 시작 시 Rentre Agent 자동 실행
REM ============================================
REM 설치: 이 파일을 Windows 시작 프로그램 폴더에 복사
REM   Win+R → shell:startup → 이 파일 복사
REM ============================================

REM WSL은 자동 시작되므로 바로 agent 실행 (5초 여유)
timeout /t 5 /nobreak
wsl -- bash -c "/home/stephen/home/stephen/rentre-agents/scripts/start-agent.sh >> /home/stephen/home/stephen/rentre-agents/logs/startup.log 2>&1"
