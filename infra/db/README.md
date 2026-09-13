# Database (PostgreSQL)

## 서비스 성격

사내 게시판 + 회의실 예약 시스템.

## 스키마

| 테이블 | 설명 |
|---|---|
| `users` | 직원 (300명 규모 시뮬레이션, `department` ENUM 포함) |
| `posts` | 게시판 게시글 |
| `comments` | 게시글 댓글 |
| `rooms` | 회의실 |
| `reservations` | 회의실 예약 — `EXCLUDE USING gist`로 **같은 회의실의 시간대 중복 예약을 DB 레벨에서 차단** |

전체 정의는 [`init/001_schema.sql`](init/001_schema.sql) 참고.

## 디렉터리

- `init/001_schema.sql` — 테이블/제약/인덱스 정의 (컨테이너 최초 기동 시 자동 실행)
- `init/002_seed.sql` — 더미 데이터: 직원 300명, 회의실 4개, 게시글 20개 + 댓글, 예약 샘플
  (⚠️ 비밀번호는 데모용 고정값 — 실서비스 재사용 금지)

`docker-entrypoint-initdb.d`는 파일명 알파벳 순으로 실행되므로, `001_`/`002_` 접두사로
순서를 보장합니다. **볼륨이 비어있을 때만** 실행되는 점에 유의 (기존 데이터가 있으면 재실행 안 됨).

## 네트워크/포트

`backend` 네트워크에만 연결되며 호스트 포트는 노출하지 않습니다 (내부 전용 —
[docs/network-design.md](../../docs/network-design.md) 참고). App 컨테이너에서만 접근 가능합니다.

## 로컬 검증

```bash
cd infra
docker compose up -d db
docker compose exec db psql -U app_user -d company_service -c "SELECT count(*) FROM users;"
docker compose exec db psql -U app_user -d company_service -c "SELECT * FROM reservations;"

# 중복 예약이 실제로 거부되는지 확인
docker compose exec db psql -U app_user -d company_service -c \
  "INSERT INTO reservations (room_id, user_id, title, start_time, end_time)
   SELECT 1, 1, '중복 테스트', date_trunc('day', now()) + interval '10 hour 30 min',
                                date_trunc('day', now()) + interval '11 hour';"
# → ERROR: conflicting key value violates exclusion constraint 가 나오면 정상
```

## 예정 항목

- [x] 스키마 설계
- [x] `init/001_schema.sql`
- [x] `init/002_seed.sql` (300명 규모 더미 데이터)
- [ ] App에서 실제 쿼리 연동 (`pg` 드라이버, 커넥션 풀)
- [ ] 백업/복구 절차 문서화
