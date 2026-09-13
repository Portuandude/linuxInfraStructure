# 부하 테스트 스크립트 (k6)

로컬에 k6를 설치하지 않아도 되도록, `docker-compose.yml`에 `k6` 서비스를 profile로
분리해뒀습니다 (평소 `docker compose up`에는 포함되지 않음).

## 시나리오

| 파일 | 설명 |
|---|---|
| `baseline.js` | 평상시 트래픽 (동시 사용자 약 20명, 게시판 조회) |
| `peak.js` | 피크 트래픽 (300인 규모 동시 접속 가정, 게시판/회의실/메인 혼합) |
| `spike.js` | 급격한 트래픽 증가 (10초 만에 20 → 400 VU) |
| `reservation-contention.js` | 동시성 테스트 — 50명이 같은 회의실/시간대를 동시 예약 시도 → DB `EXCLUDE` 제약이 1건만 허용하는지 검증 |

## 실행 (Docker, 권장)

```bash
cd infra
docker compose up -d                         # 전체 스택이 떠 있어야 함
docker compose --profile loadtest run --rm k6 run /scripts/baseline.js
docker compose --profile loadtest run --rm k6 run /scripts/peak.js
docker compose --profile loadtest run --rm k6 run /scripts/spike.js
docker compose --profile loadtest run --rm k6 run /scripts/reservation-contention.js

# 동시성 테스트 후 실제로 1건만 생성됐는지 확인
curl -s "http://localhost/api/reservations?room_id=1"
```

k6 컨테이너는 `frontend` 네트워크에 붙어 `http://nginx`(서비스명)로 직접 요청하므로
호스트 포트 상태와 무관하게 항상 동일한 결과를 냅니다.

## 실행 (로컬에 k6가 설치되어 있다면)

```bash
k6 run -e TARGET_URL=http://localhost scripts/loadtest/baseline.js
```

## 결과 기록

각 시나리오 실행 결과(RPS, p95/p99, 에러율, 병목 분석)는
[docs/loadtest-results/](../../docs/loadtest-results/)에 기록합니다.

## 부하 중 관찰 포인트

- Grafana(`http://localhost:3001`)의 `사내 서비스 Overview` 대시보드를 열어두고
  부하 테스트 중 App 인스턴스별 요청률/지연시간, Node CPU/메모리, 컨테이너 CPU를
  실시간으로 관찰하면 병목 지점을 눈으로 확인할 수 있습니다.
- `peak.js`/`spike.js` 실행 중 `docker stats`로 각 컨테이너의 리소스 사용량을
  함께 관찰하면 어떤 컴포넌트(Nginx/App/DB)가 먼저 한계에 도달하는지 파악하기 좋습니다.
