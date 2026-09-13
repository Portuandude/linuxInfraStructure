const { Pool } = require("pg");

// pg 표준 환경변수(PGHOST 등)를 우선 사용하고, 없으면 docker-compose의
// POSTGRES_* 값으로 폴백한다. 커넥션은 최초 쿼리 시점에 지연 연결된다.
const pool = new Pool({
  host: process.env.PGHOST || "db",
  port: Number(process.env.PGPORT) || 5432,
  user: process.env.PGUSER || process.env.POSTGRES_USER || "app_user",
  password: process.env.PGPASSWORD || process.env.POSTGRES_PASSWORD || "changeme",
  database: process.env.PGDATABASE || process.env.POSTGRES_DB || "company_service",
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// 유휴 커넥션에서 발생하는 에러가 프로세스를 죽이지 않도록 처리
pool.on("error", (err) => {
  console.error("[db] unexpected pool error:", err.message);
});

module.exports = pool;
