-- Table: Person
CREATE TABLE Person (
    SIN VARCHAR(9) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    medicare_card_number VARCHAR(30),
    address VARCHAR(100),
    city VARCHAR(50),
    province VARCHAR(50),
    telephone_number VARCHAR(20),
    email_address VARCHAR(100),
    postal_code VARCHAR(6),
    gender VARCHAR(10),
    
);

-- Table: ClubMember
CREATE TABLE ClubMember (
    ID VARCHAR(20) PRIMARY KEY,
    SIN VARCHAR(20),
    weight FLOAT,
    height FLOAT,
    major_or_minor VARCHAR(10),
    progress VARCHAR(100),
    guardianID INT,
    FOREIGN KEY (SIN) REFERENCES Person(SIN)
);

-- Table: FamilyMember
CREATE TABLE FamilyMember (
    ID VARCHAR(20) PRIMARY KEY,
    FOREIGN KEY (ID) REFERENCES ClubMember(ID)
);

-- Table: MinorMember
CREATE TABLE MinorMember (
    ID VARCHAR(20) PRIMARY KEY,
    guardianID VARCHAR(20),
    FOREIGN KEY (ID) REFERENCES ClubMember(ID),
    FOREIGN KEY (guardianID) REFERENCES FamilyMember(ID)
);

-- Table: Payment
CREATE TABLE Payment (
    ClubMemberNumber VARCHAR(20),
    PaymentDate DATE,
    AmountOfPayment DECIMAL(10, 2),
    MethodOfPayment VARCHAR(30),
    DateOfMembershipPayment DATE,
    PRIMARY KEY (ClubMemberNumber, PaymentDate),
    FOREIGN KEY (ClubMemberNumber) REFERENCES ClubMember(ID)
);

-- Table: Hobby
CREATE TABLE Hobbies (
    ID INT PRIMARY KEY,
    Name VARCHAR(30),
    ClubMemberID VARCHAR(20),
    FOREIGN KEY (ClubMemberID) REFERENCES ClubMember(ID)
);

-- Table: HasHobby
CREATE TABLE HasHobby (
    HobbyID INT,
    ClubMemberID VARCHAR(20),
    PRIMARY KEY (HobbyID,ClubMemberID),
    FOREIGN KEY (HobbyID) REFERENCES Hobbies(ID),
    FOREIGN KEY (ClubMemberID) REFERENCES ClubMember(ID)
);






-- Table: Location
CREATE TABLE Location (
    ID INT PRIMARY KEY,
    name VARCHAR(100),
    capacity INT
);


-- Table: Team
CREATE TABLE Team (
    ID INT PRIMARY KEY,
    Gender VARCHAR(10),
    LocationID INT,
    FOREIGN KEY (LocationID) REFERENCES Location(ID)
);


-- Association Table: ClubMember_Team (joins)
CREATE TABLE ClubMember_Team (
    ClubMemberID VARCHAR(20),
    TeamID INT,
    PRIMARY KEY (ClubMemberID, TeamID),
    FOREIGN KEY (ClubMemberID) REFERENCES ClubMember(ID),
    FOREIGN KEY (TeamID) REFERENCES Team(ID)
);



-- Table: HeadLocation
CREATE TABLE HeadLocation (
    ID INT PRIMARY KEY,
    FOREIGN KEY (ID) REFERENCES Location(ID)
);

-- Table: MemberLocationGivenTime (Member-Location-Time relationship)
CREATE TABLE MemberLocationGivenTime (
    ClubMemberID VARCHAR(20),
    LocationID INT,
    time DATETIME,
    PRIMARY KEY (ClubMemberID, LocationID, time),
    FOREIGN KEY (ClubMemberID) REFERENCES ClubMember(ID),
    FOREIGN KEY (LocationID) REFERENCES Location(ID)
);

-- Table: ClubRole
CREATE TABLE ClubRoles (
    ID INT PRIMARY KEY,
    ClubRole VARCHAR(50)
);


-- Table: Personnel
CREATE TABLE Personnel (
    ID INT PRIMARY KEY,
    SIN VARCHAR(9),
    ClubRoleID INT,
    Mandate VARCHAR(20),
    FOREIGN KEY (SIN) REFERENCES Person(SIN),
    FOREIGN KEY (ClubRoleID) REFERENCES ClubRoles(ID)
);


-- Table: HeadPersonnel
CREATE TABLE HeadPersonnel (
    ID INT PRIMARY KEY,
    FOREIGN KEY (ID) REFERENCES Personnel(ID)
  
    
);


-- Table: HeadRole
CREATE TABLE HeadRoles (
    ID INT PRIMARY KEY,
    HeadRole VARCHAR(50)
    
);
-- Table: HeadPersonnelHeadRoles
CREATE TABLE HeadPersonnelHeadRoles (
    HeadPersonnelID INT UNIQUE,
    HeadRoleID INT UNIQUE,
    PRIMARY KEY (HeadPersonnelID,HeadRoleID),
    FOREIGN KEY (HeadPersonnelID) REFERENCES HeadPersonnel(ID),
    FOREIGN KEY (HeadRoleID) REFERENCES HeadRoles(ID)
    
    
);







-- Table: TimePeriod
CREATE TABLE TimePeriod (
    ID INT PRIMARY KEY,
    startTime DATETIME,
    endTime DATETIME
);


-- Table: WorkingLocation
CREATE TABLE WorkingLocation (
    PersonnelID INT,
    LocationID INT,
    TimePeriodID INT,
    PRIMARY KEY (PersonnelID, LocationID, TimePeriodID),
    FOREIGN KEY (PersonnelID) REFERENCES Personnel(ID),
    FOREIGN KEY (LocationID) REFERENCES Location(ID),
    FOREIGN KEY (TimePeriodID) REFERENCES TimePeriod(ID)
);
