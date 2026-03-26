--creating Database
CREATE DATABASE LibraryDB;
USE LibraryDB;

--creating tables
--Role Table
CREATE TABLE Role (
    RoleID      INT PRIMARY KEY IDENTITY(1,1),
    RoleName    VARCHAR(50) NOT NULL,
    Description VARCHAR(255)
);
--Person Table
CREATE TABLE Person (
    PersonID    INT PRIMARY KEY IDENTITY(1,1),
    FullName    VARCHAR(100) NOT NULL,
    Email       VARCHAR(150) NOT NULL,
    PersonType  VARCHAR(50)  NOT NULL,   -- e.g. Student, Staff, Lecturer
    RoleID      INT NOT NULL,
    FOREIGN KEY (RoleID) REFERENCES Role(RoleID)
);
--Category Table
CREATE TABLE Category (
    CategoryID   INT PRIMARY KEY IDENTITY(1,1),
    CategoryName VARCHAR(100) NOT NULL,
    TagColour    VARCHAR(50),
    LoanPeriod   INT NOT NULL,           -- in days
    FineRate     DECIMAL(5,2) NOT NULL   -- per day
);
--Publisher Table
CREATE TABLE Publisher (
    PublisherID   INT PRIMARY KEY IDENTITY(1,1),
    PublisherName VARCHAR(150) NOT NULL,
    ContactEmail  VARCHAR(150)
);
--Book Table
CREATE TABLE Book (
    ISBN        VARCHAR(20)  PRIMARY KEY,
    Title       VARCHAR(255) NOT NULL,
    Genre       VARCHAR(100),
    Description VARCHAR(500),
    CategoryID  INT NOT NULL,
    PublisherID INT,
    FOREIGN KEY (CategoryID)  REFERENCES Category(CategoryID),
    FOREIGN KEY (PublisherID) REFERENCES Publisher(PublisherID)
);
--BookCopy Table
CREATE TABLE BookCopy (
    CopyID     INT PRIMARY KEY IDENTITY(1,1),
    ISBN       VARCHAR(20) NOT NULL,
    IsLoanable BIT NOT NULL DEFAULT 1,
    Status     VARCHAR(50) NOT NULL DEFAULT 'Available', -- Available, OnLoan, Reserved
    FOREIGN KEY (ISBN) REFERENCES Book(ISBN)
);
--Author Table
CREATE TABLE Author (
    AuthorID   INT PRIMARY KEY IDENTITY(1,1),
    AuthorName VARCHAR(150) NOT NULL
);
--BookAuthor Table
CREATE TABLE BookAuthor (
    ISBN     VARCHAR(20) NOT NULL,
    AuthorID INT         NOT NULL,
    PRIMARY KEY (ISBN, AuthorID),
    FOREIGN KEY (ISBN)     REFERENCES Book(ISBN),
    FOREIGN KEY (AuthorID) REFERENCES Author(AuthorID)
);
--Loan Table
CREATE TABLE Loan (
    LoanID     INT PRIMARY KEY IDENTITY(1,1),
    PersonID   INT         NOT NULL,
    CopyID     INT         NOT NULL,
    ISBN       VARCHAR(20) NOT NULL,
    LoanDate   DATE        NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ReturnDate DATE        NULL,     -- NULL = not yet returned
    FOREIGN KEY (PersonID) REFERENCES Person(PersonID),
    FOREIGN KEY (CopyID)   REFERENCES BookCopy(CopyID),
    FOREIGN KEY (ISBN)     REFERENCES Book(ISBN)
);
--Fine Table
CREATE TABLE Fine (
    FineID        INT PRIMARY KEY IDENTITY(1,1),
    LoanID        INT           NOT NULL,
    Amount        DECIMAL(8,2)  NOT NULL,
    DateIssued    DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    PaymentStatus VARCHAR(20)   NOT NULL DEFAULT 'Unpaid', -- Unpaid, Paid
    FOREIGN KEY (LoanID) REFERENCES Loan(LoanID)
);
--Reservation Table
CREATE TABLE Reservation (
    ReservationID   INT PRIMARY KEY IDENTITY(1,1),
    PersonID        INT         NOT NULL,
    CopyID          INT         NOT NULL,
    ISBN            VARCHAR(20) NOT NULL,
    ReservationDate DATE        NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Status          VARCHAR(20) NOT NULL DEFAULT 'Active', -- Active, Expired, Fulfilled
    FOREIGN KEY (PersonID) REFERENCES Person(PersonID),
    FOREIGN KEY (CopyID)   REFERENCES BookCopy(CopyID)
);
--Room Table
CREATE TABLE Room (
    RoomID    INT PRIMARY KEY IDENTITY(1,1),
    RoomName  VARCHAR(100) NOT NULL,
    Capacity  INT,
    Location  VARCHAR(150)
);
--RoomBooking Table
CREATE TABLE RoomBooking (
    BookingID     INT PRIMARY KEY IDENTITY(1,1),
    RoomID        INT  NOT NULL,
    PersonID      INT  NOT NULL,
    BookingDate   DATE NOT NULL,
    DurationHours INT  NOT NULL DEFAULT 1,
    FOREIGN KEY (RoomID)   REFERENCES Room(RoomID),
    FOREIGN KEY (PersonID) REFERENCES Person(PersonID)
);
--DeletedPersonalLog Table
CREATE TABLE DeletedPersonLog (
    LogID       INT PRIMARY KEY IDENTITY(1,1),
    PersonID    INT          NOT NULL,
    DeletedAt   DATETIME     NOT NULL DEFAULT GETDATE()
);
--Inserting Sample Data
--Roles
INSERT INTO Role (RoleName, Description) VALUES
('Student',   'University student member'),
('Staff',     'University staff member'),
('Librarian', 'Library administration staff'),
('Lecturer',  'University academic lecturer');
-- Persons
INSERT INTO Person (FullName, Email, PersonType, RoleID) VALUES
('Nishan Tamang',   'nishan.tamang@university.edu',   'Student',  1),
('Sabal Shahi',     'sabal.shahi@university.edu',     'Student',  1),
('Harish Singh Air','harish.air@university.edu',      'Student',  1),
('Nirjala Thapa',   'nirjala.thapa@university.edu',   'Student',  1),
('Dr. Raman Kafle', 'raman.kafle@university.edu',     'Lecturer', 4),
('Sita Lama',       'sita.lama@university.edu',       'Staff',    2),
('Mohan Bista',     'mohan.bista@university.edu',     'Librarian',3);
-- Categories
INSERT INTO Category (CategoryName, TagColour, LoanPeriod, FineRate) VALUES
('Programming',  'Green',  14, 0.50),
('Networking',   'Blue',   14, 0.50),
('Reference',    'Red',     3, 2.00),
('Literature',   'Yellow', 21, 0.25),
('Mathematics',  'Green',  14, 0.50);
INSERT INTO Publisher (PublisherName, ContactEmail) VALUES
('Pearson Education',    'contact@pearson.com'),
('John Wiley & Sons',    'info@wiley.com'),
('OReilly Media',      'books@oreilly.com'),
('Springer Nature',      'info@springer.com'),
('McGraw Hill',          'support@mcgrawhill.com');
-- Books
INSERT INTO Book (ISBN, Title, Genre, Description, CategoryID, PublisherID) VALUES
('978-0132350884', 'Clean Code',                     'Software Engineering', 'A handbook of agile software craftsmanship.',           1, 1),
('978-0201633610', 'Design Patterns',                'Software Engineering', 'Elements of reusable object-oriented software.',        1, 1),
('978-0596517748', 'JavaScript: The Good Parts',     'Programming',          'Unearthing the excellence in JavaScript.',              1, 3),
('978-0132546201', 'Computer Networks',              'Networking',           'A top-down approach to networking.',                    2, 1),
('978-0471117094', 'Database System Concepts',       'Databases',            'Comprehensive introduction to database systems.',       1, 2),
('978-0387952451', 'Introduction to Algorithms',     'Computer Science',     'Classic algorithms reference.',                         5, 4),
('978-0062316097', 'To Kill a Mockingbird',          'Classic Fiction',      'A novel by Harper Lee.',                               4, 5),
('978-0385737951', 'The Hunger Games',               'Fiction',              'A dystopian novel by Suzanne Collins.',                 4, 5),
('978-0134685991', 'Effective Java',                 'Programming',          'Best practices for the Java platform.',                 1, 1),
('978-1491950357', 'Python Data Science Handbook',   'Data Science',         'Essential tools for working with data.',                1, 3);
INSERT INTO BookCopy (ISBN, IsLoanable, Status) VALUES
('978-0132350884', 1, 'Available'),
('978-0132350884', 1, 'OnLoan'),
('978-0201633610', 1, 'Available'),
('978-0596517748', 1, 'Available'),
('978-0132546201', 1, 'OnLoan'),
('978-0471117094', 1, 'Available'),
('978-0062316097', 1, 'Available'),
('978-0385737951', 1, 'Available'),
('978-0134685991', 1, 'OnLoan'),
('978-1491950357', 1, 'Available');
-- Authors
INSERT INTO Author (AuthorName) VALUES
('Robert C. Martin'),
('Erich Gamma'),
('Douglas Crockford'),
('Andrew S. Tanenbaum'),
('Abraham Silberschatz'),
('Thomas H. Cormen'),
('Harper Lee'),
('Suzanne Collins'),
('Joshua Bloch'),
('Jake VanderPlas');
-- BookAuthor
INSERT INTO BookAuthor (ISBN, AuthorID) VALUES
('978-0132350884', 1),
('978-0201633610', 2),
('978-0596517748', 3),
('978-0132546201', 4),
('978-0471117094', 5),
('978-0385737952', 6),
('978-0062316097', 7),
('978-0385737951', 8),
('978-0134685991', 9),
('978-1491950357', 10);
-- Loans
INSERT INTO Loan (PersonID, CopyID, ISBN, LoanDate, ReturnDate) VALUES
(1, 2,  '978-0132350884', '2025-03-01', NULL),
(2, 5,  '978-0132546201', '2025-03-05', '2025-03-19'),
(3, 9,  '978-0134685991', '2025-03-10', NULL),
(4, 1,  '978-0132350884', '2025-02-20', '2025-03-05'),
(5, 3,  '978-0201633610', '2025-03-12', NULL);
-- Fines
INSERT INTO Fine (LoanID, Amount, DateIssued, PaymentStatus) VALUES
(2, 3.50, '2025-03-22', 'Paid'),
(4, 1.00, '2025-03-08', 'Paid');
-- Reservations
INSERT INTO Reservation (PersonID, CopyID, ISBN, ReservationDate, Status) VALUES
(1, 5,  '978-0132546201', '2025-03-20', 'Active'),
(2, 9,  '978-0134685991', '2025-03-15', 'Active'),
(3, 2,  '978-0132350884', '2025-03-01', 'Fulfilled'),
(4, 4,  '978-0596517748', '2025-03-18', 'Active');
-- Rooms
INSERT INTO Room (RoomName, Capacity, Location) VALUES
('Presentation Room A', 20, 'Ground Floor'),
('Presentation Room B', 15, 'First Floor'),
('Study Room 1',        10, 'Second Floor'),
('Conference Hall',     50, 'Basement');
-- RoomBookings
INSERT INTO RoomBooking (RoomID, PersonID, BookingDate, DurationHours) VALUES
(1, 1, '2025-03-15', 2),
(1, 2, '2025-03-16', 1),
(2, 3, '2025-03-15', 3),
(3, 4, '2025-03-17', 2),
(1, 5, '2025-03-18', 1),
(4, 6, '2025-04-01', 4);

