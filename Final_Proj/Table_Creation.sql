-- constraint
-- member 11+
-- Minor between adult >
-- female / male teams

-- combine FamilyMember with ClubMember 
--  At any time, a location can have a manager and any number of other personnel working at the location
-- mutual exlusion personnel vs HeadPersonnel
-- HeadPersonnel only assigned to headlocation
-- capacity location
-- What does this mean A minor club member can be associated with different family members at different times

-- payment constraints using trigger
CREATE TABLE Person (
    person_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    ssn VARCHAR(15) UNIQUE NOT NULL,
    medicare_number VARCHAR(20) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(10),
    email VARCHAR(100)
);

CREATE TABLE ClubMember (
    person_id INT PRIMARY KEY,
    member_id INT UNIQUE AUTO_INCREMENT,
    height DECIMAL(4,2),
    weight DECIMAL(5,2),
    is_minor BOOLEAN NOT NULL,
    status ENUM('Active', 'Inactive') DEFAULT 'Active',
    FOREIGN KEY (person_id) REFERENCES Person(person_id)
);


CREATE TABLE Personnel (
    person_id INT PRIMARY KEY,
    role ENUM('Administrator', 'Captain', 'Coach', 'Assistant Coach', 'Other') NOT NULL,
    mandate ENUM('Volunteer', 'Salaried') NOT NULL,
    FOREIGN KEY (person_id) REFERENCES Person(person_id)
);

CREATE TABLE HeadPersonnel (
    person_id INT PRIMARY KEY,
    role ENUM('General manager', 'Deputy manager', 'Treasurer', 'Secretary', 'Administrator') NOT NULL,
    mandate ENUM('Volunteer', 'Salaried') NOT NULL,
    FOREIGN KEY (person_id) REFERENCES Person(person_id)
);



CREATE TABLE FamilyMember (
    person_id INT,
    family_id INT,
    relationship ENUM('Father', 'Mother', 'Grandfather', 'Grandmother', 'Tutor', 'Partner', 'Friend', 'Other'),
    PRIMARY KEY (person_id,family_id),
    FOREIGN KEY (person_id) REFERENCES ClubMember(person_id),
    FOREIGN KEY (family_id) REFERENCES ClubMember(person_id)
);

CREATE TABLE SecondaryFamilyContact (
    member_id INT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone_number VARCHAR(20),
    relationship VARCHAR(50),
    PRIMARY KEY (member_id),
    FOREIGN KEY (member_id) REFERENCES ClubMember(member_id)
);


CREATE TABLE Location (
    location_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    type ENUM('Head', 'Branch') NOT NULL,
    address VARCHAR(255),
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(10),
    phone_number VARCHAR(20),
    web_address VARCHAR(100),
    max_capacity INT
);

CREATE TABLE PersonnelLocation (
    person_id INT,
    location_id INT,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (person_id, location_id, start_date),
    FOREIGN KEY (person_id) REFERENCES HeadPersonnel(person_id),
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
);

CREATE TABLE HeadPersonnelLocation (
    person_id INT,
    location_id INT,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (person_id, location_id, start_date),
    FOREIGN KEY (person_id) REFERENCES Personnel(person_id),
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
);


CREATE TABLE MemberLocation (
    person_id INT,
    location_id INT,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (person_id, location_id, start_date),
    FOREIGN KEY (person_id) REFERENCES ClubMember(person_id),
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
);


CREATE TABLE Hobby (
    hobby_id INT PRIMARY KEY AUTO_INCREMENT,
    name ENUM('volleyball', 'soccer', 'tennis', 'ping pong', 'swimming', 'hockey', 'golf') UNIQUE NOT NULL
);


CREATE TABLE MemberHobby (
    member_id INT,
    hobby_id INT,
    PRIMARY KEY (member_id, hobby_id),
    FOREIGN KEY (member_id) REFERENCES ClubMember(member_id),
    FOREIGN KEY (hobby_id) REFERENCES Hobby(hobby_id)
);


CREATE TABLE Payment (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT,
    payment_date DATE NOT NULL,
    amount DECIMAL(8,2) NOT NULL,
    method ENUM('Cash', 'Debit Card', 'Credit Card'),
    membership_year YEAR NOT NULL,
    FOREIGN KEY (member_id) REFERENCES ClubMember(member_id)
);



CREATE TABLE Team (
    team_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    location_id INT,
    gender ENUM('Male', 'Female'),
    head_coach_id INT,
    FOREIGN KEY (location_id) REFERENCES Location(location_id),
    FOREIGN KEY (head_coach_id) REFERENCES Personnel(person_id)
);




CREATE TABLE Session (
    session_id INT PRIMARY KEY AUTO_INCREMENT,
    team1_id INT,
    team2_id INT,
    session_type ENUM('Game', 'Training'),
    session_date DATE,
    session_time TIME,
    address VARCHAR(255),
    score_team1 INT,
    score_team2 INT,
    FOREIGN KEY (team1_id) REFERENCES Team(team_id),
    FOREIGN KEY (team2_id) REFERENCES Team(team_id)
);





CREATE TABLE TeamFormation (
    session_id INT,
    member_id INT,
    team_id INT,
    role ENUM('Goalkeeper', 'Defender', 'Midfielder', 'Forward'),
    PRIMARY KEY (session_id, member_id),
    FOREIGN KEY (session_id) REFERENCES Session(session_id),
    FOREIGN KEY (member_id) REFERENCES ClubMember(member_id),
    FOREIGN KEY (team_id) REFERENCES Team(team_id)
);

CREATE TABLE Email (
    email_id INT PRIMARY KEY AUTO_INCREMENT,
    send_date DATE NOT NULL,                         
    session_id INT NOT NULL,                         
    member_id INT NOT NULL,                          
    subject VARCHAR(255) NOT NULL,                   
    body TEXT NOT NULL,                              
    FOREIGN KEY (session_id) REFERENCES Session(session_id),
    FOREIGN KEY (member_id) REFERENCES ClubMember(member_id)
);

CREATE TABLE EmailLog (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    email_id INT NOT NULL,
    sender_location_id INT NOT NULL,
    CONSTRAINT fk_emaillog_email
        FOREIGN KEY (email_id) REFERENCES Email(email_id),
    CONSTRAINT fk_emaillog_location
        FOREIGN KEY (sender_location_id) REFERENCES Location(location_id)
);
