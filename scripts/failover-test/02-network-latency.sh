#!/usr/bin/env bash
# 시나리오 2: App 인스턴스에 네트워크 지연/패킷 손실 주입 (tc netem)
# nicolaka/netshoot 컨테이너를 대상 컨테이너와 네트워크 네임스페이스를 공유시켜
# tc를 실행한다 (App 이미지 자체에는 iproute2가 없음).
#
# 사용법: sudo bash scripts/failover-test/02-network-latency.sh [app1|app2|app3]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../infra"

TARGET=${1:-app1}
DELAY=${DELAY:-500ms}
LOSS=${LOSS:-10%}
REQUESTS=${REQUESTS:-20}
NETSHOOT="nicolaka/netshoot"

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
echo "=== [장애 주입] ${TARGET}에 지연 ${DELAY} / 손실 ${LOSS} 주입 ==="
docker run --rm --network "container:$CID" --cap-add NET_ADMIN "$NETSHOOT" \
  tc qdisc add dev eth0 root netem delay "$DELAY" loss "$LOSS"

echo
echo "=== [장애 중] 응답 시간 ${REQUESTS}회 측정 ==="
for i in $(seq 1 "$REQUESTS"); do
  curl -s -o /dev/null -w "%{time_total}s (HTTP %{http_code})\n" http://localhost/
done

echo
echo "=== [복구] 네트워크 규칙 제거 ==="
docker run --rm --network "container:$CID" --cap-add NET_ADMIN "$NETSHOOT" \
  tc qdisc del dev eth0 root

echo
echo "=== [사후] 응답 시간 ${REQUESTS}회 재측정 ==="
for i in $(seq 1 "$REQUESTS"); do
  curl -s -o /dev/null -w "%{time_total}s\n" http://localhost/
done
