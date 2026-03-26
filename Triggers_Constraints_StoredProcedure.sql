 -- Constraint 1 (Harish Singh Air NP069458)
-- Ensure the ISBN in the Loan table exists in the Book table
-- (enforced via FK; add an explicit named constraint for clarity)
ALTER TABLE Loan
    ADD CONSTRAINT FK_Loan_Book
    FOREIGN KEY (ISBN) REFERENCES Book(ISBN);
GO
 
-- Constraint 2 (Nirjala Thapa NP069469)
-- Unique Email for each Person
ALTER TABLE Person
    ADD CONSTRAINT UQ_Person_Email UNIQUE (Email);
GO
 
-- Constraint 3 (Nishan Tamang NP069470)
-- Loan ReturnDate cannot be earlier than LoanDate
ALTER TABLE Loan
    ADD CONSTRAINT CHK_Loan_ReturnDate
    CHECK (ReturnDate IS NULL OR ReturnDate >= LoanDate);
GO
 
-- Stored Procedure 1 (Harish Singh Air NP069458)
-- Issue a Loan
CREATE PROCEDURE sp_IssueLoan
    @PersonID   INT,
    @CopyID     INT,
    @ISBN       VARCHAR(20),
    @LoanDate   DATE = NULL,
    @ReturnDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Default loan date to today if not provided
    IF @LoanDate IS NULL
        SET @LoanDate = CAST(GETDATE() AS DATE);
 
    -- Insert the loan record
    INSERT INTO Loan (PersonID, CopyID, ISBN, LoanDate, ReturnDate)
    VALUES (@PersonID, @CopyID, @ISBN, @LoanDate, @ReturnDate);
 
    -- Update book copy status to OnLoan
    UPDATE BookCopy
    SET Status = 'OnLoan'
    WHERE CopyID = @CopyID;
 
    PRINT 'Loan issued successfully for PersonID ' + CAST(@PersonID AS VARCHAR) +
          ', CopyID ' + CAST(@CopyID AS VARCHAR);
END;
GO
 
-- Stored Procedure 2 (Nirjala Thapa NP069469)
-- Register a New Person
CREATE PROCEDURE sp_RegisterPerson
    @FullName   VARCHAR(100),
    @Email      VARCHAR(150),
    @PersonType VARCHAR(50),
    @RoleID     INT
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM Person WHERE Email = @Email)
    BEGIN
        PRINT 'Error: A person with this email already exists.';
        RETURN;
    END
 
    -- Insert the new person
    INSERT INTO Person (FullName, Email, PersonType, RoleID)
    VALUES (@FullName, @Email, @PersonType, @RoleID);
 
    PRINT 'New person registered successfully: ' + @FullName;
END;
GO
 
-- Stored Procedure 3 (Nishan Tamang NP069470)
-- Get Active Reservations
CREATE PROCEDURE sp_GetActiveReservations
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT
        r.ReservationID,
        p.FullName        AS PersonName,
        p.Email,
        b.Title           AS BookTitle,
        b.ISBN,
        r.ReservationDate,
        r.Status
    FROM Reservation r
    INNER JOIN Person   p  ON r.PersonID = p.PersonID
    INNER JOIN BookCopy bc ON r.CopyID   = bc.CopyID
    INNER JOIN Book     b  ON bc.ISBN    = b.ISBN
    WHERE r.Status = 'Active'
    ORDER BY r.ReservationDate;
END;
GO
 
-- Trigger 1 (Harish Singh Air NP069458)
-- Auto-update Reservation Status to 'Fulfilled' when a Loan is made
CREATE TRIGGER trg_FulfillReservationOnLoan
ON Loan
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
 
    -- When a new loan is inserted, mark the matching active reservation as Fulfilled
    UPDATE Reservation
    SET Status = 'Fulfilled'
    WHERE Status = 'Active'
      AND PersonID = (SELECT PersonID FROM inserted)
      AND ISBN     = (SELECT ISBN     FROM inserted);
END;
GO
 
-- Trigger 2 (Nirjala Thapa NP069469)
-- Prevent Duplicate Active Reservation for the same person and book
CREATE TRIGGER trg_PreventDuplicateReservation
ON Reservation
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Check whether an active reservation already exists for this person + ISBN
    IF EXISTS (
        SELECT 1
        FROM Reservation r
        INNER JOIN inserted i ON r.PersonID = i.PersonID
                              AND r.ISBN    = i.ISBN
        WHERE r.Status = 'Active'
    )
    BEGIN
        PRINT 'Error: An active reservation already exists for this person and book.';
        RETURN;
    END
 
    -- No duplicate found — proceed with the insert
    INSERT INTO Reservation (PersonID, CopyID, ISBN, ReservationDate, Status)
    SELECT PersonID, CopyID, ISBN, ReservationDate, Status
    FROM inserted;
END;
GO
 
 
-- Optimization 1 (Harish Singh Air NP069458)
-- Indexing the Book Table on Title and CategoryID
CREATE INDEX IX_Book_Title      ON Book (Title);
CREATE INDEX IX_Book_CategoryID ON Book (CategoryID);
GO
 
-- Optimization 2 (Nirjala Thapa NP069469)
-- View for Frequently Accessed Reservation Data (simulates a materialized view)
CREATE VIEW vw_ActiveReservationDetails
AS
    SELECT
        r.ReservationID,
        p.FullName        AS PersonName,
        p.Email,
        b.Title           AS BookTitle,
        b.ISBN,
        bc.CopyID,
        r.ReservationDate,
        r.Status
    FROM Reservation r
    INNER JOIN Person   p  ON r.PersonID = p.PersonID
    INNER JOIN BookCopy bc ON r.CopyID   = bc.CopyID
    INNER JOIN Book     b  ON bc.ISBN    = b.ISBN
    WHERE r.Status = 'Active';
GO
 
-- Create an index on the view to simulate a materialized view

-- Optimization 3 (Nishan Tamang NP069470)
-- Table Partitioning on RoomBooking by BookingDate year
-- Step 1: Create a partition function for years
CREATE PARTITION FUNCTION pf_RoomBookingYear (DATE)
AS RANGE RIGHT FOR VALUES ('2024-01-01', '2025-01-01', '2026-01-01');
GO
 
-- Step 2: Create a partition scheme
CREATE PARTITION SCHEME ps_RoomBookingYear
AS PARTITION pf_RoomBookingYear
ALL TO ([PRIMARY]);
GO
 
-- Note: To apply this partition to the RoomBooking table,
-- recreate the table on the partition scheme (shown below as a reference).
-- In production, partition the table during initial creation:
--
-- CREATE TABLE RoomBooking (
--     BookingID     INT  PRIMARY KEY IDENTITY(1,1),
--     RoomID        INT  NOT NULL,
--     PersonID      INT  NOT NULL,
--     BookingDate   DATE NOT NULL,
--     DurationHours INT  NOT NULL DEFAULT 1,
--     FOREIGN KEY (RoomID)   REFERENCES Room(RoomID),
--     FOREIGN KEY (PersonID) REFERENCES Person(PersonID)
-- ) ON ps_RoomBookingYear(BookingDate);
GO
 
-- ============================================================
-- SECTION 8: SQL QUERIES
-- ============================================================
 
-- ---- Student 1: Harish Singh Air (NP069458) ----
 
-- Q1: Category with the highest number of books
SELECT TOP 1
    c.CategoryName,
    COUNT(b.ISBN) AS TotalBooks
FROM Category c
JOIN Book b ON c.CategoryID = b.CategoryID
GROUP BY c.CategoryName
ORDER BY TotalBooks DESC;
GO
 
-- Q2: Books that were never loaned
SELECT b.ISBN, b.Title
FROM Book b
LEFT JOIN BookCopy bc ON b.ISBN    = bc.ISBN
LEFT JOIN Loan     l  ON bc.CopyID = l.CopyID
WHERE l.LoanID IS NULL;
GO
 
-- Q3: People with more than 1 loan
SELECT
    p.PersonID,
    p.FullName,
    COUNT(l.LoanID) AS TotalLoans
FROM Person p
JOIN Loan l ON p.PersonID = l.PersonID
GROUP BY p.PersonID, p.FullName
HAVING COUNT(l.LoanID) > 1;
GO
 
-- Q4: Category and genre-wise total books (with ROLLUP)
SELECT
    c.CategoryName,
    b.Genre,
    COUNT(b.ISBN) AS TotalBooks
FROM Category c
JOIN Book b ON c.CategoryID = b.CategoryID
GROUP BY ROLLUP (c.CategoryName, b.Genre);
GO
 
-- Q5: Most reserved book
SELECT TOP 1
    b.Title,
    b.ISBN,
    COUNT(r.ReservationID) AS TotalReservations
FROM Reservation r
JOIN BookCopy bc ON r.CopyID = bc.CopyID
JOIN Book     b  ON bc.ISBN  = b.ISBN
GROUP BY b.Title, b.ISBN
ORDER BY TotalReservations DESC;
GO
 
-- ---- Student 2: Nirjala Thapa (NP069469) ----
 
-- Q1: Presentation room with the most bookings
SELECT TOP 1
    rm.RoomName,
    COUNT(rb.BookingID) AS TotalBookings
FROM Room rm
JOIN RoomBooking rb ON rm.RoomID = rb.RoomID
GROUP BY rm.RoomName
ORDER BY TotalBookings DESC;
GO
 
-- Q2: People with no loans
SELECT p.PersonID, p.FullName, p.Email
FROM Person p
LEFT JOIN Loan l ON p.PersonID = l.PersonID
WHERE l.LoanID IS NULL;
GO
 
-- Q3: Person who paid the highest total fine
SELECT TOP 1
    p.FullName,
    SUM(f.Amount) AS TotalFinePaid
FROM Person p
JOIN Loan l ON p.PersonID = l.PersonID
JOIN Fine f ON l.LoanID   = f.LoanID
WHERE f.PaymentStatus = 'Paid'
GROUP BY p.PersonID, p.FullName
ORDER BY TotalFinePaid DESC;
GO
 
-- Q4: Loan fine by person type (with ROLLUP)
SELECT
    p.PersonType,
    SUM(f.Amount)   AS TotalFines,
    COUNT(f.FineID) AS FineCount
FROM Person p
JOIN Loan l ON p.PersonID = l.PersonID
JOIN Fine f ON l.LoanID   = f.LoanID
GROUP BY ROLLUP (p.PersonType);
GO
 
-- Q5: Rooms with zero bookings
SELECT rm.RoomID, rm.RoomName, rm.Location
FROM Room rm
LEFT JOIN RoomBooking rb ON rm.RoomID = rb.RoomID
WHERE rb.BookingID IS NULL;
GO
 
-- ---- Student 3: Nishan Tamang (NP069470) ----
 
-- Q1: Person with the highest number of loans
SELECT TOP 1
    p.FullName,
    COUNT(l.LoanID) AS TotalLoans
FROM Person p
JOIN Loan l ON p.PersonID = l.PersonID
GROUP BY p.PersonID, p.FullName
ORDER BY TotalLoans DESC;
GO
 
-- Q2: Most frequently loaned books (top 3)
SELECT TOP 3
    b.Title,
    b.ISBN,
    COUNT(l.LoanID) AS LoanCount
FROM Loan     l
JOIN BookCopy bc ON l.CopyID = bc.CopyID
JOIN Book     b  ON bc.ISBN  = b.ISBN
GROUP BY b.Title, b.ISBN
ORDER BY LoanCount DESC;
GO
 
-- Q3: Books with more than zero (at least 1) author
SELECT
    b.Title,
    b.ISBN,
    COUNT(ba.AuthorID) AS AuthorCount
FROM Book     b
JOIN BookAuthor ba ON b.ISBN = ba.ISBN
GROUP BY b.Title, b.ISBN
HAVING COUNT(ba.AuthorID) > 0;
GO
 
-- Q4: Active and inactive borrowers by person type
SELECT
    p.PersonType,
    COUNT(DISTINCT CASE WHEN l.LoanID IS NOT NULL THEN p.PersonID END) AS ActiveBorrowers,
    COUNT(DISTINCT CASE WHEN l.LoanID IS NULL     THEN p.PersonID END) AS InactiveBorrowers
FROM Person p
LEFT JOIN Loan l ON p.PersonID = l.PersonID
GROUP BY p.PersonType;
GO
 
-- Q5: Most overdue book (not yet returned, longest outstanding)
SELECT TOP 1
    b.Title,
    b.ISBN,
    l.LoanDate,
    DATEDIFF(DAY, l.LoanDate, GETDATE()) AS DaysOverdue
FROM Loan     l
JOIN BookCopy bc ON l.CopyID = bc.CopyID
JOIN Book     b  ON bc.ISBN  = b.ISBN
WHERE l.ReturnDate IS NULL
ORDER BY DaysOverdue DESC;
GO
 