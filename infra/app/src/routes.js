const express = require("express");
const pool = require("./db");

const router = express.Router();

// PostgreSQL exclusion_violation — 회의실 시간대 중복 예약 시 발생
const EXCLUSION_VIOLATION = "23P01";

// === 게시판 ===

router.get("/posts", async (req, res, next) => {
  const limit = Math.min(Number(req.query.limit) || 20, 100);
  const offset = Number(req.query.offset) || 0;
  try {
    const { rows } = await pool.query(
      `SELECT p.id, p.title, p.view_count, p.created_at, u.name AS author_name
         FROM posts p
         JOIN users u ON u.id = p.author_id
        ORDER BY p.created_at DESC
        LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

router.get("/posts/:id", async (req, res, next) => {
  const { id } = req.params;
  try {
    const { rows } = await pool.query(
      `UPDATE posts SET view_count = view_count + 1
        WHERE id = $1
        RETURNING id, title, content, view_count, created_at, author_id`,
      [id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: "게시글을 찾을 수 없습니다" });
    }

    const { rows: comments } = await pool.query(
      `SELECT c.id, c.content, c.created_at, u.name AS author_name
         FROM comments c
         JOIN users u ON u.id = c.author_id
        WHERE c.post_id = $1
        ORDER BY c.created_at ASC`,
      [id]
    );

    res.json({ ...rows[0], comments });
  } catch (err) {
    next(err);
  }
});

router.post("/posts", async (req, res, next) => {
  const { author_id, title, content } = req.body;
  if (!author_id || !title || !content) {
    return res.status(400).json({ error: "author_id, title, content는 필수입니다" });
  }
  try {
    const { rows } = await pool.query(
      `INSERT INTO posts (author_id, title, content)
       VALUES ($1, $2, $3)
       RETURNING id, title, content, view_count, created_at`,
      [author_id, title, content]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
});

// === 회의실 ===

router.get("/rooms", async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, name, location, capacity FROM rooms ORDER BY id`
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

// === 회의실 예약 ===

router.get("/reservations", async (req, res, next) => {
  const { room_id } = req.query;
  try {
    const { rows } = await pool.query(
      `SELECT r.id, r.room_id, ro.name AS room_name, r.user_id, u.name AS user_name,
              r.title, r.start_time, r.end_time
         FROM reservations r
         JOIN rooms ro ON ro.id = r.room_id
         JOIN users u ON u.id = r.user_id
        WHERE ($1::bigint IS NULL OR r.room_id = $1)
        ORDER BY r.start_time`,
      [room_id || null]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

router.post("/reservations", async (req, res, next) => {
  const { room_id, user_id, title, start_time, end_time } = req.body;
  if (!room_id || !user_id || !title || !start_time || !end_time) {
    return res
      .status(400)
      .json({ error: "room_id, user_id, title, start_time, end_time은 필수입니다" });
  }
  try {
    const { rows } = await pool.query(
      `INSERT INTO reservations (room_id, user_id, title, start_time, end_time)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, room_id, user_id, title, start_time, end_time`,
      [room_id, user_id, title, start_time, end_time]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === EXCLUSION_VIOLATION) {
      return res.status(409).json({ error: "해당 시간대에 이미 예약이 있습니다" });
    }
    next(err);
  }
});

module.exports = router;
