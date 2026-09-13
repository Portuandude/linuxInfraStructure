# Nginx (로드밸런서)

## 구성

- `nginx.conf` — 전역 설정 (gzip, JSON 액세스 로그, rate limit, `conf.d/*.conf` include)
- `conf.d/app.conf` — App 업스트림(`app_backend`) 정의 + 로드밸런싱/헬스체크/장애 시 재시도 설정
- `Dockerfile` — `nginx:1.27-alpine` 베이스에 위 설정을 반영한 이미지

## 로드밸런싱 전략

- `least_conn` — 커넥션이 가장 적은 인스턴스로 우선 분배
- `max_fails=3 fail_timeout=10s` — 10초 내 3회 실패한 인스턴스는 일시적으로 제외 (passive health check)
- `proxy_next_upstream` — 요청 처리 중 5xx/timeout 발생 시 다른 인스턴스로 자동 재시도 (장애 대응의 1차 방어선)

## 엔드포인트

| 경로 | 용도 |
|---|---|
| `/healthz` | Nginx 자체 헬스체크 (외부 LB/모니터링용) |
| `/nginx_status` | `stub_status` — Prometheus `nginx-exporter` 스크랩 대상 (내부망만 허용) |
| `/` | App으로 프록시 (로드밸런싱 적용) |

## 현재 상태: 임시 목업으로 검증 중

`infra/app`이 아직 구현되지 않아, `docker-compose.yml`의 `app1/app2/app3` 서비스는
`traefik/whoami` 이미지로 대체되어 있습니다. 이 목업은 요청받은 자신의 컨테이너 이름을
응답하므로, `curl`을 반복 호출해보면 라운드로빈/least_conn 분배가 눈으로 확인됩니다.

App 구현이 끝나면 `docker-compose.yml`에서 `app1/app2/app3`의 `image`/`command`만
실제 App 이미지로 교체하면 되고, Nginx 쪽 설정(`app.conf`)은 변경할 필요가 없습니다
(서비스명과 포트(3000)를 그대로 맞춰서 구현할 것).

## 로컬 검증 (도커 권한 준비되면)

```bash
cd infra
docker compose up -d nginx app1 app2 app3
curl http://localhost/healthz
for i in {1..6}; do curl -s http://localhost/ | grep Hostname; done
```

## 예정 항목

- [x] `nginx.conf` — upstream 그룹 (App 다중 인스턴스)
- [x] health check / failover 설정
- [x] 접근 로그 포맷 (모니터링 연계용, JSON)
- [x] gzip, rate limit 등 기본 튜닝
- [ ] TLS(443) 설정 — 인증서 준비 후 추가
- [ ] App 구현 완료 후 목업 → 실제 서비스 교체
