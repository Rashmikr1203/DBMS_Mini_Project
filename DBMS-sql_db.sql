CREATE DATABASE Library_mngmt_system_final;
USE Library_mngmt_system_final;

-- Table Definitions
CREATE TABLE Book (
    book_id INT PRIMARY KEY,
    title VARCHAR(255),
    author VARCHAR(255),
    ISBN VARCHAR(13) UNIQUE,
    edition VARCHAR(50),
    publisher VARCHAR(255),
    publication_year INT,
    is_digital BOOLEAN,
    shelf_number INT,
    availability BOOLEAN
);

CREATE TABLE User (
    user_id INT PRIMARY KEY,
    name VARCHAR(255),
    role VARCHAR(50),
    contact_details VARCHAR(255),
    email_notification BOOLEAN
);

CREATE TABLE Library (
    library_id INT PRIMARY KEY,
    library_name VARCHAR(255),
    location VARCHAR(255),
    is_dept_library BOOLEAN,
    is_central_library BOOLEAN,
    plagiarism_check BOOLEAN DEFAULT FALSE
);

CREATE TABLE Transaction (
    transaction_id INT PRIMARY KEY,
    book_id INT,
    user_id INT,
    item_type VARCHAR(50),
    date_borrowed DATE,
    return_date DATE,
    damage_fine DECIMAL(10, 2),
    late_fees DECIMAL(10, 2),
    FOREIGN KEY (book_id) REFERENCES Book(book_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

CREATE TABLE Fine_Payment (
    payment_id INT PRIMARY KEY,
    transaction_id INT,
    fine_amount DECIMAL(10, 2),
    payment_date DATE,
    FOREIGN KEY (transaction_id) REFERENCES Transaction(transaction_id)
);

CREATE TABLE Notification (
    notification_id INT PRIMARY KEY,
    user_id INT,
    notification_type VARCHAR(100),
    notification_date DATE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

CREATE TABLE Research_Paper (
    paper_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255),
    publisher VARCHAR(255),
    publication_year YEAR,
    publication_frequency ENUM('Monthly', 'Quarterly', 'Annually'),
    is_digital BOOLEAN DEFAULT FALSE,
    subscription_status ENUM('Active', 'Expired'),
    library_id INT,
    FOREIGN KEY (library_id) REFERENCES Library(library_id)
);

CREATE TABLE Staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    role ENUM('Librarian', 'Assistant', 'Manager', 'Maintenance'),
    contact_details VARCHAR(100),
    salary DECIMAL(10, 2),
    library_id INT,
    FOREIGN KEY (library_id) REFERENCES Library(library_id)
);

CREATE TABLE Acquisition (
    acquisition_id INT PRIMARY KEY AUTO_INCREMENT,
    item_type ENUM('Book', 'Research Paper', 'Magazine', 'Journal') NOT NULL,
    item_id INT NOT NULL,
    acquisition_date DATE,
    supplier_name VARCHAR(255),
    staff_id INT,
    library_id INT,
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id),
    FOREIGN KEY (library_id) REFERENCES Library(library_id)
);

-- Function Definitions
DELIMITER //

-- Function to calculate late fee based on days overdue
CREATE FUNCTION CalculateLateFee(borrow_date DATE, return_date DATE)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE days_late INT DEFAULT 0;
    DECLARE fee DECIMAL(10, 2) DEFAULT 0.00;

    SET days_late = DATEDIFF(return_date, DATE_ADD(borrow_date, INTERVAL 14 DAY));
    SET fee = IF(days_late > 0, days_late * 60.00, 0.00);
    RETURN fee;
END //

-- Function to calculate average salary by role
CREATE FUNCTION AvgSalaryByRole(p_role ENUM('Librarian', 'Assistant', 'Manager', 'Maintenance'))
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE avg_salary DECIMAL(10, 2);

    SELECT AVG(salary) INTO avg_salary FROM Staff WHERE role = p_role;
    RETURN IFNULL(avg_salary, 0.00); -- Use IFNULL to avoid NULL returns
END //

-- Function to check if a research paper is digital
CREATE FUNCTION isDigitalResearchPaper(p_paper_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE is_digital BOOLEAN DEFAULT FALSE;

    SELECT is_digital INTO is_digital FROM Research_Paper WHERE paper_id = p_paper_id;
    RETURN IFNULL(is_digital, FALSE); -- Use IFNULL to avoid NULL returns
END //

-- Function to check if a library has plagiarism checking service
CREATE FUNCTION CheckPlagiarismService(p_library_id INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE plagiarism_available BOOLEAN DEFAULT FALSE;

    SELECT plagiarism_check INTO plagiarism_available FROM Library WHERE library_id = p_library_id;
    RETURN IFNULL(plagiarism_available, FALSE); -- Use IFNULL to avoid NULL returns
END //

DELIMITER ;

-- Data Insertion Statements
-- Example of inserting data into tables
INSERT INTO Book (book_id, title, author, ISBN, edition, publisher, publication_year, is_digital, shelf_number, availability)
VALUES (1, 'Introduction to Algorithms', 'Thomas H. Cormen', '9780262033848', '3rd', 'MIT Press', 2009, FALSE, 101, TRUE), 
       (2, 'The Pragmatic Programmer', 'Andrew Hunt', '9780201616224', '1st', 'Addison-Wesley', 1999, TRUE, 102, TRUE);

-- Insert additional data as per requirement.
-- Set custom delimiter to avoid conflicts with `;` inside the function bodies
DELIMITER //

-- Drop existing functions to avoid conflicts
DROP FUNCTION IF EXISTS CalculateLateFee //
DROP FUNCTION IF EXISTS AvgSalaryByRole //
DROP FUNCTION IF EXISTS IsDigital //
DROP FUNCTION IF EXISTS CheckPlagiarismService //

-- Function to calculate late fee based on borrow and return dates
CREATE FUNCTION CalculateLateFee(borrow_date DATE, return_date DATE)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE days_late INT;
    DECLARE fee DECIMAL(10, 2);

    -- Assuming a 14-day borrowing period
    SET days_late = DATEDIFF(return_date, DATE_ADD(borrow_date, INTERVAL 14 DAY));
    IF days_late > 0 THEN
        SET fee = days_late * 60.00; -- RS. 60 fine per day late
    ELSE
        SET fee = 0;
    END IF;

    RETURN fee;
END //

-- Function to calculate the average salary by role
CREATE FUNCTION AvgSalaryByRole(p_role ENUM('Librarian', 'Assistant', 'Manager', 'Maintenance'))
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE avg_salary DECIMAL(10, 2);
    SELECT AVG(salary) INTO avg_salary FROM staff WHERE role = p_role;
    RETURN avg_salary;
END //

-- Function to check if a research paper is digital
CREATE FUNCTION IsDigital(p_paper_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE is_digital BOOLEAN;

    -- Retrieve the digital access status of the research paper
    SELECT is_digital INTO is_digital 
    FROM research_paper 
    WHERE paper_id = p_paper_id;

    RETURN is_digital;
END //

-- Function to check if plagiarism checking service is available for a library
CREATE FUNCTION CheckPlagiarismService(p_library_id INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE plagiarism_available BOOLEAN;
    SELECT plagiarism_check INTO plagiarism_available FROM library WHERE library_id = p_library_id;
    RETURN plagiarism_available;
END //

-- Reset delimiter to default
DELIMITER ;

SHOW TABLES;
DESC Book;
DESC User;
DESC Library;
DESC Transaction;
DESC Fine_Payment;
DESC Notification;
DESC Research_Paper;
DESC Staff;
DESC Acquisition;


-- Insert 20 entries into the Book table
INSERT INTO Book (book_id, title, author, ISBN, edition, publisher, publication_year, is_digital, shelf_number, availability) VALUES
(3, 'Clean Code', 'Robert C. Martin', '9780132350884', '1st', 'Prentice Hall', 2008, TRUE, 103, FALSE),
(4, 'Design Patterns', 'Erich Gamma', '9780201633610', '1st', 'Addison-Wesley', 1994, FALSE, 104, TRUE),
(5, 'Refactoring', 'Martin Fowler', '9780201485677', '2nd', 'Addison-Wesley', 2018, TRUE, 105, FALSE),
(6, 'Effective Java', 'Joshua Bloch', '9780134685991', '3rd', 'Addison-Wesley', 2017, FALSE, 106, TRUE),
(7, 'Java Concurrency in Practice', 'Brian Goetz', '9780321349606', '1st', 'Addison-Wesley', 2006, TRUE, 107, TRUE),
(8, 'Code Complete', 'Steve McConnell', '9780735619678', '2nd', 'Microsoft Press', 2004, FALSE, 108, FALSE),
(9, 'Structure and Interpretation of Computer Programs', 'Harold Abelson', '9780262510874', '2nd', 'MIT Press', 1996, TRUE, 109, TRUE),
(10, 'Algorithms', 'Robert Sedgewick', '9780321573513', '4th', 'Addison-Wesley', 2011, TRUE, 110, FALSE),
(11, 'Operating System Concepts', 'Abraham Silberschatz', '9781119456339', '10th', 'Wiley', 2018, FALSE, 111, TRUE),
(12, 'Computer Networking', 'James F. Kurose', '9780133594140', '7th', 'Pearson', 2016, TRUE, 112, TRUE),
(13, 'Artificial Intelligence: A Modern Approach', 'Stuart Russell', '9780136042594', '3rd', 'Pearson', 2009, FALSE, 113, FALSE),
(14, 'Pattern Recognition and Machine Learning', 'Christopher Bishop', '9780387310732', '1st', 'Springer', 2006, TRUE, 114, TRUE),
(15, 'Deep Learning', 'Ian Goodfellow', '9780262035613', '1st', 'MIT Press', 2016, FALSE, 115, TRUE),
(16, 'Computer Vision: Algorithms and Applications', 'Richard Szeliski', '9781848829343', '1st', 'Springer', 2010, TRUE, 116, FALSE),
(17, 'Data Mining: Concepts and Techniques', 'Jiawei Han', '9780123814791', '3rd', 'Morgan Kaufmann', 2011, FALSE, 117, TRUE),
(18, 'Principles of Compiler Design', 'Alfred V. Aho', '9780201100884', '1st', 'Addison-Wesley', 1977, TRUE, 118, TRUE),
(19, 'Computer Organization and Design', 'David A. Patterson', '9780124077263', '5th', 'Morgan Kaufmann', 2013, FALSE, 119, FALSE),
(20, 'Digital Design and Computer Architecture', 'David Harris', '9780123944245', '2nd', 'Morgan Kaufmann', 2012, TRUE, 120, TRUE);

-- Insert 20 entries into the User table
INSERT INTO User (user_id, name, role, contact_details, email_notification) VALUES
(1, 'Alice Johnson', 'Student', 'alice.johnson@example.com', TRUE),
(2, 'Bob Smith', 'Professor', 'bob.smith@example.com', FALSE),
(3, 'Charlie Lee', 'Researcher', 'charlie.lee@example.com', TRUE),
(4, 'Daisy Chen', 'Student', 'daisy.chen@example.com', TRUE),
(5, 'Edward Kim', 'Faculty', 'edward.kim@example.com', FALSE),
(6, 'Fiona White', 'Student', 'fiona.white@example.com', TRUE),
(7, 'George Martin', 'Professor', 'george.martin@example.com', FALSE),
(8, 'Hannah Brown', 'Researcher', 'hannah.brown@example.com', TRUE),
(9, 'Ian Green', 'Student', 'ian.green@example.com', TRUE),
(10, 'Jack Black', 'Librarian', 'jack.black@example.com', FALSE),
(11, 'Karen Lopez', 'Faculty', 'karen.lopez@example.com', TRUE),
(12, 'Liam Clark', 'Researcher', 'liam.clark@example.com', FALSE),
(13, 'Mia Lewis', 'Student', 'mia.lewis@example.com', TRUE),
(14, 'Nina Wilson', 'Professor', 'nina.wilson@example.com', TRUE),
(15, 'Oscar Brown', 'Student', 'oscar.brown@example.com', FALSE),
(16, 'Paul Adams', 'Faculty', 'paul.adams@example.com', TRUE),
(17, 'Quincy Hall', 'Researcher', 'quincy.hall@example.com', FALSE),
(18, 'Rachel Evans', 'Student', 'rachel.evans@example.com', TRUE),
(19, 'Steve Price', 'Faculty', 'steve.price@example.com', TRUE),
(20, 'Tina Turner', 'Professor', 'tina.turner@example.com', FALSE);

-- Insert 20 entries into the Library table
INSERT INTO Library (library_id, library_name, location, is_dept_library, is_central_library, plagiarism_check) VALUES
(1, 'Main Library', 'Central Campus', FALSE, TRUE, TRUE),
(2, 'Engineering Library', 'Engineering Building', TRUE, FALSE, FALSE),
(3, 'Medical Library', 'Health Sciences Center', TRUE, FALSE, TRUE),
(4, 'Law Library', 'Law School', TRUE, FALSE, FALSE),
(5, 'Business Library', 'Business School', TRUE, FALSE, TRUE),
(6, 'Science Library', 'Science Building', TRUE, FALSE, FALSE),
(7, 'Fine Arts Library', 'Arts Building', TRUE, FALSE, FALSE),
(8, 'Social Sciences Library', 'Social Sciences Building', TRUE, FALSE, TRUE),
(9, 'Graduate Library', 'Graduate Studies Center', FALSE, FALSE, FALSE),
(10, 'Education Library', 'Education Building', TRUE, FALSE, TRUE),
(11, 'Mathematics Library', 'Math Building', TRUE, FALSE, FALSE),
(12, 'Architecture Library', 'Architecture Building', TRUE, FALSE, TRUE),
(13, 'History Library', 'History Building', TRUE, FALSE, FALSE),
(14, 'Philosophy Library', 'Philosophy Building', TRUE, FALSE, FALSE),
(15, 'Physics Library', 'Physics Department', TRUE, FALSE, TRUE),
(16, 'Biology Library', 'Biology Department', TRUE, FALSE, FALSE),
(17, 'Chemistry Library', 'Chemistry Department', TRUE, FALSE, FALSE),
(18, 'Literature Library', 'Literature Department', TRUE, FALSE, TRUE),
(19, 'Economics Library', 'Economics Department', TRUE, FALSE, FALSE),
(20, 'Environmental Studies Library', 'Environmental Studies Building', TRUE, FALSE, TRUE);

-- Insert 20 entries into the Transaction table
INSERT INTO Transaction (transaction_id, book_id, user_id, item_type, date_borrowed, return_date, damage_fine, late_fees) VALUES
(1, 1, 2, 'Book', '2024-01-05', '2024-01-19', 0.00, 0.00),
(2, 2, 1, 'Book', '2024-01-15', '2024-01-29', 0.00, 0.00),
(3, 3, 4, 'Book', '2024-02-05', '2024-02-19', 0.00, 60.00),
(4, 4, 3, 'Book', '2024-02-15', '2024-03-01', 0.00, 0.00),
(5, 5, 5, 'Book', '2024-03-01', '2024-03-15', 0.00, 120.00),
(6, 6, 6, 'Book', '2024-03-10', '2024-03-24', 10.00, 0.00),
(7, 7, 7, 'Book', '2024-04-01', '2024-04-15', 0.00, 180.00),
(8, 8, 8, 'Book', '2024-04-12', '2024-04-26', 0.00, 0.00),
(9, 9, 9, 'Book', '2024-05-05', '2024-05-19', 0.00, 0.00),
(10, 10, 10, 'Book', '2024-05-10', '2024-05-24', 15.00, 0.00),
(11, 11, 11, 'Book', '2024-06-01', '2024-06-15', 0.00, 240.00),
(12, 12, 12, 'Book', '2024-06-15', '2024-06-29', 0.00, 0.00),
(13, 13, 13, 'Book', '2024-07-05', '2024-07-19', 5.00, 60.00),
(14, 14, 14, 'Book', '2024-07-10', '2024-07-24', 0.00, 0.00),
(15, 15, 15, 'Book', '2024-08-01', '2024-08-15', 0.00, 0.00),
(16, 16, 16, 'Book', '2024-08-05', '2024-08-19', 0.00, 0.00),
(17, 17, 17, 'Book', '2024-09-01', '2024-09-15', 0.00, 300.00),
(18, 18, 18, 'Book', '2024-09-10', '2024-09-24', 0.00, 0.00),
(19, 19, 19, 'Book', '2024-10-05', '2024-10-19', 0.00, 0.00),
(20, 20, 20, 'Book', '2024-10-15', '2024-10-29', 0.00, 360.00);

-- Insert 20 entries into the Fine_Payment table
INSERT INTO Fine_Payment (payment_id, transaction_id, fine_amount, payment_date) VALUES
(1, 1, 0.00, '2024-01-20'),
(2, 3, 60.00, '2024-02-20'),
(3, 5, 120.00, '2024-03-16'),
(4, 6, 10.00, '2024-03-25'),
(5, 7, 180.00, '2024-04-16'),
(6, 10, 15.00, '2024-05-25'),
(7, 11, 240.00, '2024-06-16'),
(8, 13, 65.00, '2024-07-20'),
(9, 17, 300.00, '2024-09-16'),
(10, 20, 360.00, '2024-10-30'),
(11, 2, 0.00, '2024-01-30'),
(12, 4, 0.00, '2024-03-02'),
(13, 8, 0.00, '2024-04-27'),
(14, 9, 0.00, '2024-05-20'),
(15, 12, 0.00, '2024-06-30'),
(16, 14, 0.00, '2024-07-25'),
(17, 15, 0.00, '2024-08-16'),
(18, 16, 0.00, '2024-08-20'),
(19, 18, 0.00, '2024-09-25'),
(20, 19, 0.00, '2024-10-20');

-- Insert 20 entries into the Notification table
INSERT INTO Notification (notification_id, user_id, notification_type, notification_date) VALUES
(1, 1, 'Overdue Fine Reminder', '2024-01-20'),
(2, 3, 'Damage Fine Imposed', '2024-02-21'),
(3, 5, 'Late Fee Reminder', '2024-03-16'),
(4, 6, 'Fine Payment Confirmation', '2024-03-25'),
(5, 7, 'Overdue Fine Reminder', '2024-04-16'),
(6, 10, 'Damage Fine Imposed', '2024-05-25'),
(7, 11, 'Late Fee Reminder', '2024-06-16'),
(8, 13, 'Fine Payment Confirmation', '2024-07-20'),
(9, 17, 'Overdue Fine Reminder', '2024-09-16'),
(10, 20, 'Fine Payment Confirmation', '2024-10-30'),
(11, 2, 'Fine Cleared', '2024-01-31'),
(12, 4, 'Fine Cleared', '2024-03-02'),
(13, 8, 'Fine Cleared', '2024-04-27'),
(14, 9, 'Fine Cleared', '2024-05-20'),
(15, 12, 'Fine Cleared', '2024-06-30'),
(16, 14, 'Fine Cleared', '2024-07-25'),
(17, 15, 'Overdue Fine Reminder', '2024-08-16'),
(18, 16, 'Overdue Fine Reminder', '2024-08-20'),
(19, 18, 'Overdue Fine Reminder', '2024-09-25'),
(20, 19, 'Overdue Fine Reminder', '2024-10-20');

-- Insert 20 entries into the research_paper table
INSERT INTO research_paper (paper_id, title, author, publisher, publication_year, publication_frequency, is_digital, subscription_status, library_id) VALUES
(1, 'Advances in Machine Learning', 'John Doe', 'Springer', 2021, 'Annually', TRUE, 'Active', 1),
(2, 'Quantum Computing Fundamentals', 'Alice Johnson', 'IEEE', 2022, 'Quarterly', FALSE, 'Expired', 2),
(3, 'Neuroscience and AI', 'Robert Green', 'Elsevier', 2020, 'Monthly', TRUE, 'Active', 3),
(4, 'Climate Change Impacts', 'Mary White', 'Nature Publishing', 2019, 'Annually', FALSE, 'Expired', 4),
(5, 'Robotics and Automation', 'James Lee', 'MIT Press', 2021, 'Quarterly', TRUE, 'Active', 5),
(6, 'Economic Theory and Practice', 'Nina Brown', 'Oxford University Press', 2022, 'Annually', FALSE, 'Active', 6),
(7, 'Modern Genetics', 'Emily Clark', 'Cambridge University Press', 2018, 'Quarterly', TRUE, 'Expired', 7),
(8, 'Renewable Energy Systems', 'Oliver Black', 'Springer', 2020, 'Monthly', TRUE, 'Active', 8),
(9, 'Biomedical Engineering Today', 'Liam Smith', 'Elsevier', 2021, 'Annually', FALSE, 'Expired', 9),
(10, 'Social Psychology Studies', 'Emma Davis', 'Wiley', 2020, 'Quarterly', TRUE, 'Active', 10),
(11, 'Artificial Intelligence Ethics', 'Mia Garcia', 'MIT Press', 2021, 'Monthly', FALSE, 'Active', 11),
(12, 'Astrophysics Insights', 'Jack Miller', 'Springer', 2019, 'Annually', TRUE, 'Expired', 12),
(13, 'Big Data and Analytics', 'Grace Wilson', 'IEEE', 2020, 'Quarterly', TRUE, 'Active', 13),
(14, 'Human-Computer Interaction', 'Lucas Brown', 'Elsevier', 2022, 'Monthly', FALSE, 'Expired', 14),
(15, 'Philosophy of Science', 'Sophia Moore', 'Oxford University Press', 2020, 'Annually', TRUE, 'Active', 15),
(16, 'Urban Planning Today', 'Ethan Harris', 'Cambridge University Press', 2021, 'Quarterly', FALSE, 'Expired', 16),
(17, 'Data Security Advances', 'Amelia Clark', 'IEEE', 2022, 'Monthly', TRUE, 'Active', 17),
(18, 'Behavioral Economics', 'Ben Perez', 'Harvard University Press', 2018, 'Annually', FALSE, 'Expired', 18),
(19, 'Agricultural Science Innovations', 'Charlotte Reed', 'Springer', 2020, 'Quarterly', TRUE, 'Active', 19),
(20, 'Cognitive Neuroscience', 'Henry Lee', 'Elsevier', 2021, 'Monthly', FALSE, 'Expired', 20);

-- Insert 20 entries into the staff table
INSERT INTO staff (staff_id, name, role, contact_details, salary, library_id) VALUES
(1, 'Sarah Collins', 'Librarian', 'sarah.collins@example.com', 45000.00, 1),
(2, 'Tom Harris', 'Assistant', 'tom.harris@example.com', 32000.00, 2),
(3, 'Lucy Fisher', 'Manager', 'lucy.fisher@example.com', 55000.00, 3),
(4, 'Max Roberts', 'Maintenance', 'max.roberts@example.com', 28000.00, 4),
(5, 'Linda Walker', 'Librarian', 'linda.walker@example.com', 47000.00, 5),
(6, 'Chris Johnson', 'Assistant', 'chris.johnson@example.com', 33000.00, 6),
(7, 'Angela Smith', 'Manager', 'angela.smith@example.com', 56000.00, 7),
(8, 'John Baker', 'Maintenance', 'john.baker@example.com', 29000.00, 8),
(9, 'Emily Young', 'Librarian', 'emily.young@example.com', 46000.00, 9),
(10, 'Dylan Hill', 'Assistant', 'dylan.hill@example.com', 31000.00, 10),
(11, 'Chloe Taylor', 'Manager', 'chloe.taylor@example.com', 58000.00, 11),
(12, 'Jason King', 'Maintenance', 'jason.king@example.com', 27500.00, 12),
(13, 'Megan Wright', 'Librarian', 'megan.wright@example.com', 48000.00, 13),
(14, 'Nathan Scott', 'Assistant', 'nathan.scott@example.com', 34000.00, 14),
(15, 'Olivia Evans', 'Manager', 'olivia.evans@example.com', 59000.00, 15),
(16, 'Oscar Turner', 'Maintenance', 'oscar.turner@example.com', 28500.00, 16),
(17, 'Sophia Morgan', 'Librarian', 'sophia.morgan@example.com', 49500.00, 17),
(18, 'Liam Bell', 'Assistant', 'liam.bell@example.com', 35000.00, 18),
(19, 'Grace Allen', 'Manager', 'grace.allen@example.com', 60000.00, 19),
(20, 'Evan Mitchell', 'Maintenance', 'evan.mitchell@example.com', 29000.00, 20);

-- Insert 20 entries into the acquisition table
INSERT INTO acquisition (acquisition_id, item_type, item_id, acquisition_date, supplier_name, staff_id, library_id) VALUES
(1, 'Book', 1, '2024-01-05', 'Global Books Ltd.', 1, 1),
(2, 'Research Paper', 3, '2024-01-15', 'Science Publications Inc.', 2, 2),
(3, 'Journal', 5, '2024-01-25', 'Academic Journals Co.', 3, 3),
(4, 'Magazine', 7, '2024-02-05', 'Periodicals International', 4, 4),
(5, 'Book', 9, '2024-02-15', 'World Books', 5, 5),
(6, 'Research Paper', 11, '2024-02-25', 'Tech Press', 6, 6),
(7, 'Journal', 13, '2024-03-05', 'Global Journals', 7, 7),
(8, 'Magazine', 15, '2024-03-15', 'Print House Ltd.', 8, 8),
(9, 'Book', 17, '2024-03-25', 'University Books', 9, 9),
(10, 'Research Paper', 19, '2024-04-05', 'Research Publishers Inc.', 10, 10),
(11, 'Book', 2, '2024-04-15', 'Scholarly Works', 11, 11),
(12, 'Journal', 4, '2024-04-25', 'Academic Journals Co.', 12, 12),
(13, 'Magazine', 6, '2024-05-05', 'Periodicals International', 13, 13),
(14, 'Research Paper', 8, '2024-05-15', 'Science Publications Inc.', 14, 14),
(15, 'Book', 10, '2024-05-25', 'Global Books Ltd.', 15, 15),
(16, 'Journal', 12, '2024-06-05', 'Journal Publishers', 16, 16),
(17, 'Magazine', 14, '2024-06-15', 'Magazine Distributors', 17, 17),
(18, 'Book', 16, '2024-06-25', 'Literary World', 18, 18),
(19, 'Research Paper', 18, '2024-07-05', 'Tech Research Group', 19, 19),
(20, 'Journal', 20, '2024-07-15', 'Monthly Insights Ltd.', 20, 20);

SELECT * FROM Book;
SELECT * FROM User;
SELECT * FROM library;
SELECT * FROM Transaction;
SELECT * FROM Fine_Payment;
SELECT * FROM Notification;
SELECT * FROM research_paper;
SELECT * FROM staff;
SELECT * FROM acquisition;

SELECT CalculateLateFee('2024-10-01', '2024-11-01') AS late_fee;
SELECT AvgSalaryByRole('Librarian') AS average_salary;
SELECT isDigitalResearchPaper(1) AS is_digital;
SELECT CheckPlagiarismService(1) AS plagiarism_service_available;


