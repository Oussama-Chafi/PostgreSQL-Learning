
-- CREATE TABLE WITH 100000 USERS USING generate_series() fuction

CREATE TABLE users(
    id SERIAL PRIMARY KEY,
    username VARCHAR(100),
    email VARCHAR(100),
    status VARCHAR(20)
);

INSERT INTO users (username , email , status)
SELECT
'user_' || g,
'user_' || g || '@gmail.com',
'active'
FROM generate_series(1,100000) AS g;

SELECT count(*) FROM users;


-- now we gonna see how it's take to get the user without index;
EXPLAIN ANALYSE SELECT * FROM users WHERE username = 'user_99999';
-- The scan method here was (Seq Scan), whitch means the engine searched row by row.
-- Rows removed by filter : 99999.
-- Exection time was 76.563 ms, whitch is quite slow for a single record search.

--now with an index on row (username);
CREATE INDEX idx_users_username ON users(username);
EXPLAIN ANALYSE SELECT * FROM users WHERE username = 'user_99999';
-- Now using the index (idx_users_username).
-- Planing time was 0.369 ms.
-- Execution time was just 0.173 ms.
-- No rows were removed by filter. With Index Searches = 1, the engine fetched the exact row directly.
-- And also the engine accessed only 4 memory pages instead of 934 pages in scan method.

-- COMPOSITE INDEX --
-- This index can take many keys from the table 
--With scan method.
EXPLAIN ANALYSE SELECT * FROM users WHERE username = 'user_99899' AND email = 'user_99899@gmail.com'  ;
-- Execution time was just 0.369 ms because the username fild is unique.
-- But we have Filter feld.

-- Create Composite Index.
CREATE INDEX idx_users_username_email ON users(username , email);
EXPLAIN ANALYSE SELECT * FROM users WHERE username = 'user_89405' AND email ='user_89405@gmail.com';
-- Execution time was 0.111 and also Index Cond has two propereties username and email.
-- Order is importent, it's gonna work with username but if we search by email, the searching will be with scan method and this is (Left-Prefix-Rule).
-- And also we got here filter for email because we have already an index for username , and the engine use it because it's fast than the composite index.

-- Partial Index --

CREATE INDEX idx_users_inactive ON users(email); WHERE status = 'inactive';
EXPLAIN ANALYSE SELECT * FROM users WHERE email = 'user_29300@gmail.com' AND status = 'inactive';
-- To use this index we should search with email and status, because this index if for just (inactive) accounts.
-- Whitch means that all users with status 'inactive' and we need to know where is the user that we looking for.
-- And also we can't search with just an email in this index, because we don't know if this user inactive or active.
-- The point is that this index has just inactive users, so if our user is inactive then we should search with his email because it's unique.

-- Covering Index --
-- This index will create on one row but he can also save another felds, so he didn't need to fetch the table to get another felds.
CREATE INDEX idx_users_username_covering ON users(username) INCLUDE(email , status);
EXPLAIN ANALYSE SELECT email , status FROM users WHERE username = 'user_43943';
-- The method now is Index Only Scan, whitch means that the index now has email and status.
-- The engine now doesn't need to fetch the table to get the email and status.



-- Expression / Functional Index --
-- We can change all text to lower or uppper when we create an index.
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
 SELECT * FROM users WHERE LOWER(email) = LOWER('UsEr_43834@gmail.com');
 EXPLAIN ANALYSE SELECT * FROM users WHERE LOWER(email) = LOWER('UsEr_43834@gmail.com');
-- The engine now change the email to lowercase and also the input value to lowercase;


-- GIN : GENERALIZED INVERTED INDEX --
-- This index saves elements inside arrays and objects.
-- For EX. we have 'express' in many arrays.
-- The engine maps each internal element to the rows containing it like the next line.
-- 'express' = [row 1 ,row 3, row 10].
-- So when we search about express, now the index already has the rows that they has express.

-- create a table of developers with an array.
CREATE TABLE developers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    skills TEXT[]
)

INSERT INTO developers (name , skills) VALUES 
('john' , ARRAY['postgresql' , 'javascript']),
('sara' , ARRAY['node' , 'express' , 'postgresql' , 'react']),
('tom' , ARRAY['javascript' , 'react' , 'docker' , 'mongodb']);

EXPLAIN ANALYSE SELECT * FROM developers WHERE skills @> ARRAY['docker'];
-- Without GIN index the method was sec scan (row by row);
-- Two rows removed by filter;
-- Execution time was 0.111 ms because the table has no many arrays.

-- create GIN index.
CREATE INDEX idx_developers_skills ON developers USING gin(skills);
-- using {USING gin} to skip the default  B-Tree.

-- set enable scan so we can use the index because the table has just thre columns
SET enable_seqscan = off;
EXPLAIN ANALYSE SELECT * FROM developers WHERE skills @> ARRAY['postgresql'];
-- The tag ( @> ) means is there any array has this value
-- The method now is Bitmap Heap Scan;
-- We don't have any rows has been removed by filter;
-- Execution time was 0.110 ms;


-- GIST INDEX
-- This index create many boxes for this table.
-- For EX. we have a table of booking, the GIST index create many boxes like
-- A table for days from 1st to 10st , another one from 11st to 20st and the last one from 21st to 31st.
-- And this table also has many tables for ex. 1st has has tables of hours from 8 am to 12 am and from 13 pm to 17pm and 
-- another one from 18 pm to 00 pm.

-- So when the user want to book the first day in october in 10 am to 12 pm.
-- The index now has a table of Morning , so he go direct to this table and check if the range of this user is available or not.
-- Because there is a change that this room has been booked from 9 am to 12 pm.

-- TSRANGE means timestamp and range.
CREATE TABLE room_bookings (
    id SERIAL PRIMARY KEY,
    room_id INT ,
    booking_time TSRANGE
);

INSERT INTO room_bookings (room_id , booking_time) VALUES
(101 , tsrange('2026-01-04 08:00' , '2026-01-04 10:00')),
(101 , tsrange('2026-01-04 09:00' , '2026-01-05 12:00')),
(102 , tsrange('2026-01-06 08:00' , '2026-01-07 10:00'))

-- create GIST Index --

CREATE INDEX idx_room_bookings_gist ON room_bookings USING gist(booking_time);

SHOW enable_seqscan;
SET enable_seqscan = off;

-- Using Overlap Operator ( && ) : is there any minute in this range 8:00 => 10:00 ==> overlap = true.
 SELECT * FROM room_bookings WHERE booking_time && tsrange('2026-01-04 08:30' , '2026-01-04 10:00');
-- We got here two available roms booking because the day is the same day and also this day in the range of the second value 


-- INDEX MAINTENANCE & OVERHEAD --

-- Indexes has also downsides (averhead):
-- 1 slows down write operations (INSERT , UPDATE , DELETE) because DB must update all indexes on that table.
-- 2 Indexes on multiple columns can grow larger than the table itself.
-- 3 Indexes require RAM to stay fast, campeting with actual table data for memory space.
-- The point is that we need just to create the indexes that we need for reading to make it fast.

-- To get dead indexes.
SELECT relname AS table_name, indexrelname AS index_name , idx_scan AS number_of_scan ,
pg_size_pretty(pg_relation_size(indexrelid)) AS index_size 
FROM pg_stat_user_indexes WHERE idx_scan =0 AND indexrelname NOT LIKE '%pkey';

-- Create an index so we can delete it;
CREATE INDEX delete_index ON users(email);

-- Drop dead indexes.
DROP INDEX delete_index;


