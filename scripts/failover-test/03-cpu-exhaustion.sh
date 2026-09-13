#!/usr/bin/env bash
# 시나리오 3: App 인스턴스 CPU 자원 제한 (자원 고갈 시뮬레이션)
# docker update로 컨테이너의 CPU 쿼터를 강제로 줄인 뒤, 부하를 가해 영향을 관찰한다.
#
# 사용법: sudo bash scripts/failover-test/03-cpu-exhaustion.sh [app1|app2|app3]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../infra"

TARGET=${1:-app3}
REQUESTS=${REQUESTS:-30}

CID="$(docker compose ps -q "$TARGET")"
if [ -z "$CID" ]; then
  echo "컨테이너 $TARGET 를 찾을 수 없습니다 (docker compose up 상태인지 확인)" >&2
  exit 1
fi

echo "=== [사전] 정상 상태 응답 시간 ${REQUESTS}회 측정 ==="
for i in $(seq 1 "$REQUESTS"); do
  curl -s -o /dev/null -w "%{time_total}s\n" http://localhost/
done

echo
echo "=== [장애 주입] ${TARGET} CPU를 0.1코어로 제한 ==="
docker update --cpus="0.1" "$CID"

echo
echo "=== [부하 인가] k6 peak.js(300 VU)로 부하를 가하며 실패율/응답 시간 관찰 ==="
docker compose --profile loadtest run --rm k6 run /scripts/peak.js || echo "(threshold 위반으로 종료됐을 수 있음 — 정상적인 관찰 결과)"

echo
echo "=== [복구] ${TARGET} CPU 제한 해제 ==="
docker update --cpus="0" "$CID"

echo
echo "=== [사후] 응답 시간 ${REQUESTS}회 재측정 ==="
for i in $(seq 1 "$REQUESTS"); do
  curl -s -o /dev/null -w "%{time_total}s\n" http://localhost/
done
