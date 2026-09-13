-- 300인 규모 시뮬레이션을 위한 더미 데이터
-- ⚠️ 비밀번호는 데모용 고정값('password123')입니다. 실서비스에 절대 재사용 금지.

INSERT INTO users (employee_no, name, email, department, position, password_hash)
SELECT
    'EMP' || LPAD(i::text, 4, '0'),
    '직원' || i,
    'employee' || i || '@company.local',
    (ARRAY['engineering','product','design','sales','marketing','hr','finance','operations']::department[])[1 + (i % 8)],
    (ARRAY['사원','대리','과장','차장','부장'])[1 + (i % 5)],
    crypt('password123', gen_salt('bf'))
FROM generate_series(1, 300) AS i;

INSERT INTO rooms (name, location, capacity) VALUES
    ('회의실 A', '3층', 6),
    ('회의실 B', '3층', 10),
    ('회의실 C', '5층', 4),
    ('대회의실', '5층', 20);

INSERT INTO posts (author_id, title, content)
SELECT
    (SELECT id FROM users ORDER BY random() LIMIT 1),
    '사내 공지 ' || i,
    '샘플 게시글 내용입니다. (' || i || ')'
FROM generate_series(1, 20) AS i;

INSERT INTO comments (post_id, author_id, content)
SELECT
    p.id,
    (SELECT id FROM users ORDER BY random() LIMIT 1),
    '샘플 댓글입니다.'
FROM posts p, generate_series(1, 2);

INSERT INTO reservations (room_id, user_id, title, start_time, end_time)
SELECT
    r.id,
    (SELECT id FROM users ORDER BY random() LIMIT 1),
    '주간 회의',
    date_trunc('day', now()) + INTERVAL '10 hour',
    date_trunc('day', now()) + INTERVAL '11 hour'
FROM rooms r;
