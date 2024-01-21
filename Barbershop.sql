

-- Drop the existing BarbersDB if it exists
USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BarberShopDB')
BEGIN
    ALTER DATABASE BarberShopDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BarberShopDB;
END;
GO

-- Create the BarbersDB
CREATE DATABASE BarberShopDB;
GO
USE BarberShopDB;
GO

-- Create Barbers Table
CREATE TABLE Barbers (
    BarberID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(255) NOT NULL,
    Gender NVARCHAR(10) NOT NULL,  
    ContactPhone NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    HireDate DATE NOT NULL,
    Position NVARCHAR(50) NOT NULL,
	-- ensures that the values in the Position column must be one of the specified options
    CONSTRAINT CK_Position CHECK (Position IN ('Chief Barber', 'Senior Barber', 'Junior Barber'))
);
GO
-- Create Services Table
CREATE TABLE Services (
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    BarberID INT NOT NULL,
    ServiceName NVARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    Duration INT NOT NULL, -- in minutes
    CONSTRAINT FK_Services_Barbers FOREIGN KEY (BarberID) REFERENCES Barbers(BarberID)
);
GO

-- Create Client Table
CREATE TABLE Clients (
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(255) NOT NULL,
    ContactPhone NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100) NOT NULL
);

GO

-- Create BarberFeedback Table
CREATE TABLE BarberFeedback (
    FeedbackID INT IDENTITY(1,1) PRIMARY KEY,
    BarberID INT NOT NULL,
    ClientID INT NOT NULL,
    Rating NVARCHAR(20) NOT NULL,
    Feedback NVARCHAR(MAX) NOT NULL,
    CONSTRAINT FK_BarberFeedback_Barbers FOREIGN KEY (BarberID) REFERENCES Barbers(BarberID),
    CONSTRAINT FK_BarberFeedback_Clients FOREIGN KEY (ClientID) REFERENCES Clients(ClientID)
);

GO

-- Create Visits Archive Table
CREATE TABLE VisitsArchive (
    VisitID INT IDENTITY(1,1) PRIMARY KEY,
    ClientID INT NOT NULL,
    BarberID INT NOT NULL,
    ServiceID INT NOT NULL,
    VisitDate DATE NOT NULL,
    TotalCost DECIMAL(10, 2) NOT NULL,
    Rating NVARCHAR(20) NOT NULL,
    Feedback NVARCHAR(MAX) NOT NULL,
    CONSTRAINT FK_VisitsArchive_Clients FOREIGN KEY (ClientID) REFERENCES Clients(ClientID),
    CONSTRAINT FK_VisitsArchive_Barbers FOREIGN KEY (BarberID) REFERENCES Barbers(BarberID),
    CONSTRAINT FK_VisitsArchive_Services FOREIGN KEY (ServiceID) REFERENCES Services(ServiceID)
);

GO

-- Create Schedule Table
CREATE TABLE Schedule (
    BarberID INT IDENTITY(1,1) NOT NULL,
    Date DATE NOT NULL,
    TimeSlot NVARCHAR(10) NOT NULL,
    IsAvailable BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_Schedule PRIMARY KEY (BarberID, Date, TimeSlot),
    CONSTRAINT FK_Schedule_Barbers FOREIGN KEY (BarberID) REFERENCES Barbers(BarberID)
);
GO

-- Insert into Barbers Table
INSERT INTO Barbers (FullName, Gender, ContactPhone, Email, BirthDate, HireDate, Position)
VALUES
('John Doe', 'Male', '123-456-7890', 'john.doe@example.com', '1980-01-01', '2020-05-15', 'Chief Barber'),
('Jane Smith', 'Female', '987-654-3210', 'jane.smith@example.com', '1990-03-15', '2021-02-20', 'Senior Barber'),
('Bob Johnson', 'Male', '555-123-4567', 'bob.johnson@example.com', '1985-08-10', '2019-10-30', 'Senior Barber'),
('Alice Brown', 'Female', '777-888-9999', 'alice.brown@example.com', '1995-12-05', '2022-04-25', 'Junior Barber'),
('Chris White', 'Male', '111-222-3333', 'chris.white@example.com', '1988-06-20', '2020-08-12', 'Junior Barber');

GO

-- Insert into Services Table
INSERT INTO Services (BarberID, ServiceName, Price, Duration)
VALUES
(1, 'Haircut', 25.00, 30),
(2, 'Shave', 15.00, 15),
(3, 'Beard Trim', 10.00, 20),
(4, 'Coloring', 40.00, 45),
(5, 'Manicure', 20.00, 25);
GO

-- Insert into Clients Table
INSERT INTO Clients (FullName, ContactPhone, Email)
VALUES
('Mary Johnson', '444-555-6666', 'mary.johnson@example.com'),
('Tom Davis', '666-777-8888', 'tom.davis@example.com'),
('Sara Miller', '999-888-7777', 'sara.miller@example.com'),
('Alex Turner', '111-222-3333', 'alex.turner@example.com'),
('Olivia Brown', '333-444-5555', 'olivia.brown@example.com');
GO

-- Insert into BarberFeedback Table
INSERT INTO BarberFeedback (BarberID, ClientID, Rating, Feedback)
VALUES
(1, 1, 'Excellent', 'Great haircut, very satisfied!'),
(2, 3, 'Good', 'Nice shave but took a bit long.'),
(3, 2, 'Excellent', 'Awesome coloring job!'),
(4, 4, 'Average', 'Decent beard trim, could be better.'),
(5, 5, 'Good', 'Liked the manicure service.');
GO

-- Insert into Schedule Table
INSERT INTO Schedule (Date, TimeSlot)
VALUES
    ('2024-01-21', '09:00 AM'),
    ('2024-01-21', '10:00 AM'),
    ('2024-01-21', '11:00 AM'),
    ('2024-01-21', '01:00 PM'),
    ('2024-01-21', '02:00 PM');
GO

-- Functionality Implementation

-- 1. Return information about all barbers
CREATE FUNCTION GetAllBarbers()
RETURNS TABLE
AS RETURN
    SELECT * FROM Barbers;
GO

-- 2. Return information about barbers who can provide a specific service
CREATE FUNCTION GetBarbersByService(@serviceName NVARCHAR(100))
RETURNS TABLE
AS RETURN
    SELECT * FROM Barbers
    WHERE BarberID IN (SELECT BarberID FROM Services WHERE ServiceName = @serviceName);
GO

-- 3. Return information about barbers who have worked for more than a specified number of years
CREATE FUNCTION GetBarbersByExperience(@yearsOfExperience INT)
RETURNS TABLE
AS RETURN
    SELECT * FROM Barbers
    WHERE DATEDIFF(YEAR, HireDate, GETDATE()) > @yearsOfExperience;
GO

-- 4. Delete records from the archive that are more than one year old
CREATE PROCEDURE DeleteOldVisitsFromArchive
AS
BEGIN
    DELETE FROM VisitsArchive
    WHERE DATEDIFF(YEAR, VisitDate, GETDATE()) > 1;
END;
GO

-- 5. Return the count of Senior Barbers and Junior Barbers
CREATE PROCEDURE GetSeniorJuniorBarberCount
AS
BEGIN
    SELECT
        COUNT(CASE WHEN Position = 'Senior Barber' THEN 1 END) AS SeniorBarberCount,
        COUNT(CASE WHEN Position = 'Junior Barber' THEN 1 END) AS JuniorBarberCount
    FROM Barbers;
END;
GO


-- 6. Return information about regular clients
CREATE PROCEDURE GetRegularClients(@visitCount INT)
AS
BEGIN
    SELECT * FROM Clients
    WHERE ClientID IN (
        SELECT ClientID
        FROM VisitsArchive
        GROUP BY ClientID
        HAVING COUNT(*) >= @visitCount
    );
END;
GO

-- 7. Return information about the longest service in the barbershop
CREATE FUNCTION GetLongestService()
RETURNS TABLE
AS RETURN
    SELECT TOP 1 * FROM Services
    ORDER BY Duration DESC;
GO

-- 8. Show the schedule for a specific barber on a given day
CREATE PROCEDURE GetBarberSchedule(@barberID INT, @date DATE)
AS
BEGIN
    SELECT * FROM Schedule
    WHERE BarberID = @barberID AND Date = @date;
END;
GO

-- 9. Show the top 3 barbers by client rating
CREATE FUNCTION GetTopRatedBarbers()
RETURNS TABLE
AS RETURN
    SELECT TOP 3 Barbers.BarberID, Barbers.FullName, Barbers.Gender, AVG(CONVERT(FLOAT, Feedbacks.Rating)) AS AverageRating
    FROM Barbers
    JOIN BarberFeedback AS Feedbacks ON Barbers.BarberID = Feedbacks.BarberID
    GROUP BY Barbers.BarberID, Barbers.FullName, Barbers.Gender
    ORDER BY AverageRating DESC;
GO


-- 10. Check if a barber is available at a specific date and time
CREATE FUNCTION IsBarberAvailable(@barberID INT, @date DATE, @timeSlot NVARCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @isAvailable BIT = 0; -- Default to not available

    SELECT @isAvailable = 1
    FROM Schedule
    WHERE BarberID = @barberID AND Date = @date AND TimeSlot = @timeSlot
    AND IsAvailable = 1;

    RETURN @isAvailable;
END;

-- Example Queries and Calls to Functions and Procedures

-- 1. Get All Barbers
SELECT * FROM GetAllBarbers;

-- 2. Get Barbers Providing a Specific Service
SELECT * FROM GetBarbersByService('Haircut');

-- 3. Get Barbers with More than X Years of Experience
SELECT * FROM GetBarbersByExperience(3);

-- 4. Delete Old Visits from Archive
EXEC DeleteOldVisitsFromArchive;

-- 5. Get Count of Senior and Junior Barbers
EXEC GetSeniorJuniorBarberCount;

-- 6. Get Regular Clients with at Least X Visits
EXEC GetRegularClients 2;

-- 7. Get Information about the Longest Service
SELECT * FROM GetLongestService;

-- 8. Get Schedule for a Specific Barber on a Given Day
EXEC GetBarberSchedule @barberID = 1, @date = '2024-01-21';

-- 9. Get Top 3 Barbers by Average Rating
SELECT * FROM GetTopRatedBarbers;

-- 10. Check if a Barber is Available at a Specific Date and Time
DECLARE @isAvailable BIT;
SET @isAvailable = dbo.IsBarberAvailable(@barberID = 1, @date = '2024-01-21', @timeSlot = '09:00 AM');
SELECT @isAvailable AS IsAvailable;
