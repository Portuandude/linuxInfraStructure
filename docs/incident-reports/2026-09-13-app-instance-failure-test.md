# 2026-09-13: App 인스턴스 장애 주입 테스트 (계획된 테스트)

## 개요

`scripts/failover-test/01-app-instance-failure.sh app2`로 `app2` 인스턴스를
의도적으로 `docker compose stop`, 이후 재시작하여 Nginx의 장애 우회(failover)가
설계대로 동작하는지 검증했다.

## 탐지

계획된 테스트 — 스크립트가 장애 주입 전/중/후 요청을 자동으로 관찰.

## 영향 범위

**없음.** 장애 주입 중 30회 요청 전부 200 OK (실패 0건).

## 원인 분석 (= 검증 대상 설계)

- `infra/nginx/conf.d/app.conf`의 `app_backend` upstream에 `max_fails=3 fail_timeout=10s`
  로 passive health check가 걸려있고, `proxy_next_upstream error timeout http_500 502 503 504`
  로 한 인스턴스 실패 시 자동으로 다음 upstream을 재시도하도록 구성되어 있음.
- `app2`가 내려가면 해당 upstream으로의 연결이 즉시 `error`(connection refused)로
  실패하고, Nginx가 같은 요청을 `app1`/`app3` 중 하나로 즉시 재시도 → 클라이언트는
  실패를 전혀 겪지 않음.

## 결과

| 구간 | 관찰 |
|---|---|
| 사전 (30회) | `app1`/`app2`/`app3`가 거의 고르게 분배됨 (least_conn) |
| 장애 중 (30회, app2 다운) | **실패 0 / 30**, 응답은 `app1`/`app3`로만 옴 |
| 사후 (30회, app2 재시작) | 재시작 직후 첫 7건은 `app1`/`app3`만 응답, 8번째 요청부터 `app2`가 다시 분배에 포함됨 |

사후 구간에서 `app2`가 즉시가 아니라 몇 건 이후부터 복귀한 것은, 컨테이너
기동(로그상 2.8초) + Nginx가 다음 요청이 왔을 때 해당 upstream을 다시 시도해보는
타이밍이 겹쳐 발생한 정상적인 지연으로 보인다 (별도 조치 불필요).

## 대응 조치

없음 — 자동 복구가 설계대로 동작함을 확인.

## 재발 방지책

해당 없음. 이 테스트는 기존 설계([infra/nginx](../../infra/nginx/README.md)의
`proxy_next_upstream`/passive health check)가 실제로 의도대로 작동하는지 확인하기
위한 것이었고, 결과가 기대와 일치했다.
