-- ====================================================
-- SQL Snake Game
-- Fully working: growth, self-collision, edge wrapping
-- Author: AkaneDev
-- ====================================================

-- FRAMEBUFFER: 32x32 monochrome screen
CREATE TABLE IF NOT EXISTS framebuffer(
    x INT,
    y INT,
    pixel TINYINT DEFAULT 0,
    PRIMARY KEY(x, y)
);

-- SNAKE SEGMENTS: newest row is head
CREATE TABLE IF NOT EXISTS snake(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    x INT,
    y INT
);

-- SNAKE DIRECTION: single row, U/D/L/R
CREATE TABLE IF NOT EXISTS snake_dir(dir CHAR(1));

-- FOOD: single piece at a time
CREATE TABLE IF NOT EXISTS food(x INT, y INT);

-- --------------------
-- INITIALIZATION (first run only)
-- --------------------
INSERT INTO snake(x,y)
SELECT 16,16
WHERE NOT EXISTS(SELECT 1 FROM snake);

INSERT INTO snake_dir(dir)
SELECT 'R'
WHERE NOT EXISTS(SELECT 1 FROM snake_dir);

INSERT INTO food(x,y)
SELECT ABS(RANDOM()%32), ABS(RANDOM()%32)
WHERE NOT EXISTS(SELECT 1 FROM food);

-- --------------------
-- CLEAR FRAMEBUFFER
-- --------------------
UPDATE framebuffer SET pixel = 0;

WITH RECURSIVE xs(x) AS (
    SELECT 0 UNION ALL SELECT x+1 FROM xs WHERE x<31
), ys(y) AS (
    SELECT 0 UNION ALL SELECT y+1 FROM ys WHERE y<31
)
INSERT OR IGNORE INTO framebuffer(x, y, pixel)
SELECT xs.x, ys.y, 0
FROM xs, ys;

-- --------------------
-- UPDATE DIRECTION FROM INPUT
-- Prevent reversing
-- --------------------
UPDATE snake_dir
SET dir = CASE
    WHEN EXISTS(SELECT 1 FROM input_events WHERE event='U') AND dir<>'D' THEN 'U'
    WHEN EXISTS(SELECT 1 FROM input_events WHERE event='D') AND dir<>'U' THEN 'D'
    WHEN EXISTS(SELECT 1 FROM input_events WHERE event='L') AND dir<>'R' THEN 'L'
    WHEN EXISTS(SELECT 1 FROM input_events WHERE event='R') AND dir<>'L' THEN 'R'
    ELSE dir
END;

-- --------------------
-- MOVE SNAKE & WRAP EDGES
-- --------------------
INSERT INTO snake(x, y)
SELECT 
    (CASE snake_dir.dir
        WHEN 'L' THEN (h.x-1+32)%32
        WHEN 'R' THEN (h.x+1)%32
        ELSE h.x END),
    (CASE snake_dir.dir
        WHEN 'U' THEN (h.y-1+32)%32
        WHEN 'D' THEN (h.y+1)%32
        ELSE h.y END)
FROM (SELECT x, y FROM snake ORDER BY id DESC LIMIT 1) AS h, snake_dir;

-- --------------------
-- SELF-COLLISION DETECTION
-- If head overlaps body, reset snake
-- --------------------
DELETE FROM snake
WHERE EXISTS (
    SELECT 1 
    FROM snake s1, snake s2
    WHERE s1.id <> s2.id
    AND s1.x = s2.x AND s1.y = s2.y
);

-- --------------------
-- FOOD CHECK & TAIL DELETION (GROW SNAKE)
-- --------------------
-- Get head position
WITH head AS (SELECT x, y FROM snake ORDER BY id DESC LIMIT 1)
-- Delete tail if head did NOT eat food
DELETE FROM snake
WHERE id = (SELECT id FROM snake ORDER BY id ASC LIMIT 1)
AND NOT EXISTS (
    SELECT 1 FROM food f, head h WHERE f.x = h.x AND f.y = h.y
);

-- Delete eaten food
DELETE FROM food
WHERE (x, y) IN (SELECT x, y FROM snake ORDER BY id DESC LIMIT 1);

-- Spawn new food if none exists (avoid snake)
INSERT INTO food(x, y)
SELECT fx, fy
FROM (SELECT ABS(RANDOM()%32) AS fx, ABS(RANDOM()%32) AS fy)
WHERE NOT EXISTS (SELECT 1 FROM food)
AND NOT EXISTS (SELECT 1 FROM snake WHERE snake.x = fx AND snake.y = fy);

-- --------------------
-- DRAW SNAKE
-- --------------------
UPDATE framebuffer SET pixel=0;

UPDATE framebuffer
SET pixel=1
WHERE EXISTS(SELECT 1 FROM snake s WHERE s.x=framebuffer.x AND s.y=framebuffer.y);

-- --------------------
-- DRAW FOOD
-- --------------------
UPDATE framebuffer
SET pixel=1
WHERE EXISTS(SELECT 1 FROM food f WHERE f.x=framebuffer.x AND f.y=framebuffer.y);
