-- create tables 
CREATE TABLE patients (
    id INT GENERATED ALWAYS AS IDENTITY,
    first_name VARCHAR(50) CONSTRAINT check_first_name CHECK(length(btrim(first_name)) >= 2),
    last_name VARCHAR(50) CONSTRAINT check_last_name CHECK(length(btrim(last_name)) >= 2),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
ALTER TABLE
    patients
ADD
    COLUMN username VARCHAR(20)
ALTER TABLE
    patients
ADD
    PRIMARY KEY (id)
ALTER TABLE
    patients
ALTER COLUMN
    email
SET
    NOT NULL,
ADD
    CONSTRAINT unique_patient_email UNIQUE(email) CREATE TABLE doctors (
        id INT GENERATED ALWAYS AS IDENTITY,
        first_name VARCHAR(50) CONSTRAINT check_first_name CHECK(length(btrim(first_name)) >= 2),
        last_name VARCHAR(50) CONSTRAINT check_last_name CHECK(length(btrim(last_name)) >= 2),
        username VARCHAR(50),
        email VARCHAR(100),
        specialty VARCHAR(30) NOT NULL,
        phone VARCHAR(10),
        PRIMARY KEY (id, email, phone, username),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
ALTER TABLE
    doctors DROP CONSTRAINT doctors_pkey
ALTER TABLE
    doctors
ADD
    PRIMARY KEY(id)
ALTER TABLE
    doctors
ALTER COLUMN
    email
SET
    NOT NULL,
ALTER COLUMN
    phone
SET
    NOT NULL,
ALTER COLUMN
    username
SET
    NOT NULL,
ADD
    CONSTRAINT doctor_email UNIQUE(email),
ADD
    CONSTRAINT doctor_phone UNIQUE(phone),
ADD
    CONSTRAINT doctor_username UNIQUE(username) CREATE TABLE doctorSlots (
        id INT GENERATED ALWAYS AS IDENTITY,
        doctor_id INT REFERENCES doctors(id) ON DELETE CASCADE,
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        isBooked BOOLEAN NOT NULL,
        PRIMARY KEY(id, doctor_id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
ALTER TABLE
    doctorslots DROP CONSTRAINT doctorslots_pkey
ALTER TABLE
    doctorslots
ADD
    PRIMARY KEY(id) CREATE TABLE appointment (
        id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        doctor_id INT REFERENCES doctors(id),
        patient_id INT REFERENCES patients(id),
        slot_id INT REFERENCES doctorSlots(id),
        statusAppointment TEXT NOT NULL CONSTRAINT status_options CHECK(
            statusAppointment IN (
                'confirmed',
                'cancelled',
                'rejected',
                'completed'
            )
        )
    );
-- RLS Row Security Policies
ALTER TABLE appointment ENABLE ROW LEVEL SECURITY;

CREATE POLICY patient_policy ON appointment FOR SELECT USING(patient_id = current_setting('app.current_user_id')::INT) -- now the user can just select his appointments

ALTER TABLE
    appointment DROP COLUMN doctor_id CASCADE CREATE TABLE prescriptions (
        id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        appointment_id INT REFERENCES appointment(id),
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE medicines (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
) CREATE TABLE prescription_items (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prescription_id INT REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_id INT REFERENCES medicines(id) ON DELETE RESTRICT,
    dosage VARCHAR(50) NOT NULL,
    duration VARCHAR(50) NOT NULL
);

CREATE TABLE appointment_review (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    appointment_id INT REFERENCES appointment(id) ON DELETE RESTRICT,
    stars NUMERIC(2, 1) DEFAULT 0.0,
    review VARCHAR(200) NOT NULL
);

-- system columns
INSERT INTO
    patients (first_name, last_name, email, username)
VALUES
    (
        'oussama',
        'oussama',
        'oussama@gmail.com',
        'oussamaOm'
    )
SELECT
    ctid,
    xmin,
    xmax,
    id,
    email,
    first_name
FROM
    patients
WHERE
    email = 'oussama@gmail.com' -- res1 before update : (0,1)	1100	0	2	oussama@gmail.com	oussama
UPDATE
    patients
SET
    first_name = 'Dev'
WHERE
    email = 'oussama@gmail.com' -- res2 after update : (0,2)	1101	0	2	oussama@gmail.com	Dev
    -- Privilages
SELECT
    CURRENT_USER CREATE ROLE patient_role WITH LOGIN PASSWORD '12345678' GRANT USAGE ON SCHEMA public TO patient_role GRANT
SELECT
    ON TABLE doctorSlots TO patient_role GRANT
SELECT
,
UPDATE
,
    DELETE,
INSERT
    ON TABLE appointment,
    appointment_review TO patient_role -- After we create connection with new role | response will be permission denied for table doctorSlots because we can just read {SELECT}
SELECT
    CURRENT_USER;

INSERT INTO
    doctorSlots (doctor_id, start_time, end_time, isBooked)
VALUES
    (1, '10:00', '11:00', FALSE);

-- DOCTOR_ROLE
CREATE ROLE doctor_role WITH LOGIN PASSWORD '12345678' GRANT USAGE ON SCHEMA public TO doctor_role GRANT
SELECT
,
UPDATE
,
    DELETE,
INSERT
    ON TABLE appointment,
    doctorSlots,
    prescriptions,
    prescription_items TO doctor_role;

SELECT
    CURRENT_USER
SELECT
    *
FROM
    doctorSlots;

INSERT INTO
    doctorSlots (doctor_id, start_time, end_time, isBooked)
VALUES
    (1, '10:00', '11:00', FALSE);

UPDATE
    doctorSlots
SET
    isBooked = TRUE
WHERE
    id = 15;

SELECT
FROM
    TABLE doctorSlots
WHERE
    id = 15;

DELETE FROM
    doctorSlots
WHERE
    id = 15;

DELETE FROM
    doctorSlots
WHERE
    id IN (12, 13, 14)
SELECT
    *
FROM
    doctorSlots;

-- SHOULD GET PREMISSION DENIED FOR TABLE DOCTORS WHEN WE TRY TO FETSHING
SELECT
    *
FROM
    doctors;

-- SCHEMAS
SELECT
    CURRENT_USER;

CREATE SCHEMA auth_schema;

SHOW search_path;

-- update search_path to auth schema
SET
    search_path = auth_schema;

-- create users table in auth schema
CREATE TABLE users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    email VARCHAR(40) UNIQUE NOT NULL,
    password TEXT NOT null CHECK (length(btrim(password)) >= 8)
);

CREATE TABLE doctors (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT REFERENCES users(id),
    speciality VARCHAR(40) NOT NULL,
    phone VARCHAR(10) NOT NULL UNIQUE CONSTRAINT phone_check CHECK(length(btrim(phone)) = 10)
);

-- create another schema 
CREATE SCHEMA clinic;

SET
    search_path = clinic;

SHOW search_path;

CREATE TABLE slots (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    doctor_id INT REFERENCES auth_schema.doctors(id),
    isBooked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE
    slots
ADD
    COLUMN start_time TIME NOT NULL;

ALTER TABLE
    slots
ADD
    COLUMN end_time TIME NOT NULL;

CREATE TABLE appointments(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT REFERENCES auth_schema.users(id),
    slot_id INT REFERENCES slots(id),
    appointment_status TEXT CONSTRAINT status_value CHECK(
        appointment_status IN (
            'cancelled',
            'rejected',
            'confirmed',
            'completed'
        )
    ),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET
    search_path = auth_schema;

INSERT INTO
    users (first_name, last_name, email, password)
VALUES
    ('user1', 'user', 'user@gmail.com', '87654321'),
    (
        'user2',
        'doctor',
        'doctor@gmail.com',
        '87654321'
    );

SELECT
    *
FROM
    users;

INSERT INTO
    doctors (user_id, speciality, phone)
VALUES
    (2, 'specialityTest', '1020301232');

SELECT
    d.speciality,
    d.phone,
    d.user_id,
    u.first_name,
    u.last_name,
    u.email
FROM
    doctors d
    JOIN users u ON d.user_id = u.id;

-- speciality	specialityTest   phone	1020301232  user_id 	2       first_name	user2       last_name	doctor      email	doctor@gmail.com;
SET
    search_path = clinic;

INSERT INTO
    slots (doctor_id, start_time, end_time)
VALUES
(1, '10:00', '11:00'),
(1, '14:00', '15:00');

SELECT
    *
FROM
    slots;

INSERT INTO
    appointments (user_id, slot_id, appointment_status)
VALUES
(1, 5, 'confirmed');

SELECT
    a.id,
    a.appointment_status,
    a.created_at,
    a.slot_id,
    a.user_id,
    u.first_name,
    u.last_name,
    u.email,
    d.speciality,
    d.phone,
    u2.first_name,
    u2.last_name,
    u2.email
FROM
    appointments a
    JOIN slots s ON a.slot_id = s.id
    JOIN auth_schema.users u ON a.user_id = u.id
    JOIN auth_schema.doctors d ON s.doctor_id = u.id
    JOIN auth_schema.users u2 ON d.user_id = u2.id;

--RESPONSE :  id	2    appointment_status	confirmed   created_at	2026-09-27 18:18:54.406826    slot_id	5     user_id	1     first_name	user1   last_name	user    
-- email	user@gmail.com  speciality	specialityTest  phone	1020301232  first_name	user2   last_name	doctor  email	doctor@gmail.com
-- Pretitioning
CREATE TABLE orders_partitioned (
    id INT GENERATED ALWAYS AS IDENTITY,
    product_name VARCHAR(50) NOT NULL CONSTRAINT name_check CHECK(length(btrim(product_name)) > 5),
    description TEXT NOT NULL CONSTRAINT des_check CHECK (length(btrim(description)) > 10),
    amount_price NUMERIC(10, 2) NOT NULL DEFAULT 10.00,
    order_date DATE NOT NULL,
    region TEXT NOT NULL,
    PRIMARY KEY (id, order_date, region)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2025 PARTITION OF orders_partitioned FOR
VALUES
FROM
    ('2025-01-01') TO ('2026-01-01') PARTITION BY LIST(region);

CREATE TABLE orders_2026 PARTITION OF orders_partitioned FOR
VALUES
FROM
    ('2026-01-01') TO ('2027-01-01') PARTITION BY LIST(region);

CREATE TABLE orders_default PARTITION OF orders_partitioned DEFAULT;

CREATE TABLE orders_2025_europe PARTITION OF orders_2025 FOR
VALUES
    IN ('DE', 'ES', 'FR', 'UK', 'I');

CREATE TABLE orders_2025_africa PARTITION OF orders_2025 FOR
VALUES
    IN ('MA', 'TS', 'EG');

CREATE TABLE orders_2026_europe PARTITION OF orders_2026 FOR
VALUES
    IN ('DE', 'ES', 'FR', 'UK', 'I');

CREATE TABLE orders_2026_africa PARTITION OF orders_2026 FOR
VALUES
    IN ('MA', 'TS', 'EG')
INSERT INTO
    orders_partitioned (
        product_name,
        description,
        amount_price,
        order_date,
        region
    )
VALUES
    (
        'product1',
        'product1 for testing1',
        593.99,
        '2025-02-03',
        'DE'
    ),
    (
        'product2',
        'product2 for testing2',
        493.99,
        '2026-05-03',
        'MA'
    ),
    (
        'product3',
        'product3 for testing3',
        593.99,
        '2025-12-25',
        'TS'
    ),
    (
        'product4',
        'product4 for testing4',
        593.99,
        '2024-02-03',
        'DE'
    ),
    (
        'product5',
        'product5 for testing5',
        593.99,
        '2026-02-03',
        'FR'
    )
SELECT
    *
FROM
    orders_partitioned;

SELECT
    *
FROM
    orders_2025;

SELECT
    *
FROM
    orders_2025_europe;

SELECT
    *
FROM
    orders_2026;

SELECT
    *
FROM
    orders_2026_europe;

SELECT
    *
FROM
    orders_2026_africa;

SELECT
    *
FROM
    orders_default;

-- Inheritance 
CREATE TABLE employees (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    salery NUMERIC(6, 2) NOT NULL
);

CREATE TABLE programmers(
    id INT REFERENCES employees(id) PRIMARY KEY,
    programming_language TEXT NOT NULL
);

INSERT INTO
    employees (
        first_name,
        last_name,
        email,
        password,
        salery
    )
VALUES
    (
        'USER',
        '1',
        'user1@gmail.com',
        '132',
        1935.99
    ),
    (
        'USER',
        '2',
        'user2@gmail.com',
        'afs',
        2501.99
    );

SELECT
    *
FROM
    employees;

INSERT INTO
    programmers (id, programming_language)
VALUES
    (3, 'postgreSQL');

SELECT
    e.first_name,
    e.last_name,
    e.email,
    e.salery,
    p.programming_language
FROM
    programmers p
    JOIN employees e ON p.id = e.id;

SELECT
    e.first_name,
    e.last_name,
    e.email,
    e.salery,
    p.programming_language
FROM
    employees e
    LEFT JOIN programmers p ON e.id = p.id;

    -- This command to connect with another database like MySQL =>  CREATE EXTENSION postgres_fdw; fdw === foriegn data wrapper