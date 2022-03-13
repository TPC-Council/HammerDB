CREATE TABLE Student (
  MatrNr int(11) DEFAULT '0' NOT NULL auto_increment,
  Name varchar(20),
  Semester int(11),
  PRIMARY KEY (MatrNr)
);

INSERT INTO Student VALUES (1,'Sojka',4);
INSERT INTO Student VALUES (2,'Preisner',2);
INSERT INTO Student VALUES (3,'Killar',2);
INSERT INTO Student VALUES (4,'Penderecki',10);
INSERT INTO Student VALUES (5,'Turnau',2);
INSERT INTO Student VALUES (6,'Grechuta',3);
INSERT INTO Student VALUES (7,'Gorniak',1);
INSERT INTO Student VALUES (8,'Niemen',3);
INSERT INTO Student VALUES (9,'Bem',5);

CREATE TABLE Binarytest (
  id int(11) DEFAULT '0' NOT NULL auto_increment,
  data longblob,
  PRIMARY KEY (id)
);
 
