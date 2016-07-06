--Procedure to change the Password for a given user
CREATE PROCEDURE usp_ChangePassword(@UserId VARCHAR(50), @OldPassword VARCHAR(15), @NewPassword VARCHAR(15))
AS
BEGIN

	BEGIN TRY
	
		--Check whther the combination of UserId and Password exist or not, if the combination is valid, change the password and return 0
		IF EXISTS(SELECT UserId, [Password] FROM tbl_User WHERE UserId=@UserId AND Password=@OldPassword)
		BEGIN
		
			UPDATE tbl_User SET Password=@NewPassword WHERE UserId=@UserId
			RETURN 0
			
		END
		
		--Return -1 if the UserId and Password combination is not valid
		ELSE RETURN -1
	END TRY
	
	BEGIN CATCH
	
		--In case of any exception, return -2
		RETURN -2
	END CATCH
END
GO


--Procedure to book the ticket
CREATE PROCEDURE usp_BookTicket(@UserId VARCHAR(50), @DateofJourney DATE, @TrainId SMALLINT, @CLassId TINYINT, @NumberofSeats INT, 
								@FromStation CHAR(3), @ToStation CHAR(3), @PNRNumber INT OUT, @Status VARCHAR(20) OUT)
AS
BEGIN
	
	DECLARE @AvailableSeats TINYINT, @Distance SMALLINT, @FarePerPerson MONEY, @TotalFare MONEY, @Day VARCHAR(10), @Available BIT
	
	--Fetch the day from the Date of Journey
	SELECT @Day=DATENAME(DW,@DateofJourney)
	
	--Check if the train is available on that day
	IF @Day='Sunday'
		SELECT @Available=Sunday FROM tbl_Train WHERE TrainId=@TrainId
		
	ELSE IF @Day='Monday'
		SELECT @Available=Monday FROM tbl_Train WHERE TrainId=@TrainId
		
	ELSE IF @Day='Tuesday'
		SELECT @Available=Tuesday FROM tbl_Train WHERE TrainId=@TrainId
		
	ELSE IF @Day='Wednesday'
		SELECT @Available=Wednesday FROM tbl_Train WHERE TrainId=@TrainId
		
	ELSE IF @Day='Thursday'
		SELECT @Available=Thursday FROM tbl_Train WHERE TrainId=@TrainId
		
	ELSE IF @Day='Friday'
		SELECT @Available=Friday FROM tbl_Train WHERE TrainId=@TrainId
		
	ELSE IF @Day='Saturday'
		SELECT @Available=Saturday FROM tbl_Train WHERE TrainId=@TrainId
	
	BEGIN TRY
	
		--If the train is available, continue with the rest of the logic 
		IF @Available=1
		BEGIN
		
				
			--Fetch the maximum PNR Number if records are present in tbl_TicketBooking
			IF EXISTS(SELECT * FROM tbl_TicketBooking)
				SELECT @PNRNumber=MAX(PNRNumber)+1 FROM tbl_TicketBooking
			
			--If there is no record present in tbl_TicketBooking, set the PNR Number to 111111
			ELSE SET @PNRNumber=111111
			
			--Fetch the number of seats available for the given train, class and date of journey
			SET @AvailableSeats=dbo.ufn_CheckSeatAvailability(@TrainId, @ClassId, @DateofJourney)
			
			--Fetch the distance for the given TrainId, From Station and To Station
			SET @Distance=dbo.ufn_CalculateDistance(@TrainId, @FromStation, @ToStation)
				
			--Fetch the fare per person 
			SET @FarePerPerson = dbo.ufn_CalculateFare(@Distance,@TrainId,@CLassId)
				
			--Calculate the total fare based on the fare per person
			SET @TotalFare=@FarePerPerson*@NumberofSeats
			
			--Check if the seats are available
			IF @AvailableSeats>=@NumberofSeats
			BEGIN
				--Insert the values into tbl_TicketBooking with status as 'Confirmed' and return the value 1
				INSERT INTO tbl_TicketBooking(PNRNumber, UserId, DateofBooking, DateofJourney, TrainId, Class, NumberofSeats, FromStation, ToStation, 
				[Status], TotalFare) 
				VALUES(@PNRNumber, @UserId, GETDATE(), @DateofJourney, @TrainId, @CLassId, @NumberofSeats, @FromStation, @ToStation, 'Confirmed', @TotalFare)
			
				SET @Status='Confirmed'
				
				RETURN 1
			
			END
			
			ELSE
			BEGIN
			
				--Insert the values into tbl_TicketBooking with status as 'Waiting List' and return the value 2
				INSERT INTO tbl_TicketBooking(PNRNumber, UserId, DateofBooking, DateofJourney, TrainId, Class, NumberofSeats, FromStation, ToStation, 
				[Status], TotalFare) 
				VALUES(@PNRNumber, @UserId, GETDATE(), @DateofJourney, @TrainId, @CLassId, @NumberofSeats, @FromStation, @ToStation, 'Waiting List', @TotalFare)
			
				SET @Status='Waiting List'
				
				RETURN 2
			
			END
			
		END
		
		--If the train is not available on that day, return -1
		ELSE RETURN -1
		
	END TRY
	
	BEGIN CATCH
		--In case of any exception, return -2
		RETURN -2
	END CATCH
	
END
GO


--Procedure to insert the seat details for a given PNR Number
ALTER PROCEDURE [dbo].[usp_InsertSeatDetails](@PNRNumber INT, @PassengerName VARCHAR(50), @Age TINYINT, @Gender CHAR(1))
AS
BEGIN

	DECLARE @Status VARCHAR(20), @ClassName VARCHAR(10), @LenClassName TINYINT, @SeatNumber VARCHAR(20), @LenSeatNumber TINYINT, 
		    @SeatPart SMALLINT, @LengthDifference TINYINT

	
	BEGIN TRY
	
		--Check if the PNR Number exists
		IF EXISTS(SELECT PNRNumber FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
		BEGIN

			--Fetch the status of the ticket
			SELECT @Status=[Status] FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber
			
			BEGIN TRAN InsertSeatTransaction
			
			--Check if the status is 'Confirmed'
			IF @Status='Confirmed'
			BEGIN
			
				
				
				--Fetch the class name
				SELECT @ClassName=ClassName FROM tbl_ClassofService WHERE ClassId=
				(SELECT Class FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
				
				--Check whether there are some seats available for the cancelled tickets
				IF EXISTS(SELECT * FROM tbl_SeatDetails WHERE SeatNumber!='NA' 
				AND PNRNumber IN 
				(SELECT PNRNumber FROM tbl_TicketBooking WHERE DateofJourney=
				(SELECT DateofJourney FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber) 
				 AND Class = (SELECT Class FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
				 AND [Status]='Cancelled'))
				BEGIN
				
					--Fetch the Seat Number from the cancelled tickets
					SELECT TOP(1) @SeatNumber=SeatNumber FROM tbl_SeatDetails WHERE PNRNumber = 
					(SELECT TOP(1)TB.PNRNumber FROM tbl_SeatDetails SD JOIN tbl_TicketBooking TB 
					 ON SD.PNRNumber=TB.PNRNumber
					 WHERE SeatNumber!='NA' AND
					 TB.PNRNumber IN
					(SELECT PNRNumber FROM tbl_TicketBooking WHERE DateofJourney=
					(SELECT DateofJourney FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber) 
					 AND Class = (SELECT Class FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
					 AND [Status]='Cancelled') ORDER BY DateofCancellation)ORDER BY SeatNumber
					 
					 --Update the seat of the cancelled ticket which has been allocated
					 UPDATE tbl_SeatDetails SET SeatNumber='NA' WHERE SeatNumber=@SeatNumber
					 AND PNRNumber=
					(SELECT TOP(1)TB.PNRNumber FROM tbl_SeatDetails SD JOIN tbl_TicketBooking TB 
					 ON SD.PNRNumber=TB.PNRNumber
					 WHERE SeatNumber!='NA' AND
					 TB.PNRNumber IN
					(SELECT PNRNumber FROM tbl_TicketBooking WHERE DateofJourney=
					(SELECT DateofJourney FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber) 
					 AND Class = (SELECT Class FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
					 AND [Status]='Cancelled') ORDER BY DateofCancellation)
					 
					 
				END
				ELSE
				BEGIN
					--Fetch the maximum seat number allocated
					SELECT @SeatNumber=MAX(SeatNumber) FROM tbl_SeatDetails WHERE PNRNumber IN 
					(SELECT PNRNumber FROM tbl_TicketBooking WHERE DateofJourney=
					(SELECT DateofJourney FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber) 
					 AND Class = (SELECT Class FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
					 AND [Status]='Confirmed') 
				 
					--Calculate the length of the class name and seat number and then calulate the difference between the two
					SET @LenClassName=LEN(@ClassName) 
					SET @LenSeatNumber=LEN(@SeatNumber)
					SET @LengthDifference=@LenSeatNumber-(@LenClassName+1)
					 
					--If the Seat Number is not null, then, generate the Seat Number
					IF (@SeatNumber IS NOT NULL)
					BEGIN
						SET @SeatPart=SUBSTRING(@SeatNumber,@LenClassName+2,@LengthDifference)
						SET @SeatPart+=1
						SET @SeatNumber=@ClassName+'-'+CONVERT(VARCHAR, @SeatPart)
					END
					  
					--If the Seat Number is null, then, generate the Seat Number as ClassName-1
					ELSE SET @SeatNumber=@ClassName+'-1'
				END
				--Insert the values into tbl_SeatDetails and return the value 1
				INSERT INTO tbl_SeatDetails VALUES(@PNRNumber,@SeatNumber, @PassengerName, @Age, @Gender)
				
				COMMIT TRAN InsertSeatTransaction
				
				RETURN 1
			
			END
			
			--Check if the status is 'Waiting List'
			ELSE IF @Status='Waiting List'
			BEGIN
			
				--Insert the values into tbl_SeatDetails and return the value 2
				INSERT INTO tbl_SeatDetails VALUES(@PNRNumber,'NA', @PassengerName, @Age, @Gender)
				
				COMMIT TRAN InsertSeatTransaction
				
				RETURN 2
			
			END
			
			--If the status is something else return -2
			ELSE RETURN -2

		END

		--If the PNR Number is not valid, then return -1
		ELSE RETURN -1
		
	END TRY

	BEGIN CATCH
	
		ROLLBACK TRAN
		--In case of any exception, return -3
		RETURN -3
	END CATCH

END
GO


--Procedure to cancel a ticket
CREATE PROCEDURE [dbo].[usp_CancelTicket](@PNRNumber INT, @RefundAmount MONEY OUTPUT)
AS
BEGIN

	DECLARE @NumberofSeatsCancelled TINYINT, @PNRNumbertobeUpdated INT, @Count TINYINT=1, @SeatNumbertobeUpdated VARCHAR(20), 
			@NumberofSeatstobeUpdated TINYINT=0, @NumberofSeatstobeUpdatedTemp TINYINT, @DateofJourney DATE

	BEGIN TRY
	
		--Check whether the PNR Number is valid
		IF EXISTS(SELECT PNRNumber FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
		BEGIN
		
			SELECT @DateofJourney=DateofJourney FROM tbl_TicketBooking WHERE  PNRNumber=@PNRNumber
			
			IF @DateofJourney<GETDATE()
			BEGIN
				RETURN -2
			END
		
			BEGIN TRAN CancelTicketTransaction
			
			--If the PNR Number is valid, then update the status of the ticket as cancelled
			UPDATE tbl_TicketBooking SET Status='Cancelled',DateofCancellation=GETDATE() WHERE PNRNumber=@PNRNumber
			
			--Fetch the refund amount after cancelling the ticket
			SELECT @RefundAmount=ISNULL(TotalFare,0) FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber
			
			--Fetch the number of seats cancelled
			SELECT @NumberofSeatsCancelled=ISNULL(NumberofSeats,0) FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber
			
			--Set the value for number of seats to be updated
			SET @NumberofSeatstobeUpdated=@NumberofSeatsCancelled-@NumberofSeatstobeUpdated
			
			WHILE (@NumberofSeatstobeUpdated>0)
			BEGIN
				--Check whether there is any ticket with status as 'Waiting List'
				IF EXISTS(SELECT PNRNumber FROM tbl_TicketBooking WHERE DateofJourney=
						  (SELECT DateofJourney FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber) 
						   AND Class = (SELECT Class FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
						   AND [Status]='Waiting List'
						   AND NumberofSeats<=@NumberofSeatstobeUpdated)
				BEGIN
				
					--Fetch the PNR Number of the ticket whose status has to be changed from 'Waiting List' to 'Confirmed'
					SELECT TOP(1) @PNRNumbertobeUpdated=PNRNumber FROM tbl_TicketBooking WHERE DateofJourney=
					(SELECT DateofJourney FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber) 
					 AND Class = (SELECT Class FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumber)
					 AND [Status]='Waiting List'
					 AND NumberofSeats<=@NumberofSeatstobeUpdated 
					 ORDER BY DateofBooking
				     
					 --Update the status of Waiting List ticket to Confirmed
					 UPDATE tbl_TicketBooking SET [Status]='Confirmed' WHERE PNRNumber=@PNRNumbertobeUpdated
				     
					 --Fetch the number of seats to be updated 
					 SELECT @NumberofSeatstobeUpdatedtemp=NumberofSeats FROM tbl_TicketBooking WHERE PNRNumber=@PNRNumbertobeUpdated
				     
					 --Update the seat details for that particular PNR Number 
					 WHILE @Count<=@NumberofSeatstobeUpdatedtemp
					 BEGIN		   
								
						--Fetch the seat number that can be alloted		
						SELECT TOP(1) @SeatNumbertobeUpdated=SeatNumber FROM tbl_SeatDetails WHERE 
						PNRNumber=@PNRNumber AND SeatNumber!='NA' ORDER BY SeatNumber
						
						--Update the seat number for the PNR Number to be updated and setthe seat number to 'NA' for the cancelled ticket
						UPDATE tbl_SeatDetails SET SeatNumber=@SeatNumbertobeUpdated WHERE PNRNumber=@PNRNumbertobeUpdated
						UPDATE tbl_SeatDetails SET SeatNumber='NA' WHERE PNRNumber=@PNRNumber AND SeatNumber=@SeatNumbertobeUpdated
						
						--Increment the counter by 1
						SET @Count=@Count+1
						
					 END
					 
					 --Update the value of number of seats to be updated
					 SET @NumberofSeatstobeUpdated=@NumberofSeatstobeUpdated-@NumberofSeatstobeUpdatedTemp
				 
				 END
				 
				 ELSE
				 BEGIN
				 
					SET @NumberofSeatstobeUpdated=0
				 
				 END
				 
				 UPDATE tbl_TicketBooking SET [Status]='Cancelled' WHERE PNRNumber=@PNRNumber
				 
			END 
			
			COMMIT TRAN CancelTicketTransaction
			
			--Return the value 0 in case of successful transaction
			RETURN 0
			
			
		
		END

		--Return -1 if the PNR Number is not valid
		ELSE RETURN -1
		
	END TRY
	
	BEGIN CATCH
		ROLLBACK TRAN
		--In case of any exception, return -3
		RETURN -3
	END CATCH

END
GO





--Scalar function to validate the user and return the RoleId
CREATE FUNCTION ufn_FetchRole(@UserId VARCHAR(50), @Password VARCHAR(15))
RETURNS TINYINT
BEGIN

	DECLARE @RoleId TINYINT=-1

	--Check whether the combination of UserId and Password are valid or not, if valid, return the RoleId, else return 0 as the RoleId
	IF EXISTS (SELECT * FROM tbl_User WHERE UserId=@UserId AND [Password]=@Password )
		SELECT @RoleId =RoleId FROM tbl_User WHERE UserId=@UserId
		
	RETURN @RoleId


END
GO


--Scalar function to calculate the distance between two stations for a given train
CREATE FUNCTION ufn_CalculateDistance(@TrainId SMALLINT, @FromStation CHAR(3), @ToStation CHAR(3))
RETURNS SMALLINT
BEGIN

	DECLARE @FromStationDistance SMALLINT, @ToStationDistance SMALLINT, @Distance SMALLINT=-1
	
	--Fetch the distancefromdestination for both fromstation and tostation and then calculate the distance and return it
	SELECT @FromStationDistance=DistanceFromDestination FROM tbl_TrainRoute WHERE TrainId=@TrainId AND StationCode=@FromStation
	SELECT @ToStationDistance=DistanceFromDestination FROM tbl_TrainRoute WHERE TrainId=@TrainId AND StationCode=@ToStation
	SET @Distance=@FromStationDistance-@ToStationDistance

	RETURN @Distance

END
GO


--Scalar function to calculate the fare 
CREATE FUNCTION ufn_CalculateFare(@Distance SMALLINT, @TrainId SMALLINT, @ClassId TINYINT)
RETURNS MONEY
BEGIN

	--Calculate the fare per person based on distance, trainid and classid 
	DECLARE @Fare MONEY=-1
	
	SELECT @Fare=FarePerPerson FROM tbl_ClasswiseSeats WHERE TrainId=@TrainId AND ClassId=@ClassId
	
	RETURN (@Fare*@Distance)

END
GO





--Scalar function to check for the availability of seats
CREATE FUNCTION ufn_CheckSeatAvailability(@TrainId SMALLINT, @ClassId TINYINT, @DateofJourney DATE)
RETURNS TINYINT
BEGIN

	DECLARE @AvailableSeats TINYINT, @SeatsBooked TINYINT=0, @Totalseats TINYINT
	
	--Fetch the number of seats that have been booked 
	SELECT @SeatsBooked=ISNULL(SUM(NumberofSeats),0) FROM tbl_TicketBooking WHERE TrainId=@TrainId AND Class=@ClassId AND DateofJourney=@DateofJourney
	AND [Status]='Confirmed'
	
	--Fetch the total number of seats
	SELECT @TotalSeats=ISNULL(NumberofSeats,0) FROM tbl_ClasswiseSeats WHERE TrainId=@TrainId AND ClassId=@ClassId
	
	--Calculate the number of available seats and then return it
	SET @AvailableSeats=@TotalSeats-@SeatsBooked
	
	IF @AvailableSeats<0
		SET @AvailableSeats=-1
	RETURN @AvailableSeats 

END
GO


--Inline table valued function to fetch the PNR status
CREATE FUNCTION ufn_FetchPNRStatus(@PNRNumber INT)
RETURNS TABLE
AS RETURN

	--Fetch the passenger name, age, gender, status and seat number
	(SELECT PassengerName, Age, Gender, [Status],SeatNumber FROM tbl_SeatDetails SD
	JOIN tbl_TicketBooking TB 
	ON SD.PNRNumber=TB.PNRNumber
	WHERE SD.PNRNumber=@PNRNumber)
GO

--Inline table valued function to fetch the available classes for a train
CREATE FUNCTION ufn_FetchAvailableClassesforaTrain(@TrainId SMALLINT)
RETURNS TABLE 
AS RETURN
	(SELECT CS.ClassId, ClassName FROM tbl_ClassofService CS JOIN 
	tbl_ClasswiseSeats CWS ON CS.ClassId=CWS.ClassId
	WHERE TrainId=@TrainId AND NumberofSeats>0)
GO




--Multi-line table valued function
CREATE FUNCTION ufn_FetchScheduleBasedonTrainId(@TrainId INT)
RETURNS @Table TABLE(TrainName VARCHAR(30), FromStation CHAR(3), FromDepartureTime TIME, [Day] TINYINT, ToStation CHAR(3), 
			         ToArrivalTime TIME, Sunday BIT, Monday BIT, Tuesday BIT, Wednesday BIT, Thursday BIT, Friday BIT, 
			         Saturday BIT)
BEGIN
	
	DECLARE @TrainName VARCHAR(30), @FromStation CHAR(3), @FromDepartureTime TIME, @Day TINYINT, @ToStation CHAR(3), 
			@ToArrivalTime TIME, @Sunday BIT, @Monday BIT, @Tuesday BIT, @Wednesday BIT, @Thursday BIT, @Friday BIT, 
			@Saturday BIT
	
	--Fetch the train name and the days when the train runs
	SELECT @TrainName=TrainName, @Sunday=Sunday, @Monday=Monday, @Tuesday=Tuesday, @Wednesday=Wednesday, @Thursday=Thursday, 
		   @Friday=Friday, @Saturday=Saturday FROM tbl_Train WHERE TrainId=@TrainId
		   
	--Fetch the source and destination of the train
	SELECT @FromStation=StationCode, @FromDepartureTime=DepartureTime FROM tbl_TrainRoute 
	WHERE TrainId=@TrainId AND DistanceFromDestination=(SELECT MAX(DistanceFromDestination) FROM tbl_TrainRoute WHERE TrainId=@TrainId)

	SELECT @ToStation=StationCode, @ToArrivalTime=ArrivalTime, @Day=[Day] FROM tbl_TrainRoute 
	WHERE TrainId=@TrainId AND DistanceFromDestination=0
	
	--Insert the values into the table which would be returned
	INSERT INTO @Table VALUES(@TrainName, @FromStation, @FromDepartureTime, @Day, @ToStation, 
			@ToArrivalTime, @Sunday, @Monday, @Tuesday, @Wednesday, @Thursday, @Friday, @Saturday)
	
RETURN

END
GO

--Multi-line table valued function to fetch the train route
CREATE FUNCTION ufn_FetchTrainRoute(@TrainId INT)
RETURNS @Table TABLE(Station CHAR(3), ArrivalTime TIME, DepartureTime TIME,  [Day] TINYINT)
BEGIN

	--Fetch the station code, arrival time, departure time and the day of journey on which the train departs from that station
	INSERT @Table
	SELECT StationCode, ArrivalTime, DepartureTime, [Day] 
	FROM tbl_TrainRoute WHERE TrainId=@TrainId ORDER BY DistanceFromDestination DESC
	 
	RETURN
END
GO



--Multi-line table valued function to fetch the details of a class for a train
CREATE FUNCTION ufn_FetchClassDetails(@TrainId INT, @ClassId TINYINT, @DateofJourney DATE, @FromStation CHAR(3), @ToStation CHAR(3))
RETURNS @Table TABLE(ClassName VARCHAR(10), AvailableSeats TINYINT, FarePerPerson MONEY)
BEGIN

	DECLARE @ClassName VARCHAR(10), @Availableseats TINYINT, @FarePerPerson MONEY, @Distance SMALLINT
	
	--Fetch the class name from the train id
	SELECT @ClassName=ClassName FROM tbl_ClassofService WHERE ClassId=@ClassId
	
	--Fetch the number of available seats for the given train, class and date
	SET @AvailableSeats=dbo.ufn_CheckAvailability(@TrainId,@ClassId,@DateofJourney)
	
	--Fetch the distance between the stations
	SET @Distance=dbo.ufn_CalculateDistance(@TrainId, @FromStation, @ToStation)
	
	--Fetch the fare per person
	SET @FarePerPerson=dbo.ufn_CalculateFare(@Distance, @TrainId, @ClassId)
	
	--Insert the values into the table to be returned
	INSERT INTO @Table VALUES(@ClassName, @Availableseats, @FarePerPerson)

RETURN

END
GO