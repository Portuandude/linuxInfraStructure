# 2026-09-13: DB 연결 끊김 장애 주입 테스트 (계획된 테스트)

## 개요

`scripts/failover-test/04-db-connection-loss.sh`로 `db` 컨테이너를 의도적으로
`docker compose stop`, 이후 재시작하여 App의 liveness/readiness 분리 설계와
`pg.Pool`의 자동 재연결이 실제로 동작하는지 검증했다.

## 탐지

계획된 테스트 — 스크립트가 장애 주입 전/중/후 `/health`·`/ready`·`/api/rooms`를
자동으로 관찰.

## 영향 범위

DB에 의존하는 기능(`/ready`, `/api/*`)만 일시적으로 503/500. 프로세스 자체(`/health`)는
영향 없음 — 즉 오케스트레이션 관점에서 컨테이너가 "죽은 것"으로 오판되어 불필요하게
재시작되는 일은 없다.

## 원인 분석 (= 검증 대상 설계)

- `infra/app/src/index.js`의 `/health`는 프로세스 생존만 확인하고 DB를 전혀 조회하지
  않음 (liveness). `/ready`는 `SELECT 1`로 DB 연결을 확인하고, 실패 시 503을 반환
  (readiness).
- `/api/*`는 `pool.query()`가 실패하면 `src/routes.js`의 catch에서 `next(err)`로
  넘어가 `src/index.js`의 공통 에러 핸들러가 500을 반환.
- `src/db.js`의 `pg.Pool`은 커넥션을 지연 생성하며, 유휴 커넥션 에러가 나더라도
  `pool.on('error', ...)`로 흡수해 프로세스를 죽이지 않는다. DB가 복구되면 다음
  쿼리 시점에 새 커넥션을 맺으므로 **App을 재시작할 필요가 없다.**

## 결과

| 구간 | `/health` | `/ready` | `/api/rooms` |
|---|---|---|---|
| 사전 | 200 | 200 | 200 |
| 장애 중 (10회 반복) | **200** (전부) | **503** (전부) | **500** (전부) |
| 사후 (App 재시작 없이) | 200 | **200** | **200** |

기대한 그대로: liveness는 DB와 무관하게 계속 살아있고, readiness/API만 정확히
실패했으며, DB 복구 후 App 프로세스를 건드리지 않아도 자동으로 정상화됐다.

## 대응 조치

없음 — 설계대로 자동 복구됨.

## 재발 방지책

해당 없음. 다만 이 테스트로 얻은 확신: 만약 오케스트레이터(Kubernetes 등)의
liveness probe를 `/health`가 아니라 `/ready`로 잘못 설정했다면, DB가 잠깐
끊기는 것만으로 모든 App 인스턴스가 "죽었다"고 오판되어 연쇄적으로 재시작되는
훨씬 심각한 장애로 번졌을 것이다 — liveness/readiness를 분리해둔 설계의
실익이 이번 테스트로 확인됨.
