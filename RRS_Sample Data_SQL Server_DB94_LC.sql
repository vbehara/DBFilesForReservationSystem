--tbl_UserRole
INSERT INTO tbl_UserRole VALUES('Admin')
INSERT INTO tbl_UserRole VALUES('Customer')

SELECT * FROM tbl_UserRole

--tbl_User
INSERT INTO tbl_User VALUES('ScaryHarry','Harry',28,'M','harry',1)
INSERT INTO tbl_User VALUES('CalmTom','Tom',26,'M','tom',2)
INSERT INTO tbl_User VALUES('ScamSam','Samantha',24,'F','samantha',2)

SELECT * FROM tbl_User

--tbl_Train
INSERT INTO tbl_Train VALUES('Chennai Express','Express',1,1,1,1,1,1,1)
INSERT INTO tbl_Train VALUES('Kaveri Express','Express',1,1,1,1,1,1,1)

SELECT * FROM tbl_Train

--tbl_ClassofService
INSERT INTO tbl_ClassofService VALUES('Sleeper')
INSERT INTO tbl_ClassofService VALUES('First AC')
INSERT INTO tbl_ClassofService VALUES('Second AC')
INSERT INTO tbl_ClassofService VALUES('Third AC')
INSERT INTO tbl_ClassofService VALUES('Chair Car')
INSERT INTO tbl_ClassofService VALUES('FirstClass')

SELECT * FROM tbl_ClassofService

--tbl_ClasswiseSeats
INSERT INTO tbl_ClasswiseSeats VALUES(1000,1,10,1)
INSERT INTO tbl_ClasswiseSeats VALUES(1001,1,10,1)

SELECT * FROM tbl_ClasswiseSeats

--tbl_Station
INSERT INTO tbl_Station VALUES('MAS','Chennai')
INSERT INTO tbl_Station VALUES('SBC','Bangalore')
INSERT INTO tbl_Station VALUES('MYS','Mysore')
INSERT INTO tbl_Station VALUES('MYA','Mandya')
INSERT INTO tbl_Station VALUES('KPD','Katpadi Jn')

SELECT * FROM tbl_Station

--tbl_TrainRoute
INSERT INTO tbl_TrainRoute VALUES(1000,'MYS',NULL,'20:30',500,0)
INSERT INTO tbl_TrainRoute VALUES(1000,'MYA','21:13','21:15',455,0)
INSERT INTO tbl_TrainRoute VALUES(1000,'SBC','23:30','23:45',360,0)
INSERT INTO tbl_TrainRoute VALUES(1000,'KPD','04:05','04:10',130,1)
INSERT INTO tbl_TrainRoute VALUES(1000,'MAS','07:25',NULL,0,1)
INSERT INTO tbl_TrainRoute VALUES(1001,'MAS',NULL,'21:30',500,0)
INSERT INTO tbl_TrainRoute VALUES(1001,'KPD','23:43','23:45',370,0)
INSERT INTO tbl_TrainRoute VALUES(1001,'SBC','04:10','04:50',140,1)
INSERT INTO tbl_TrainRoute VALUES(1001,'MYA','06:39','06:40',45,1)
INSERT INTO tbl_TrainRoute VALUES(1001,'MYS','08:00',NULL,0,1)

SELECT * FROM tbl_TrainRoute

