// 평상시 트래픽 시뮬레이션 — 동시 사용자 약 20명이 게시판을 조회하는 상황
import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.TARGET_URL || "http://localhost";

export const options = {
  scenarios: {
    baseline: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "30s", target: 20 }, // 서서히 증가
        { duration: "2m", target: 20 }, // 유지
        { duration: "30s", target: 0 }, // 서서히 감소
      ],
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<300"],
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/api/posts`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(1);
}
