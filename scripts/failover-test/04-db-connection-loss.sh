#!/usr/bin/env bash
# 시나리오 4: DB 연결 끊김 — liveness(/health)는 살아있고 readiness(/ready)/API만
# 실패하는지, 그리고 DB 복구 시 App 재시작 없이 자동 재연결되는지 확인한다.
#
# 사용법: sudo bash scripts/failover-test/04-db-connection-loss.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../infra"

REQUESTS=${REQUESTS:-10}

echo "=== [사전] /health, /ready, /api/rooms 정상 확인 ==="
curl -s -o /dev/null -w "/health -> %{http_code}\n" http://localhost/health
curl -s -o /dev/null -w "/ready  -> %{http_code}\n" http://localhost/ready
curl -s -o /dev/null -w "/api/rooms -> %{http_code}\n" http://localhost/api/rooms

echo
echo "=== [장애 주입] db 컨테이너 중지 ==="
docker compose stop db

echo
echo "=== [장애 중] health는 살아있고 ready/API만 실패하는지 확인 ==="
for i in $(seq 1 "$REQUESTS"); do
  echo "--- 시도 $i ---"
  curl -s -o /dev/null -w "  /health    -> %{http_code}\n" http://localhost/health
  curl -s -o /dev/null -w "  /ready     -> %{http_code}\n" http://localhost/ready
  curl -s -o /dev/null -w "  /api/rooms -> %{http_code}\n" http://localhost/api/rooms
  sleep 1
done

echo
echo "=== [복구] db 컨테이너 재시작 후 healthy 대기 ==="
docker compose start db
DB_CID="$(docker compose ps -q db)"
echo -n "db가 healthy 상태가 될 때까지 대기 중"
until [ "$(docker inspect -f '{{.State.Health.Status}}' "$DB_CID" 2>/dev/null)" = "healthy" ]; do
  echo -n "."
  sleep 2
done
echo " 완료"

echo
echo "=== [사후] App 재시작 없이 자동 재연결되는지 확인 ==="
curl -s -o /dev/null -w "/ready     -> %{http_code}\n" http://localhost/ready
curl -s -o /dev/null -w "/api/rooms -> %{http_code}\n" http://localhost/api/rooms
