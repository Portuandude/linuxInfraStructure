// 동시성 테스트 — 같은 회의실/시간대를 50명이 동시에 예약 시도
// DB의 EXCLUDE 제약(infra/db/init/001_schema.sql)이 동시 요청에서도
// 정확히 1건만 성공시키고 나머지를 409로 막는지 검증한다.
import http from "k6/http";
import { check } from "k6";

const BASE_URL = __ENV.TARGET_URL || "http://localhost";

export const options = {
  scenarios: {
    contention: {
      executor: "per-vu-iterations",
      vus: 50,
      iterations: 1, // VU당 정확히 1회 → 50명이 거의 동시에 1번씩 요청
      maxDuration: "30s",
    },
  },
};

// 매 테스트 실행마다 겹치지 않는 새 시간대를 쓰고 싶다면 이 값을 바꿔서 실행할 것
const START_TIME = __ENV.START_TIME || "2026-09-20T10:00:00+09:00";
const END_TIME = __ENV.END_TIME || "2026-09-20T10:30:00+09:00";

const PAYLOAD = JSON.stringify({
  room_id: 1,
  user_id: 1,
  title: "동시성 테스트",
  start_time: START_TIME,
  end_time: END_TIME,
});

export default function () {
  const res = http.post(`${BASE_URL}/api/reservations`, PAYLOAD, {
    headers: { "Content-Type": "application/json" },
  });
  check(res, {
    "201(생성) 또는 409(중복 차단) 중 하나": (r) => r.status === 201 || r.status === 409,
  });
}

// 테스트 종료 후: 실제로 해당 슬롯에 예약이 "정확히 1건"만 생성됐는지
// curl "http://<host>/api/reservations?room_id=1" 로 직접 확인할 것.
