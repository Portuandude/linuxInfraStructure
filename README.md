# Linux Infrastructure Portfolio — 300인 규모 가상 사내 서비스

단순 웹앱 개발이 아니라, **Linux 서버 구축 → 네트워크 구성 → Docker 기반 서비스 운영 →
로드밸런싱 → 데이터베이스 → 모니터링 → 부하 테스트 → 장애 발생/대응**까지 전 과정을 다루는
시스템/필드 엔지니어 포트폴리오 프로젝트입니다.

## 목표

- 300명 규모 사내 서비스를 가정한 인프라를 처음부터 설계하고 구축
- Docker Compose로 다중 서비스(App / DB / LB / Monitoring)를 오케스트레이션
- 부하 테스트로 실제 트래픽 상황을 재현하고 병목을 분석
- 의도적으로 장애를 주입하고, 감지 → 대응 → 복구 → 회고까지 기록

## 아키텍처 개요

```
                ┌────────────┐
   Client ───▶ │ Nginx (LB) │
                └─────┬──────┘
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
      App #1       App #2       App #3
          │           │           │
          └─────┬─────┴─────┬─────┘
                ▼           ▼
             PostgreSQL   Redis(캐시, 선택)

      Prometheus ── scrape ──▶ App / Nginx / node-exporter / cAdvisor
      Grafana    ── visualize ──▶ Prometheus
```

자세한 설계는 [docs/architecture.md](docs/architecture.md), [docs/network-design.md](docs/network-design.md) 참고.

## 기술 스택

| 영역 | 기술 |
|---|---|
| OS | Ubuntu 26.04 LTS |
| 컨테이너 | Docker, Docker Compose |
| 로드밸런서 | Nginx |
| 애플리케이션 | Node.js |
| 데이터베이스 | PostgreSQL |
| 모니터링 | Prometheus, Grafana, node-exporter, cAdvisor |
| 부하 테스트 | k6 |
| 장애 시뮬레이션 | docker stop/pause, tc(네트워크 지연), cgroup 리소스 제한 |

## 디렉터리 구조

```
linuxinfrastructure/
├── docs/                    # 설계 문서, 장애 리포트, 부하 테스트 결과
├── infra/                   # 인프라 구성 (docker-compose, 서비스별 설정)
│   ├── nginx/               # 로드밸런서 설정
│   ├── app/                 # 애플리케이션 코드
│   ├── db/                  # DB 초기화 스크립트
│   └── monitoring/          # Prometheus / Grafana 설정
├── scripts/                 # 운영/테스트 자동화 스크립트
│   ├── loadtest/            # k6 부하 테스트 스크립트
│   └── failover-test/       # 장애 주입 스크립트
├── .env.example
└── .gitignore
```

## 진행 현황

- [x] 개발 환경 점검 (OS/CPU/RAM/Docker/네트워크/포트)
- [x] 프로젝트 디렉터리 스캐폴딩
- [x] 네트워크/컨테이너 설계 확정
- [x] 로드밸런서 구성 ([infra/nginx](infra/nginx/README.md))
- [x] 애플리케이션 구현 ([infra/app](infra/app/README.md) — Node.js/Express, `/health`·`/metrics` 포함)
- [x] 데이터베이스 구성 (PostgreSQL, 게시판+예약 스키마 — [infra/db](infra/db/README.md))
- [x] 모니터링 스택 구성 (Prometheus+Grafana — [infra/monitoring](infra/monitoring/README.md))
- [ ] 부하 테스트 수행
- [ ] 장애 시나리오 설계 및 대응 기록

## 시작하기

```bash
cp .env.example .env
# .env 값 채운 뒤
cd infra
docker compose up -d
```

기동 후:
- App: http://localhost/
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (admin / `.env`의 `GRAFANA_ADMIN_PASSWORD`)
