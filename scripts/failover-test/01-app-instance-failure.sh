#!/usr/bin/env bash
# 시나리오 1: App 인스턴스 강제 종료 → Nginx가 나머지 인스턴스로 우회하는지 확인
#
# 사용법: sudo bash scripts/failover-test/01-app-instance-failure.sh [app1|app2|app3]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../infra"

TARGET=${1:-app2}
REQUESTS=${REQUESTS:-30}
INTERVAL=${INTERVAL:-0.5}

echo "=== [사전] 정상 상태에서 ${REQUESTS}회 요청 (인스턴스 분배 확인) ==="
for i in $(seq 1 "$REQUESTS"); do
  curl -s http://localhost/ | grep -o '"instance":"[^"]*"'
  sleep "$INTERVAL"
done

echo
echo "=== [장애 주입] ${TARGET} 강제 종료 ==="
docker compose stop "$TARGET"

echo
echo "=== [장애 중] ${REQUESTS}회 요청 (나머지 인스턴스가 처리하는지 확인) ==="
FAIL=0
for i in $(seq 1 "$REQUESTS"); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
  if [ "$CODE" != "200" ]; then
    FAIL=$((FAIL + 1))
    echo "  요청 $i: HTTP $CODE (실패)"
  fi
  sleep "$INTERVAL"
done
echo "실패 요청 수: $FAIL / $REQUESTS"

echo
echo "=== [복구] ${TARGET} 재시작 ==="
docker compose start "$TARGET"
sleep 3

echo
echo "=== [사후] ${REQUESTS}회 요청 (모든 인스턴스가 다시 분배에 포함되는지 확인) ==="
for i in $(seq 1 "$REQUESTS"); do
  curl -s http://localhost/ | grep -o '"instance":"[^"]*"'
  sleep "$INTERVAL"
done
