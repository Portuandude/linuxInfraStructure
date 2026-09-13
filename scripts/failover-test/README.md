# 장애 주입 스크립트

## 예정 시나리오

- [ ] App 인스턴스 강제 종료 (`docker stop`) → LB 우회 확인
- [ ] 네트워크 지연/패킷 손실 주입 (`tc netem`)
- [ ] 리소스 제한(cgroup)으로 OOM/CPU 포화 시뮬레이션
- [ ] DB 연결 끊김 시나리오

각 실행 결과와 대응 기록은 [docs/incident-reports/](../../docs/incident-reports/)에 남깁니다.
