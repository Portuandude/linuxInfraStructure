# Database (PostgreSQL)

## 디렉터리

- `init/` — 컨테이너 최초 기동 시 실행될 초기화 SQL 스크립트 (`docker-entrypoint-initdb.d`에 마운트 예정)

## 예정 항목

- [ ] 스키마 설계
- [ ] `init/001_schema.sql`
- [ ] `init/002_seed.sql` (테스트용 더미 데이터, 300명 규모 시뮬레이션용)
- [ ] 백업/복구 절차 문서화
