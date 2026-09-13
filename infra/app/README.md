# App (사내 서비스)

Node.js(Express) 기반 사내 서비스 애플리케이션입니다. 게시판 + 회의실 예약 API를 제공하고,
PostgreSQL(`infra/db`)에 연결합니다.

## 엔드포인트

| 경로 | 설명 |
|---|---|
| `GET /` | 서비스 기본 응답 (인스턴스명/호스트명 포함 — LB 분배 확인용) |
| `GET /health` | liveness — 프로세스 생존 여부, DB 상태와 무관 (Docker `HEALTHCHECK`용) |
| `GET /ready` | readiness — DB 연결까지 확인 (`SELECT 1`), 실패 시 503 |
| `GET /metrics` | Prometheus 스크랩 엔드포인트 (`prom-client`) |
| `GET /api/posts` | 게시글 목록 (`limit`/`offset` 쿼리) |
| `GET /api/posts/:id` | 게시글 상세 + 댓글 (조회 시 `view_count` 증가) |
| `POST /api/posts` | 게시글 작성 `{ author_id, title, content }` |
| `GET /api/rooms` | 회의실 목록 |
| `GET /api/reservations?room_id=` | 예약 목록 |
| `POST /api/reservations` | 예약 생성 `{ room_id, user_id, title, start_time, end_time }` — **시간대 중복 시 409** |

## DB 연결

`src/db.js`가 `pg.Pool`을 관리합니다. 환경변수(`PGHOST`/`PGPORT`/`PGUSER`/`PGPASSWORD`/`PGDATABASE`,
없으면 `POSTGRES_*`로 폴백)로 접속 정보를 구성하며, `docker-compose.yml`에서 `db` 서비스가
healthy 상태가 된 뒤에만 App이 기동되도록 `depends_on.condition: service_healthy`를 걸어뒀습니다.

## 인스턴스 식별

`INSTANCE_NAME` 환경변수로 자신을 식별합니다 (`docker-compose.yml`에서 `app1`/`app2`/`app3`로 지정).
미설정 시 `os.hostname()`(컨테이너 ID)을 사용합니다.

## 로컬 실행 (DB 없이도 기동은 됨)

```bash
cd infra/app
npm install
npm run dev      # --watch 로 파일 변경 자동 반영
```

DB 없이 실행하면 `/health`·`/`는 정상 응답하고, `/ready`와 `/api/*`는 503/500으로 실패합니다
(연결 실패가 명확한 에러 메시지로 나타나는지 확인하는 용도로도 사용 가능).

## Docker (Nginx + App + DB 전체 기동)

```bash
cd infra
docker compose up -d
curl http://localhost/api/rooms
curl http://localhost/api/posts

# 중복 예약 시 409 확인
curl -i -X POST http://localhost/api/reservations \
  -H "Content-Type: application/json" \
  -d '{"room_id":1,"user_id":1,"title":"중복 테스트","start_time":"2026-09-14T10:30:00+09:00","end_time":"2026-09-14T11:00:00+09:00"}'
```

## 예정 항목

- [x] `/health`, `/ready`, `/metrics` 엔드포인트
- [x] `Dockerfile`
- [x] DB 연동 (PostgreSQL, `pg.Pool`)
- [x] 게시판/예약 API
- [ ] 인증/인가 (현재는 `author_id`/`user_id`를 요청 바디로 직접 받음 — 실서비스라면 세션/JWT 필요)
