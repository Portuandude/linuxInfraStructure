const os = require("os");
const express = require("express");
const client = require("prom-client");
const pool = require("./db");
const apiRouter = require("./routes");

const app = express();
const PORT = process.env.PORT || 3000;
const INSTANCE_NAME = process.env.INSTANCE_NAME || os.hostname();

// === Prometheus 메트릭 ===
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestCounter = new client.Counter({
  name: "http_requests_total",
  help: "총 HTTP 요청 수",
  labelNames: ["method", "route", "status_code", "instance"],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP 요청 처리 시간(초)",
  labelNames: ["method", "route", "status_code", "instance"],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
  registers: [register],
});

app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on("finish", () => {
    const labels = {
      method: req.method,
      route: req.path,
      status_code: res.statusCode,
      instance: INSTANCE_NAME,
    };
    httpRequestCounter.inc(labels);
    end(labels);
  });
  next();
});

app.use(express.json());

// === 헬스체크 ===
// /health: liveness — 프로세스 자체 생존 여부 (DB 상태와 무관, Docker HEALTHCHECK가 사용)
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", instance: INSTANCE_NAME });
});

// /ready: readiness — DB 등 의존성까지 정상인지 (LB가 트래픽을 보내도 되는지 판단용)
app.get("/ready", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.status(200).json({ status: "ready", instance: INSTANCE_NAME });
  } catch (err) {
    res.status(503).json({ status: "not ready", instance: INSTANCE_NAME, error: err.message });
  }
});

// === Prometheus 스크랩 엔드포인트 ===
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

// === 사내 서비스 API (지금은 최소 골격, 이후 기능 추가) ===
app.get("/", (req, res) => {
  res.json({
    message: "사내 서비스에 오신 것을 환영합니다",
    instance: INSTANCE_NAME,
    hostname: os.hostname(),
    timestamp: new Date().toISOString(),
  });
});

// === 사내 서비스 API (게시판, 회의실 예약) ===
app.use("/api", apiRouter);

app.use((req, res) => {
  res.status(404).json({ error: "Not Found" });
});

// 공통 에러 핸들러 (4개 인자 시그니처 필수)
app.use((err, req, res, next) => {
  console.error(`[${INSTANCE_NAME}] unhandled error:`, err);
  res.status(500).json({ error: "Internal Server Error" });
});

app.listen(PORT, () => {
  console.log(`[${INSTANCE_NAME}] app listening on port ${PORT}`);
});
