-- 0) Clean up any existing versions
DROP TRIGGER IF EXISTS check_member_age_dev;
DROP TRIGGER IF EXISTS enforce_sponsor_age_dev;
DROP TRIGGER IF EXISTS check_headpersonnel_location_dev;
DROP TRIGGER IF EXISTS check_location_capacity_dev;
DROP TRIGGER IF EXISTS validate_payment_installments_dev;
DROP TRIGGER IF EXISTS validate_payment_total_dev;

-- 1) Enforce minimum member age (11 years)
DELIMITER //
CREATE TRIGGER check_member_age_dev
BEFORE INSERT ON ClubMember_dev
FOR EACH ROW
BEGIN
    DECLARE age INT;

    SELECT TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())
      INTO age
    FROM Person_dev
    WHERE person_id = NEW.person_id;
    
    IF age < 11 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Member must be at least 11 years old';
    END IF;
END;
//
DELIMITER ;

-- 2) Enforce that any sponsor is at least 18
DELIMITER //
CREATE TRIGGER enforce_sponsor_age_dev
BEFORE INSERT ON ClubMember_dev
FOR EACH ROW
BEGIN
    DECLARE sponsor_age INT;

    IF NEW.main_sponsor_id IS NOT NULL THEN
        SELECT TIMESTAMPDIFF(
                 YEAR,
                 P.date_of_birth,
                 CURDATE()
               )
          INTO sponsor_age
        FROM Person_dev P
        JOIN ClubMember_dev C 
          ON P.person_id = C.person_id
        WHERE C.member_id = NEW.main_sponsor_id;

        IF sponsor_age < 18 THEN
            SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'Main sponsor must be at least 18 years old';
        END IF;
    END IF;
END;
//
DELIMITER ;

-- 3) Only HeadPersonnel can be assigned to Head locations
DELIMITER //
CREATE TRIGGER check_headpersonnel_location_dev
BEFORE INSERT ON HeadPersonnelLocation_dev
FOR EACH ROW
BEGIN
    DECLARE loc_type ENUM('Head','Branch');

    SELECT type
      INTO loc_type
      FROM Location_dev
     WHERE location_id = NEW.location_id;
    
    IF loc_type <> 'Head' THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Only head locations may be used here';
    END IF;
END;
//
DELIMITER ;

-- 4) Don’t exceed a location’s personnel capacity
DELIMITER //
CREATE TRIGGER check_location_capacity_dev
BEFORE INSERT ON MemberLocation_dev
FOR EACH ROW
BEGIN
    DECLARE current_count INT;
    DECLARE capacity     INT;
    
    SELECT COUNT(*)
      INTO current_count
      FROM MemberLocation_dev
     WHERE location_id = NEW.location_id
       AND (end_date IS NULL
            OR (start_date <= NEW.start_date
                AND NEW.start_date <= end_date));
    
    SELECT max_capacity
      INTO capacity
      FROM Location_dev
     WHERE location_id = NEW.location_id;
    
    IF current_count >= capacity THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Location personnel capacity exceeded';
    END IF;
END;
//
DELIMITER ;

-- 5) Max 4 payment installments per member per year
DELIMITER //
CREATE TRIGGER validate_payment_installments_dev
BEFORE INSERT ON Payment_dev
FOR EACH ROW
BEGIN
    DECLARE installments INT;

    SELECT COUNT(*)
      INTO installments
      FROM Payment_dev
     WHERE member_id = NEW.member_id
       AND YEAR(payment_date) = YEAR(NEW.payment_date);
    
    IF installments >= 4 THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Payment-installments limit (4) exceeded';
    END IF;
END;
//
DELIMITER ;

-- 6) Annual payment‐total cap: minors <100, adults <200
DELIMITER //
CREATE TRIGGER validate_payment_total_dev
BEFORE INSERT ON Payment_dev
FOR EACH ROW
BEGIN
    DECLARE total_payment DECIMAL(10,2) DEFAULT 0;
    DECLARE payer_age     INT;

    SELECT COALESCE(SUM(amount),0)
      INTO total_payment
      FROM Payment_dev
     WHERE member_id       = NEW.member_id
       AND membership_year = NEW.membership_year;

    SELECT TIMESTAMPDIFF(YEAR, P.date_of_birth, NEW.payment_date)
      INTO payer_age
      FROM Person_dev P
      JOIN ClubMember_dev C ON P.person_id = C.person_id
     WHERE C.member_id = NEW.member_id;

    IF (payer_age < 18  AND total_payment + NEW.amount >= 100)
       OR (payer_age >= 18 AND total_payment + NEW.amount >= 200) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Annual payment total limit exceeded';
    END IF;
END;
//
DELIMITER ;


-- testing triggers --

-- 1) Insert a dummy 10-year-old into Person_dev supplying every NOT NULL column
INSERT INTO Person_dev (
    person_id,
    first_name,
    last_name,
    date_of_birth,
    ssn,
    medicare_number,
    phone_number,
    address,
    city,
    province,
    postal_code,
    email
) VALUES (
    9999,
    'Test',
    'Kid',
    DATE_SUB(CURDATE(), INTERVAL 10 YEAR),
    'SSN99990001',
    'MED99990001',
    '555-0001',
    '1 Test St',
    'Montreal',
    'QC',
    'H3Z2Y7',
    'testkid9999@example.com'
);

-- 2) Now fire the age-check trigger (should throw the 11-year-minimum error)
INSERT INTO ClubMember_dev
  (member_id, person_id)
VALUES
  (9001, 9999);

INSERT INTO Person_dev (
    person_id, first_name, last_name, date_of_birth,
    ssn, medicare_number, phone_number,
    address, city, province, postal_code, email
) VALUES
  -- Under-18 sponsor (age 17)
  (10000,'Under','Sponsor', DATE_SUB(CURDATE(),INTERVAL 17 YEAR),
   'SSN10000','MED10000','555-10000',
   '100 Sponsor St','Montreal','QC','H1H1H1','under@ex.com'),

  -- Adult sponsor (age 20)
  (10001,'Adult','Sponsor', DATE_SUB(CURDATE(),INTERVAL 20 YEAR),
   'SSN10001','MED10001','555-10001',
   '101 Sponsor St','Montreal','QC','H1H1H1','adult@ex.com'),

  -- New member for testing (age 15)
  (10002,'Test','Member', DATE_SUB(CURDATE(),INTERVAL 15 YEAR),
   'SSN10002','MED10002','555-10002',
   '102 Member St','Montreal','QC','H1H1H1','test@ex.com');

INSERT INTO ClubMember_dev (member_id, person_id)
VALUES
  (10000,10000),  -- under-18 sponsor
  (10001,10001);  -- adult sponsor

-- Test with under-18 sponsor 
INSERT INTO ClubMember_dev
  (member_id, person_id, main_sponsor_id)
VALUES
  (11000, 10002, 10000);
  
-- Test with adult sponsor
INSERT INTO ClubMember_dev
  (member_id, person_id, is_minor, main_sponsor_id)
VALUES
  (11001, 10002, 1, 10001);

-- 1) Find a valid HeadPersonnel person_id
-- (run this first; note the number returned as your HEAD_ID)
SELECT 
  person_id            -- HEAD_ID: the ID of someone in HeadPersonnel_dev
FROM 
  HeadPersonnel_dev 
LIMIT 1;



-- 2) Find a Branch location_id
--    (run this; note the number returned as your BRANCH_LOC)
SELECT 
  location_id          -- BRANCH_LOC: a location marked type='Branch'
FROM 
  Location_dev 
WHERE 
  type = 'Branch' 
LIMIT 1;



-- 3) Find a Head location_id
--    (run this; note the number returned as your HEAD_LOC)
SELECT 
  location_id          -- HEAD_LOC: a location marked type='Head'
FROM 
  Location_dev 
WHERE 
  type = 'Head' 
LIMIT 1;



-- 4) Test with a BRANCH location (should FAIL the trigger)
--    person_id = 4     ← your HEAD_ID from HeadPersonnel_dev
--    location_id = 11  ← your BRANCH_LOC from Location_dev WHERE type='Branch'
INSERT INTO HeadPersonnelLocation_dev (
    person_id,       -- HEAD personnel’s person_id
    location_id,     -- branch location
    start_date       -- assignment start date
) VALUES (
    4,                -- HEAD_ID
    11,               -- BRANCH_LOC
    CURDATE()         -- today
);
-- Expect ERROR 1644 (45000): Only head locations may be used here


-- 5) Test with a HEAD location (should SUCCEED)
--    person_id = 4    ← same HEAD_ID
--    location_id = 10 ← your HEAD_LOC from Location_dev WHERE type='Head'
INSERT INTO HeadPersonnelLocation_dev (
    person_id,       -- HEAD personnel’s person_id
    location_id,     -- head location
    start_date
) VALUES (
    4,                -- HEAD_ID
    10,               -- HEAD_LOC
    CURDATE()         -- today
);
-- Expect Query OK, 1 row affected


-- Insert a ClubMember for our capacity test so we satisfy the FK
INSERT INTO ClubMember_dev (
    member_id,
    person_id
) VALUES (
    12000,        -- new member ID
    10002         -- a Person_dev you already created (age ≥11)
);
-- Expect: Query OK, 1 row affected


-- ================================================
-- TESTING check_location_capacity_dev trigger
-- ================================================

-- 1) First insert at TEST_LOC = 13 (should SUCCEED)
--    current_count = 0, max_capacity (from your SELECT) = 120
INSERT INTO MemberLocation_dev (
    member_id, 
    location_id, 
    start_date
) VALUES (
    12000,       -- fresh member
    13,          -- TEST_LOC (smallest capacity, which is 120)
    CURDATE()
);
-- Expect: Query OK, 1 row affected


INSERT INTO ClubMember_dev (
    member_id,    -- new member for capacity test
    person_id     -- use an existing Person_dev (e.g. your 15-year-old, id=10002)
) VALUES (
    12001,        -- the same member_id you’ll use below
    10002         -- any valid person_id that’s already ≥11
);
-- Expect: Query OK, 1 row affected

-- 2) INSERT #2: capacity not yet exceeded (should now SUCCEED)
--    TEST: check_location_capacity_dev allows this because current_count < max_capacity

INSERT INTO MemberLocation_dev (
    member_id,    -- now exists in ClubMember_dev
    location_id,  -- TEST_LOC (13)
    start_date
) VALUES (
    12001,        -- matches the ClubMember_dev row we just made
    13,           -- your TEST_LOC from the SELECT
    CURDATE()
);
-- Expect: Query OK, 1 row affected


-- To see the FAILURE case without doing 120 inserts,
-- temporarily tighten max_capacity to 1:
UPDATE Location_dev
   SET max_capacity = 1
 WHERE location_id = 13;

-- 3) Now this insert should FAIL:
INSERT INTO MemberLocation_dev (
    member_id, 
    location_id, 
    start_date
) VALUES (
    12002,
    13,
    CURDATE()
);
-- Expect: ERROR 1644 (45000): Location personnel capacity exceeded

-- revert the capacity so you don’t break other tests:
UPDATE Location_dev
   SET max_capacity = 120
 WHERE location_id = 13;


-- ================================================
-- TESTING validate_payment_installments_dev
-- ================================================

-- 1) INSERT 4 payments in 2025 (should SUCCEED)
--    Tests that up to 4 installments are allowed.
INSERT INTO Payment_dev (
    payment_id, 
    member_id, 
    payment_date, 
    amount, 
    membership_year
) VALUES
    (20001, 12000, '2025-08-01', 10, 2025),  -- 1st
    (20002, 12000, '2025-08-02', 10, 2025),  -- 2nd
    (20003, 12000, '2025-08-03', 10, 2025),  -- 3rd
    (20004, 12000, '2025-08-04', 10, 2025);  -- 4th
-- Expect: Query OK, 4 rows affected

-- 2) INSERT 5th payment in 2025 (should FAIL)
INSERT INTO Payment_dev (
    payment_id, 
    member_id, 
    payment_date, 
    amount, 
    membership_year
) VALUES
    (20005, 12000, '2025-08-05', 10, 2025);
-- Expect: ERROR 1644 (45000): Payment-installments limit (4) exceeded


-- ================================================
-- TESTING validate_payment_total_dev
-- ================================================

-- 1) Remove any prior payments for member 13000 in 2025
DELETE FROM Payment_dev
 WHERE member_id = 13000
   AND membership_year = 2025;

-- 2) Insert two payments totalling 99 for 2025 (should SUCCEED)
INSERT INTO Payment_dev
  (payment_id, member_id, payment_date, amount, membership_year)
VALUES
  (30001, 13000, '2025-08-10', 60, 2025),
  (30002, 13000, '2025-08-11', 39, 2025);

-- 3) Insert a third payment to hit 101 for 2025 (should FAIL)
INSERT INTO Payment_dev
  (payment_id, member_id, payment_date, amount, membership_year)
VALUES
  (30003, 13000, '2025-08-12', 2, 2025);
