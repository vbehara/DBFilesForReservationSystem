--Table Creation Scripts

--tbl_UserRole
CREATE TABLE tbl_UserRole
(
	[RoleId] TINYINT IDENTITY(1,1) CONSTRAINT pk_RoleId PRIMARY KEY,
	[RoleName] VARCHAR(20) NOT NULL
)
GO


--tbl_User
CREATE TABLE tbl_User
(
	[UserId] VARCHAR(50) CONSTRAINT pk_UserId PRIMARY KEY,
	[Name] VARCHAR(50) NOT NULL,
	[Age] TINYINT NOT NULL,
	[Gender] CHAR(1) NOT NULL CONSTRAINT chk_Gender CHECK(Gender IN ('F','M')),
	[Password] VARCHAR(15) NOT NULL,
	[RoleId] TINYINT CONSTRAINT fk_RoleId REFERENCES tbl_UserRole(RoleId)
	
)
GO


--tbl_Train
CREATE TABLE tbl_Train
(
	[TrainId] SMALLINT IDENTITY(1000,1) CONSTRAINT pk_TrainId PRIMARY KEY,
	[TrainName] VARCHAR(30) NOT NULL,
	[TrainType] VARCHAR(10) NOT NULL,
	[Sunday] BIT,
	[Monday] BIT,
	[Tuesday] BIT,
	[Wednesday] BIT,
	[Thursday] BIT,
	[Friday] BIT,
	[Saturday] BIT
)
GO


--tbl_ClassofService
CREATE TABLE tbl_ClassofService
(
	[ClassId] TINYINT IDENTITY(1,1) CONSTRAINT pk_ClassId PRIMARY KEY,
	[ClassName] VARCHAR(10) NOT NULL UNIQUE
)
GO


--tbl_ClasswiseSeats
CREATE TABLE tbl_ClasswiseSeats
(
	[TrainId] SMALLINT CONSTRAINT fk_TrainId REFERENCES tbl_Train(TrainId),
	[ClassId] TINYINT CONSTRAINT fk_ClassId REFERENCES tbl_ClassofService(ClassId),
	[NumberofSeats] TINYINT NOT NULL CONSTRAINT chk_NumberofSeats CHECK(NumberofSeats>0),
	[FarePerPerson] MONEY NOT NULL,
	CONSTRAINT pk_TrainId_ClassId PRIMARY KEY(TrainId,ClassId)
)
GO


--tbl_Station
CREATE TABLE tbl_Station
(
	[StationCode] CHAR(3) CONSTRAINT pk_StationCode PRIMARY KEY,
	[StationName] VARCHAR(20) NOT NULL
)
GO


--tbl_TrainRoute
CREATE TABLE tbl_TrainRoute
(
	[TrainId] SMALLINT CONSTRAINT fk_TrainId_TrainSchedule REFERENCES tbl_Train(TrainId),
	[StationCode] CHAR(3) CONSTRAINT fk_Station REFERENCES tbl_Station(StationCode),
	[ArrivalTime] TIME,
	[DepartureTime] TIME,
	[DistanceFromDestination] INT NOT NULL,
	[Day] TINYINT NOT NULL,
	CONSTRAINT pk_TrainIdStation PRIMARY KEY(TrainId,StationCode)
)
GO


--tbl_TicketBooking
CREATE TABLE tbl_TicketBooking
(
	[PNRNumber] INT CONSTRAINT pk_PNRNumber PRIMARY KEY,
	[UserId] VARCHAR(50) CONSTRAINT fk_UserId REFERENCES tbl_User(UserId),
	[DateofBooking] DATETIME NOT NULL,
	[DateofCancellation] DATETIME,
	[DateofJourney] DATE NOT NULL,
	[TrainId] SMALLINT NOT NULL,
	[Class] TINYINT NOT NULL,
	[NumberofSeats] TINYINT CONSTRAINT chk_NumberofSeats_TicketBooking CHECK(NumberofSeats>0),
	[FromStation] CHAR(3) NOT NULL,
	[ToStation] CHAR(3) NOT NULL,
	[Status] VARCHAR(20) CONSTRAINT chk_Status CHECK([Status] IN ('Confirmed','Waiting List','Cancelled')),
	[TotalFare] MONEY NOT NULL,
	CONSTRAINT fk_TrainClass FOREIGN KEY(TrainId,Class) REFERENCES tbl_ClasswiseSeats(TrainId,ClassId),
	CONSTRAINT fk_TrainFromStation FOREIGN KEY(TrainId,FromStation) REFERENCES tbl_TrainRoute(TrainId,StationCode),
	CONSTRAINT fk_TrainToStation FOREIGN KEY(TrainId,ToStation) REFERENCES tbl_TrainRoute(TrainId,StationCode),
	CONSTRAINT chk_DateofCancellation CHECK(DateofCancellation>=DateofBooking AND DateofCancellation<=DateofJourney),
	CONSTRAINT chk_DateofJourney CHECK(DateofJourney>=DateofBooking)
)
GO


--tbl_SeatDetails
CREATE TABLE tbl_SeatDetails
(
	[PNRNumber] INT CONSTRAINT fk_PNRNumber REFERENCES tbl_TicketBooking(PNRNumber),
	[SeatNumber] VARCHAR(20),
	[PassengerName] VARCHAR(50) NOT NULL,
	[Age] TINYINT NOT NULL,
	[Gender] CHAR(1) NOT NULL CONSTRAINT chk_Gender_SeatDetails CHECK(Gender IN ('F','M')),
	CONSTRAINT pk_PNRNumberPassengerNameAgeGender PRIMARY KEY(PNRNumber,PassengerName,Age,Gender)
)
GO