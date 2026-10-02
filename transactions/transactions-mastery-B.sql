-- Active: 1790884372632@@127.0.0.1@5432@postgres

-- THIS FOR NO-REPEATABLE READ;
BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE name = 'alice';
COMMIT;
ROLLBACK;
SELECT * FROM accounts WHERE name = 'alice';

-- THIS FOR PHANTOM READ;
BEGIN;
INSERT INTO accounts (name , balance ) VALUES ('amy' , 600);
COMMIT;
SELECT * FROM accounts;

-- THIS FOR WRITE SKEW;
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM accounts WHERE name = 'alice';
UPDATE accounts SET balance = balance +100 WHERE name = 'alice';
COMMIT

-- THIS FOR EXPLICIT LOCKING;
-- THIS FOR : FOR UPDATE;
BEGIN;
SELECT * FROM accounts WHERE name = 'bob' FOR UPDATE ;
COMMIT;

-- THIS FOR NOWAIT;
BEGIN;
SELECT * FROM accounts WHERE name = 'bob' FOR UPDATE NOWAIT;
COMMIT;

-- THIS FOR SKIP LOCKED;
BEGIN;
SELECT * FROM accounts WHERE name = 'bob' FOR UPDATE;
COMMIT;

-- THIS IS FOR : FOR SHARE;
BEGIN;
SELECT * FROM accounts;
UPDATE accounts SET balance = balance +100 WHERE name = 'alice';
COMMIT;

-- THIS IS FOR DEADBLOCK;
BEGIN;
UPDATE accounts SET balance = balance -200 WHERE name = 'alice';
UPDATE accounts SET balance = balance -100 WHERE name = 'bob';
COMMIT; 

-- THIS FOR EXCLUSIVE MODE;
BEGIN;
SELECT * FROM accounts;
UPDATE accounts SET balance = balance +100 WHERE name = 'alice';
COMMIT;