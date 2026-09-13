// 급격한 트래픽 증가 시나리오 — 공지사항 발송 직후 접속 폭주 등 스파이크 상황
import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.TARGET_URL || "http://localhost";

export const options = {
  scenarios: {
    spike: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "10s", target: 20 }, // 평상시
        { duration: "10s", target: 400 }, // 급격한 스파이크 (300인 규모를 초과하는 부하)
        { duration: "30s", target: 400 }, // 스파이크 유지
        { duration: "10s", target: 20 }, // 급격한 감소
        { duration: "20s", target: 0 },
      ],
    },
  },
  thresholds: {
    // 스파이크 구간에서는 일부 실패를 허용하되, 서비스 전체가 죽지 않는지 확인
    http_req_failed: ["rate<0.05"],
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/api/posts`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(0.5);
}
