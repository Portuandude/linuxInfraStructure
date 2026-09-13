// 피크 트래픽 시뮬레이션 — 300인 규모 동시 접속 가정 (예: 점심시간 직후 게시판/예약 확인 몰림)
import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.TARGET_URL || "http://localhost";

export const options = {
  scenarios: {
    peak: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "1m", target: 100 },
        { duration: "1m", target: 300 }, // 전 직원 규모까지 증가
        { duration: "3m", target: 300 }, // 피크 유지
        { duration: "1m", target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.02"],
    http_req_duration: ["p(95)<800"],
  },
};

export default function () {
  // 실제 사용 패턴 비율: 게시판 조회 60%, 회의실 목록 30%, 메인 페이지 10%
  const r = Math.random();
  let res;
  if (r < 0.6) {
    res = http.get(`${BASE_URL}/api/posts`);
  } else if (r < 0.9) {
    res = http.get(`${BASE_URL}/api/rooms`);
  } else {
    res = http.get(`${BASE_URL}/`);
  }
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(Math.random() * 2 + 1);
}
