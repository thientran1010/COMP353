DELIMITER //
CREATE TRIGGER check_member_age
BEFORE INSERT ON ClubMember
FOR EACH ROW
BEGIN
    DECLARE age INT;
    SELECT TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) INTO age
    FROM Person WHERE person_id = NEW.person_id;
    
    IF age < 11 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Member must be at least 11 years old';
        SET NEW.person_id=NULL;
    END IF;
END;

//

DELIMITER ;

ALTER TABLE ClubMember
ADD CONSTRAINT CHK_More_Than_Elv
CHECK((is_minor =true AND main_sponsor_id IS NOT NULL) OR (is_minor =false AND main_sponsor_id IS NULL));




DELIMITER //

CREATE TRIGGER Enforce_Acc_minor
BEFORE INSERT ON ClubMember
FOR EACH ROW
BEGIN


    IF  new.is_minor =true AND NEW.main_sponsor_id NOT IN (SELECT person_id FROM ClubMember WHERE is_minor=false)  THEN
    
        SET NEW.main_sponsor_id = NULL; 
        SIGNAL SQLSTATE '45000'   
        SET MESSAGE_TEXT = 'Main Sponsor must be older than 17';
    END IF;
END;
//

DELIMITER ;

-- Enforce Team Player Gender
DELIMITER //
CREATE TRIGGER check_team_gender
BEFORE INSERT ON TeamFormation
FOR EACH ROW
BEGIN
    DECLARE member_gender ENUM('Male', 'Female');
    DECLARE team_gender ENUM('Male', 'Female');
    
    
    SELECT gender INTO member_gender FROM Person
    WHERE person_id = (SELECT person_id FROM ClubMember WHERE member_id = NEW.member_id);
    
    SELECT gender INTO team_gender FROM Team WHERE team_id = NEW.team_id;
    
    IF member_gender != team_gender THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team gender must match member gender.';
        SET NEW.session_id=NULL;
    END IF;
END;

//

DELIMITER ;



DELIMITER //
CREATE TRIGGER check_player_location
BEFORE INSERT ON TeamFormation
FOR EACH ROW
BEGIN
    DECLARE team_location INT;
    DECLARE player_location INT;
    
    SELECT location_id INTO player_location FROM MemberLocation
    WHERE member_id = NEW.member_id AND MemberLocation.end_date IS NULL; 
    
    SELECT location_id INTO team_location FROM Team
    WHERE team_id = NEW.team_id; 

    
    IF team_location != player_location THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Player and team must be at the same location.';
        SET NEW.session_id=NULL;
    END IF;
END;

//

DELIMITER ;

-- Only HeadPersonnel can work at headlocation 
DELIMITER //
CREATE TRIGGER check_headpersonnel_location
BEFORE INSERT ON HeadPersonnelLocation
FOR EACH ROW
BEGIN
    DECLARE location_type ENUM('Head', 'Branch');
    DECLARE headperson_id INT;
    SELECT type INTO location_type FROM Location WHERE location_id = NEW.location_id;
    SELECT person_id into headperson_id FROM HeadPersonnel WHERE person_id=new.person_id;
    
    IF location_type != 'Head' OR headperson_id<>new.person_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Branch location cannot be assigned to headlocation';
        SET new.person_id=NULL;
    END IF;
    IF headperson_id<>new.person_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only HeadPersonnel can be assigned to head locations';
        SET new.person_id=NULL;
    END IF;
END;


//

DELIMITER ;



DELIMITER //
CREATE TRIGGER check_location_capacity
BEFORE INSERT ON MemberLocation
FOR EACH ROW
BEGIN
    DECLARE current_count INT;
    DECLARE capacity INT;
    
    SELECT COUNT(*) INTO current_count FROM MemberLocation
    WHERE location_id = NEW.location_id AND ((new.end_date IS NULL and end_date IS NULL) OR (start_date <= new.start_date and new.start_date<= end_date) );
    
    SELECT max_capacity INTO capacity FROM Location WHERE location_id = NEW.location_id;
    
    IF current_count > capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Location personnel capacity exceeded.';
    END IF;
END;

//

DELIMITER ;


DELIMITER //
CREATE TRIGGER validate_payment
BEFORE INSERT ON Payment
FOR EACH ROW
BEGIN
    DECLARE installments int;
    SELECT count(*) INTO installments FROM Payment
    WHERE member_id = new.member_id AND YEAR(payment_date) = YEAR(new.payment_date)
    GROUP BY YEAR(payment_date);
    
    IF installments >= 4 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment_installments exceeded.';
    END IF;
    
      
    
    
END;

//

DELIMITER ;




DELIMITER //
CREATE TRIGGER validate_status_member
BEFORE INSERT ON Payment
FOR EACH ROW
BEGIN
    DECLARE total_payment DECIMAL;
    DECLARE is_minor_true BOOLEAN;
    
    SELECT SUM(amount) INTO total_payment FROM Payment
    WHERE member_id = new.member_id AND YEAR(payment_date) = YEAR(new.payment_date)
    GROUP BY YEAR(payment_date);
    
    SELECT is_minor INTO is_minor_true FROM ClubMember
    WHERE member_id = new.member_id;
    

    
    IF (total_payment>=100 AND is_minor_true=true) OR (total_payment>=200 AND is_minor_true=false) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'payment_installments exceeded.';
      
    END IF;
    
      
    
END;
//
DELIMITER ;
