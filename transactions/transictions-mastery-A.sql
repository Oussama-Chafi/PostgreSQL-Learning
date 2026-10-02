-- Active: 1790373628720@@127.0.0.1@5432@postgres


DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULl,
    balance NUMERIC(10,2) NOT NULL
);

INSERT INTO accounts (name , balance) VALUES ('alice' , 700) , ('bob' , 300) , ('charlie' , 500) , ('lara' , 800);


-- OPEN A SESSION WITH BEGIN AND CANCEL ALL WITH ROLLBACK {CLOSE THE SESSION } --
BEGIN;
UPDATE accounts SET balance = balance -100 WHERE name = 'lara';
UPDATE accounts SET balance = balance +100 WHERE name = 'bob';
ROLLBACK;
SELECT * FROM accounts;


-- CONFIRM THE SESSION WITH COMMIT --
BEGIN;
UPDATE accounts SET balance = balance -200 WHERE name = 'alice';
UPDATE accounts SET balance = balance +200 WHERE name = 'bob';
COMMIT;
SELECT * FROM accounts;


-- CREATE SAVE POINT  AND RELEASE IT BEFORE COMMIT FOR THE PERFERMANCE IN THE SESSION --
BEGIN;
UPDATE accounts SET balance = balance -200 WHERE name = 'lara';
SAVEPOINT after_lara;
UPDATE accounts SET balance = balance -300 WHERE name = 'alice';
ROLLBACK TO SAVEPOINT after_lara;
UPDATE accounts SET balance = balance -200 WHERE name = 'bob';
RELEASE SAVEPOINT after_lara;
COMMIT;
SELECT * FROM accounts;


-- MVCC / CONCURRENCY ANOMALIES {dirty read , non-repeatable read , phantom read , write skew } --

BEGIN;
SELECT * FROM accounts WHERE name = 'alice';
ROLLBACK; 

-- we cannot get the dirty read because the engine of the postgresql implement the MVCC method but the repeatable read is applied;

-- but this time with no repeatable read | now the balance of alice will stay in 1200
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM accounts WHERE name = 'alice';
ROLLBACK;

-- and also the command {ISOLATION LEVEL REPEATABLE READ} prevent PHANTOM READ
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM accounts;
COMMIT;

-- WE USE ALSO SERIALIZABLE IF THERE IS FOR EX. TWO PEAPOLE DO THE SAME THIGN IN THE SAME SECOND 
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM accounts WHERE name = 'alice';
UPDATE accounts SET balance = balance +100 WHERE name = 'alice';
COMMIT;
-- so now after the first commit in any session for ex. if this session did commit first, the next session cannot update this var.
-- and we got this error : could not serialize access due to concurrent update
SELECT * FROM accounts WHERE name = 'alice';

-- EXPLICIT LOCKING --;
-- FOR UPDATE

BEGIN;
SELECT * FROM accounts WHERE name = 'bob' FOR UPDATE ;
COMMIT;
-- with this command {FOR UPDATE} no one can update this variable balance because it's lock 
-- and the request stay in waiting mod

-- NOWAIT 
-- and if we don't want to wait we just add {NOWAIT} commant and then we got an error:
-- could not obtain lock on row in relatic "accounts"
BEGIN;
SELECT * FROM accounts WHERE name = 'bob' FOR UPDATE;
COMMIT;

-- SKIP LOCKED;
BEGIN;
SELECT * FROM accounts FOR UPDATE SKIP LOCKED;
COMMIT;
-- we got all users expect bob, because it's lock in another session;

-- FOR SHARE;
BEGIN;
SELECT * FROM accounts FOR SHARE;
COMMIT;
-- with FOR SHARE we can let another session fetch the table but they cannot
-- update the column until we close for share session. 

-- DEAD BLOCK

BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE name = 'bob';
UPDATE accounts SET balance = balance -300 WHERE name = 'alice';
COMMIT;

-- here we got an error {deadblock detected} because the two session waiting each others
-- and the engine detected that.

--TABLE LEVEL LOCKES
BEGIN;
LOCK TABLE accounts IN EXCLUSIVE MODE NOWAIT;
COMMIT;
-- when we have already one session created and this session update or delete or..
-- we cannot close the table and we got error : could not obtain lock on relation "accounts";
-- but if this session just read the table we can close the table and if the first session 
-- try to update the column , then will stay in waiting until we COMMIT the session.

-- THERE IS ALSO ANOTHER COMMANDS LIKE {ACCESS EXCLUSIVE MODE , SHARE MODE}
-- ACCESS EXCLUSIVE MODE : this one prevent all CRUD propereties.
-- SHARE MODE : this one let us to read the table but we can't update or insert. 

