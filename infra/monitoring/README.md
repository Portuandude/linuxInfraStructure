# Monitoring (Prometheus + Grafana)

## 디렉터리

- `prometheus/` — `prometheus.yml` scrape 설정
- `grafana/provisioning/` — 데이터소스/대시보드 자동 프로비저닝 설정

## 예정 항목

- [ ] `prometheus/prometheus.yml` — App/Nginx/node-exporter/cAdvisor 스크랩 타겟
- [ ] `grafana/provisioning/datasources/` — Prometheus 데이터소스 자동 등록
- [ ] `grafana/provisioning/dashboards/` — 기본 대시보드 (시스템/컨테이너/App 지표)
- [ ] node-exporter, cAdvisor 컨테이너 구성 (docker-compose.yml)
