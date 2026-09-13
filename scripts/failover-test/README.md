# 장애 주입 스크립트

전체 스택(`docker compose up -d`)이 떠 있는 상태에서 실행합니다. Docker 제어가 필요하므로
`sudo`로 실행하세요.

## 시나리오

| 스크립트 | 시나리오 | 확인 포인트 |
|---|---|---|
| `01-app-instance-failure.sh` | App 인스턴스 강제 종료(`docker compose stop`) | Nginx가 나머지 인스턴스로 트래픽을 우회하는지, 실패 요청이 0건인지 |
| `02-network-latency.sh` | App 인스턴스에 네트워크 지연/패킷 손실 주입 (`tc netem`) | 응답 시간 변화, 장애 인스턴스 비중 |
| `03-cpu-exhaustion.sh` | App 인스턴스 CPU 자원 강제 제한 (`docker update --cpus`) | 부하 인가 시 실패율/응답 시간 악화 정도 |
| `04-db-connection-loss.sh` | DB 컨테이너 중지 | `/health`(liveness)는 살아있고 `/ready`·`/api/*`만 실패하는지, 복구 시 App 재시작 없이 자동 재연결되는지 |

## 실행

```bash
sudo bash scripts/failover-test/01-app-instance-failure.sh app2
sudo bash scripts/failover-test/02-network-latency.sh app1
sudo bash scripts/failover-test/03-cpu-exhaustion.sh app3
sudo bash scripts/failover-test/04-db-connection-loss.sh
```

모든 스크립트는 [사전] → [장애 주입] → [장애 중] → [복구] → [사후] 순서로 출력하므로,
전/중/후 수치를 비교해 실제로 장애가 발생했고 정상 복구됐는지 눈으로 확인할 수 있습니다.

각 실행 결과와 대응 기록은 [docs/incident-reports/](../../docs/incident-reports/)에 남깁니다.
