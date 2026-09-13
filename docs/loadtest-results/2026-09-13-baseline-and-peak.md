# 2026-09-13: baseline / peak 부하 테스트

## 환경

- 인프라: Nginx(LB) + App 3인스턴스 + PostgreSQL, 로컬 Docker Compose로 전체 스택 기동
- 부하 발생기: k6 (`grafana/k6:0.54.0`, `frontend` 네트워크에서 Nginx로 직접 요청)
- 대상: `GET /api/posts` (baseline), `/api/posts`·`/api/rooms`·`/` 혼합 (peak)

## 시나리오 1: `baseline.js` (20 VU, 3분)

| 지표 | 결과 |
|---|---|
| 성공률 | 100.00% (3,010 / 3,010) |
| `http_req_failed` | 0.00% (threshold `<1%` 통과) |
| `http_req_duration` p95 | 1.79ms (threshold `<300ms` 통과) |
| 처리량 | 16.65 req/s |

평상시 트래픽(20 VU) 수준에서는 여유 있게 처리됨.

## 시나리오 2: `peak.js` (300 VU, 6분) — 1차 시도

| 지표 | 결과 |
|---|---|
| 성공률 | 17.70% (6,933 / 39,156) |
| `http_req_failed` | **82.29%** (threshold `<2%` 위반, 테스트 실패) |
| `http_req_duration` p95 | 1.02ms (실패 포함) |

응답 자체는 매우 빨랐는데도 대부분 실패 — Nginx `limit_req`(IP당 rate limit)가
k6의 단일 컨테이너 출발지 IP를 과도하게 차단한 것이 원인으로 확인됨.
근본 원인 분석과 조치는 [장애 리포트](../incident-reports/2026-09-13-ratelimit-503.md) 참고.

## 시나리오 2: `peak.js` (300 VU, 6분) — 수정 후 재시도

| 지표 | 결과 |
|---|---|
| 성공률 | **100.00%** (39,030 / 39,030) |
| `http_req_failed` | **0.00%** (threshold `<2%` 통과) |
| `http_req_duration` p95 | **840.69µs** (threshold `<800ms` 통과) |
| 처리량 | 108.17 req/s |

## 병목 분석

- 두 시도 모두 처리량(~108 req/s)과 응답 시간(p95 1ms 이하)이 거의 동일 —
  **App/DB/Nginx 자체의 처리 능력은 300 VU 수준에서 병목이 아니었다.**
- 실제 병목은 애플리케이션이 아니라 **Nginx rate limit 설정값**이었다.
  (300인 규모 사내 서비스에 외부 공개 서비스용 IP당 제한을 그대로 적용한 설계 실수)
- 이 결과만으로는 DB 커넥션 풀(App당 `max:10`, 3인스턴스 = 총 30)이나 Postgres
  자체의 한계에는 아직 도달하지 않은 것으로 보임 — 더 높은 VU(예: `spike.js`,
  400 VU) 또는 쓰기 위주 시나리오(`reservation-contention.js`)에서 추가 확인 필요.

## 다음 확인 예정

- [ ] `spike.js` (400 VU 스파이크)
- [ ] `reservation-contention.js` (동시 예약 경합)
