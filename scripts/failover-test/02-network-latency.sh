#!/usr/bin/env bash
# 시나리오 2: App 인스턴스에 네트워크 지연/패킷 손실 주입 (tc netem)
# nicolaka/netshoot 컨테이너를 대상 컨테이너와 네트워크 네임스페이스를 공유시켜
# tc를 실행한다 (App 이미지 자체에는 iproute2가 없음).
#
# Nginx를 거치면 3개 인스턴스로 분산되어 효과가 희석되므로, frontend 네트워크에서
# 대상 App 컨테이너를 직접 호출해 장애 효과를 명확하게 관찰한다.
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

# compose 프로젝트명에 따라 네트워크 실제 이름이 달라질 수 있으므로 직접 조회
FRONTEND_NET="$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}' "$CID" | grep frontend)"
echo "frontend 네트워크 실제 이름: $FRONTEND_NET"

probe() {
  local label="$1"
  for i in $(seq 1 "$REQUESTS"); do
    docker run --rm --network "$FRONTEND_NET" curlimages/curl -s -o /dev/null \
      --max-time 3 -w "%{time_total}s (HTTP %{http_code})\n" "http://${TARGET}:3000/" \
      || echo "요청 실패(타임아웃)"
  done
}

echo
echo "=== [진단] ${TARGET}의 네트워크 인터페이스 확인 (netem을 어느 인터페이스에 걸지 확인) ==="
docker run --rm --network "container:$CID" "$NETSHOOT" ip -brief addr

echo
echo "=== [사전] ${TARGET} 직접 호출 응답 시간 ${REQUESTS}회 측정 (Nginx 안 거침) ==="
probe "사전"

echo
echo "=== [장애 주입] ${TARGET}(eth0)에 지연 ${DELAY} / 손실 ${LOSS} 주입 ==="
docker run --rm --network "container:$CID" --cap-add NET_ADMIN "$NETSHOOT" \
  tc qdisc add dev eth0 root netem delay "$DELAY" loss "$LOSS"

echo "--- 적용된 규칙 확인 ---"
docker run --rm --network "container:$CID" "$NETSHOOT" tc qdisc show dev eth0

echo
echo "=== [장애 중] ${TARGET} 직접 호출 응답 시간 ${REQUESTS}회 측정 ==="
probe "장애중"

echo
echo "=== [참고] 같은 시간대 Nginx(전체 분산) 응답 시간 ${REQUESTS}회 — 3개 중 1개만 영향받음 ==="
for i in $(seq 1 "$REQUESTS"); do
  curl -s -o /dev/null -w "%{time_total}s (HTTP %{http_code})\n" http://localhost/
done

echo
echo "=== [복구] 네트워크 규칙 제거 ==="
docker run --rm --network "container:$CID" --cap-add NET_ADMIN "$NETSHOOT" \
  tc qdisc del dev eth0 root

echo
echo "=== [사후] ${TARGET} 직접 호출 응답 시간 ${REQUESTS}회 재측정 ==="
probe "사후"
