-- 사내 서비스 스키마: 게시판 + 회의실 예약
-- 컨테이너 최초 기동 시 docker-entrypoint-initdb.d에 의해 자동 실행됨

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- 비밀번호 해시(crypt/gen_salt)
CREATE EXTENSION IF NOT EXISTS btree_gist; -- 예약 시간대 중복 방지 EXCLUDE 제약용

CREATE TYPE department AS ENUM (
    'engineering', 'product', 'design', 'sales', 'marketing', 'hr', 'finance', 'operations'
);

-- 직원 (300인 규모)
CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    employee_no   VARCHAR(20)  NOT NULL UNIQUE,
    name          VARCHAR(50)  NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    department    department   NOT NULL,
    position      VARCHAR(50)  NOT NULL,
    password_hash TEXT         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 게시판: 게시글
CREATE TABLE posts (
    id         BIGSERIAL PRIMARY KEY,
    author_id  BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title      VARCHAR(200) NOT NULL,
    content    TEXT         NOT NULL,
    view_count INTEGER      NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE INDEX idx_posts_author_id  ON posts(author_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- 게시판: 댓글
CREATE TABLE comments (
    id         BIGSERIAL PRIMARY KEY,
    post_id    BIGINT      NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id  BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content    TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_comments_post_id ON comments(post_id);

-- 회의실
CREATE TABLE rooms (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(50)  NOT NULL UNIQUE,
    location   VARCHAR(100) NOT NULL,
    capacity   INTEGER      NOT NULL CHECK (capacity > 0),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 회의실 예약 (같은 회의실의 시간대 중복 예약을 DB 레벨에서 차단)
CREATE TABLE reservations (
    id         BIGSERIAL PRIMARY KEY,
    room_id    BIGINT       NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    user_id    BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title      VARCHAR(200) NOT NULL,
    start_time TIMESTAMPTZ  NOT NULL,
    end_time   TIMESTAMPTZ  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CHECK (end_time > start_time),
    EXCLUDE USING gist (
        room_id WITH =,
        tstzrange(start_time, end_time) WITH &&
    )
);
CREATE INDEX idx_reservations_room_id ON reservations(room_id);
CREATE INDEX idx_reservations_user_id ON reservations(user_id);
