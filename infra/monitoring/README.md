# Monitoring (Prometheus + Grafana)

## 구성 요소

| 서비스 | 역할 | 노출 |
|---|---|---|
| `prometheus` | 메트릭 수집/저장 | 호스트 `:9090` |
| `grafana` | 대시보드 시각화 | 호스트 `:3001` (관리자 계정은 `.env` 참고) |
| `nginx-exporter` | Nginx `stub_status`(`/nginx_status`)를 Prometheus 형식으로 변환 | 내부 전용 |
| `node-exporter` | 호스트 OS 메트릭 (CPU/메모리/디스크/네트워크) | 내부 전용 |
| `cadvisor` | 컨테이너별 리소스 사용량 | 내부 전용 |

App(`infra/app`)은 자체적으로 `/metrics`를 노출하므로 별도 exporter 없이 Prometheus가 직접 스크랩합니다.

## 디렉터리

- `prometheus/prometheus.yml` — 5개 scrape job (`prometheus`, `nginx`, `app`, `node`, `cadvisor`)
- `grafana/provisioning/datasources/` — Prometheus 데이터소스 자동 등록
- `grafana/provisioning/dashboards/` — 대시보드 프로비저닝 설정 + `app-overview.json`

## 기본 대시보드 (`사내 서비스 Overview`)

1. HTTP 요청률 (App 인스턴스별)
2. 요청 처리 시간 p95
3. Node CPU 사용률
4. Node 메모리 사용률
5. 컨테이너별 CPU 사용량
6. Nginx 활성 커넥션 / 요청률

Grafana 최초 접속 시 데이터소스와 이 대시보드가 자동으로 등록되어 있습니다 (수동 설정 불필요).

## 네트워크

모든 모니터링 컴포넌트는 `monitoring`(172.20.2.0/24) 네트워크에 위치합니다. Prometheus가
`app1/2/3`(App), `nginx-exporter`를 스크랩할 수 있도록 해당 서비스들도 `monitoring`
네트워크에 함께 연결되어 있습니다 — [docs/network-design.md](../../docs/network-design.md) 참고.

## 로컬 검증

```bash
cd infra
docker compose up -d
open http://localhost:9090/targets   # 모든 job이 State=UP인지 확인
open http://localhost:3001           # Grafana (admin / .env의 GRAFANA_ADMIN_PASSWORD)
```

`http://localhost:9090/targets`에서 5개 job이 전부 UP이면 정상입니다.

## 예정 항목

- [x] `prometheus.yml` — App/Nginx/node-exporter/cAdvisor 스크랩 타겟
- [x] Grafana 데이터소스/대시보드 자동 프로비저닝
- [x] node-exporter, cAdvisor 컨테이너 구성
- [ ] 장애/부하 테스트 시나리오와 연계한 알림(Alertmanager) 구성
