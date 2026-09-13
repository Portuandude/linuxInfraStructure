# App (사내 서비스)

Node.js(Express) 기반 사내 서비스 애플리케이션입니다.

## 엔드포인트

| 경로 | 설명 |
|---|---|
| `GET /` | 서비스 기본 응답 (인스턴스명/호스트명 포함 — LB 분배 확인용) |
| `GET /health` | 헬스체크 (Docker `HEALTHCHECK`, 오케스트레이션 연동) |
| `GET /metrics` | Prometheus 스크랩 엔드포인트 (`prom-client`, 기본 Node.js 메트릭 + `http_requests_total`, `http_request_duration_seconds`) |

## 인스턴스 식별

`INSTANCE_NAME` 환경변수로 자신을 식별합니다 (`docker-compose.yml`에서 `app1`/`app2`/`app3`로 지정).
미설정 시 `os.hostname()`(컨테이너 ID)을 사용합니다.

## 로컬 실행

```bash
cd infra/app
npm install
npm run dev      # --watch 로 파일 변경 자동 반영
# 또는
npm start
```

## Docker

```bash
cd infra
docker compose build app1 app2 app3
docker compose up -d nginx app1 app2 app3
curl http://localhost/
```

## 예정 항목

- [x] `/health`, `/metrics` 엔드포인트
- [x] `Dockerfile`
- [ ] 실제 사내 서비스 기능 (게시판/예약 등 — 다음 단계에서 확장)
- [ ] DB 연동 (PostgreSQL 구성 후)
