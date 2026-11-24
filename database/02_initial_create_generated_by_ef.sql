-- 02_initial_create_generated_by_ef.sql
-- NOT run by hand: this is the SQL that EF Core generated from the C# entities
-- (dotnet ef migrations script). Update-Database runs exactly this on MySQL.
-- Kept here so you can read the CREATE TABLE / FOREIGN KEY / INSERT statements.

CREATE TABLE IF NOT EXISTS `__EFMigrationsHistory` (
    `MigrationId` varchar(150) NOT NULL,
    `ProductVersion` varchar(32) NOT NULL,
    PRIMARY KEY (`MigrationId`)
);

START TRANSACTION;
CREATE TABLE `subjects` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `Name` varchar(50) NOT NULL,
    `MaxMarks` int NOT NULL,
    PRIMARY KEY (`Id`)
);

CREATE TABLE `users` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `FullName` varchar(100) NOT NULL,
    `LoginId` varchar(100) NOT NULL,
    `ContactEmail` varchar(150) NULL,
    `PasswordHash` varchar(100) NOT NULL,
    `Role` varchar(20) NOT NULL,
    `MustChangePassword` tinyint(1) NOT NULL,
    `CreatedAt` datetime(6) NOT NULL,
    PRIMARY KEY (`Id`)
);

CREATE TABLE `classes` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `GradeName` varchar(20) NOT NULL,
    `Section` varchar(5) NOT NULL,
    `ClassTeacherId` int NULL,
    `ResultsPublishedAt` datetime(6) NULL,
    PRIMARY KEY (`Id`),
    CONSTRAINT `FK_classes_users_ClassTeacherId` FOREIGN KEY (`ClassTeacherId`) REFERENCES `users` (`Id`) ON DELETE SET NULL
);

CREATE TABLE `students` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `FullName` varchar(100) NOT NULL,
    `RollNo` varchar(10) NOT NULL,
    `ClassId` int NOT NULL,
    PRIMARY KEY (`Id`),
    CONSTRAINT `FK_students_classes_ClassId` FOREIGN KEY (`ClassId`) REFERENCES `classes` (`Id`) ON DELETE RESTRICT
);

CREATE TABLE `teaching_assignments` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `ClassId` int NOT NULL,
    `SubjectId` int NOT NULL,
    `TeacherId` int NOT NULL,
    `SubmittedAt` datetime(6) NULL,
    PRIMARY KEY (`Id`),
    CONSTRAINT `FK_teaching_assignments_classes_ClassId` FOREIGN KEY (`ClassId`) REFERENCES `classes` (`Id`) ON DELETE RESTRICT,
    CONSTRAINT `FK_teaching_assignments_subjects_SubjectId` FOREIGN KEY (`SubjectId`) REFERENCES `subjects` (`Id`) ON DELETE RESTRICT,
    CONSTRAINT `FK_teaching_assignments_users_TeacherId` FOREIGN KEY (`TeacherId`) REFERENCES `users` (`Id`) ON DELETE RESTRICT
);

CREATE TABLE `marks` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `StudentId` int NOT NULL,
    `SubjectId` int NOT NULL,
    `Obtained` int NOT NULL,
    `EnteredById` int NOT NULL,
    `UpdatedAt` datetime(6) NOT NULL,
    PRIMARY KEY (`Id`),
    CONSTRAINT `FK_marks_students_StudentId` FOREIGN KEY (`StudentId`) REFERENCES `students` (`Id`) ON DELETE CASCADE,
    CONSTRAINT `FK_marks_subjects_SubjectId` FOREIGN KEY (`SubjectId`) REFERENCES `subjects` (`Id`) ON DELETE RESTRICT,
    CONSTRAINT `FK_marks_users_EnteredById` FOREIGN KEY (`EnteredById`) REFERENCES `users` (`Id`) ON DELETE RESTRICT
);

INSERT INTO `classes` (`Id`, `ClassTeacherId`, `GradeName`, `ResultsPublishedAt`, `Section`)
VALUES (5, NULL, 'Class 9', NULL, 'C');
SELECT ROW_COUNT();


INSERT INTO `subjects` (`Id`, `MaxMarks`, `Name`)
VALUES (1, 100, 'English');
SELECT ROW_COUNT();

INSERT INTO `subjects` (`Id`, `MaxMarks`, `Name`)
VALUES (2, 100, 'Mathematics');
SELECT ROW_COUNT();

INSERT INTO `subjects` (`Id`, `MaxMarks`, `Name`)
VALUES (3, 60, 'Physics');
SELECT ROW_COUNT();

INSERT INTO `subjects` (`Id`, `MaxMarks`, `Name`)
VALUES (4, 60, 'Chemistry');
SELECT ROW_COUNT();

INSERT INTO `subjects` (`Id`, `MaxMarks`, `Name`)
VALUES (5, 60, 'Biology');
SELECT ROW_COUNT();


INSERT INTO `users` (`Id`, `ContactEmail`, `CreatedAt`, `FullName`, `LoginId`, `MustChangePassword`, `PasswordHash`, `Role`)
VALUES (1, NULL, '2026-11-20 09:00:00.000000', 'School Admin', 'admin@school.com', FALSE, '$2a$11$c6gJO2BSfKjGK2cigDfJZOnxFT6ddgxsJnwSCAYt2VHHGDpaTrTk2', 'admin');
SELECT ROW_COUNT();

INSERT INTO `users` (`Id`, `ContactEmail`, `CreatedAt`, `FullName`, `LoginId`, `MustChangePassword`, `PasswordHash`, `Role`)
VALUES (2, NULL, '2026-11-20 09:00:00.000000', 'VP Sarah', 'vp@school.com', FALSE, '$2a$11$knbs2jFie66WoIHXYKVkOetGaC0bkXmUDHQmjGEIDfPLqP2D9rREq', 'vp');
SELECT ROW_COUNT();

INSERT INTO `users` (`Id`, `ContactEmail`, `CreatedAt`, `FullName`, `LoginId`, `MustChangePassword`, `PasswordHash`, `Role`)
VALUES (3, NULL, '2026-11-20 09:00:00.000000', 'Teacher Sania', 'sania@school.com', FALSE, '$2a$11$zUYQ3hSJRte1VA7nbAlzwO0h9woXmWqkT0LuUm2mVhfYVeCCWoWfi', 'teacher');
SELECT ROW_COUNT();

INSERT INTO `users` (`Id`, `ContactEmail`, `CreatedAt`, `FullName`, `LoginId`, `MustChangePassword`, `PasswordHash`, `Role`)
VALUES (4, NULL, '2026-11-20 09:00:00.000000', 'Teacher Ahsan', 'ahsan@school.com', FALSE, '$2a$11$PvGvQ3bx/UDjVC9CcTBFF.POtBi5GnNJ0HOyAt4fhTsvU1IDEzEoa', 'teacher');
SELECT ROW_COUNT();

INSERT INTO `users` (`Id`, `ContactEmail`, `CreatedAt`, `FullName`, `LoginId`, `MustChangePassword`, `PasswordHash`, `Role`)
VALUES (5, NULL, '2026-11-20 09:00:00.000000', 'Teacher Maryam', 'maryam@school.com', FALSE, '$2a$11$iHSQXgmL3I4mPMVdCiK...me1Q.I8AZCK/4fcH.MwqdJ0hXSqa5CK', 'teacher');
SELECT ROW_COUNT();

INSERT INTO `users` (`Id`, `ContactEmail`, `CreatedAt`, `FullName`, `LoginId`, `MustChangePassword`, `PasswordHash`, `Role`)
VALUES (6, NULL, '2026-11-20 09:00:00.000000', 'Teacher Usman', 'usman@school.com', FALSE, '$2a$11$kl2OEPRuYn2EsnpUzv8bbeuzGlNUJyCiLAf6l49ujBC6ygeilXizW', 'teacher');
SELECT ROW_COUNT();


INSERT INTO `classes` (`Id`, `ClassTeacherId`, `GradeName`, `ResultsPublishedAt`, `Section`)
VALUES (1, 4, 'Class 8', NULL, 'A');
SELECT ROW_COUNT();

INSERT INTO `classes` (`Id`, `ClassTeacherId`, `GradeName`, `ResultsPublishedAt`, `Section`)
VALUES (2, 3, 'Class 8', NULL, 'B');
SELECT ROW_COUNT();

INSERT INTO `classes` (`Id`, `ClassTeacherId`, `GradeName`, `ResultsPublishedAt`, `Section`)
VALUES (3, 5, 'Class 9', NULL, 'A');
SELECT ROW_COUNT();

INSERT INTO `classes` (`Id`, `ClassTeacherId`, `GradeName`, `ResultsPublishedAt`, `Section`)
VALUES (4, 6, 'Class 9', NULL, 'B');
SELECT ROW_COUNT();


INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (21, 5, 'Areeba', '01');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (22, 5, 'Junaid', '02');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (23, 5, 'Kinza', '03');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (24, 5, 'Rehan', '04');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (25, 5, 'Noor', '05');
SELECT ROW_COUNT();


INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (21, 5, 1, NULL, 4);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (22, 5, 2, NULL, 5);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (23, 5, 3, NULL, 6);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (24, 5, 4, NULL, 3);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (25, 5, 5, NULL, 3);
SELECT ROW_COUNT();


INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (1, 1, 'Ali', '01');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (2, 1, 'Ayesha', '02');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (3, 1, 'Hamza', '03');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (4, 1, 'Hira', '04');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (5, 1, 'Omar', '05');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (6, 2, 'Sarah', '01');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (7, 2, 'Ahmed', '02');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (8, 2, 'Zain', '03');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (9, 2, 'Fatima', '04');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (10, 2, 'Bilal', '05');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (11, 3, 'Saad', '01');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (12, 3, 'Zara', '02');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (13, 3, 'Usama', '03');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (14, 3, 'Mahnoor', '04');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (15, 3, 'Fahad', '05');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (16, 4, 'Danish', '01');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (17, 4, 'Iqra', '02');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (18, 4, 'Hassan', '03');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (19, 4, 'Sana', '04');
SELECT ROW_COUNT();

INSERT INTO `students` (`Id`, `ClassId`, `FullName`, `RollNo`)
VALUES (20, 4, 'Talha', '05');
SELECT ROW_COUNT();


INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (1, 1, 1, NULL, 4);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (2, 1, 2, NULL, 5);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (3, 1, 3, NULL, 6);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (4, 1, 4, '2026-11-20 10:30:00.000000', 3);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (5, 1, 5, NULL, 3);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (6, 2, 1, '2026-11-20 10:30:00.000000', 4);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (7, 2, 2, '2026-11-20 10:30:00.000000', 5);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (8, 2, 3, NULL, 6);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (9, 2, 4, NULL, 3);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (10, 2, 5, '2026-11-20 10:30:00.000000', 3);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (11, 3, 1, '2026-11-20 10:30:00.000000', 4);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (12, 3, 2, '2026-11-20 10:30:00.000000', 5);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (13, 3, 3, '2026-11-20 10:30:00.000000', 6);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (14, 3, 4, '2026-11-20 10:30:00.000000', 3);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (15, 3, 5, '2026-11-20 10:30:00.000000', 3);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (16, 4, 1, NULL, 4);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (17, 4, 2, NULL, 5);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (18, 4, 3, NULL, 6);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (19, 4, 4, NULL, 3);
SELECT ROW_COUNT();

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `SubmittedAt`, `TeacherId`)
VALUES (20, 4, 5, NULL, 3);
SELECT ROW_COUNT();


INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (1, 3, 50, 1, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (2, 3, 44, 2, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (3, 3, 57, 3, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (4, 3, 39, 4, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (5, 3, 48, 5, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (6, 4, 85, 6, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (7, 4, 78, 7, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (8, 4, 66, 8, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (9, 4, 91, 9, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (10, 4, 72, 10, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (11, 5, 92, 6, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (12, 5, 81, 7, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (13, 5, 59, 8, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (14, 5, 88, 9, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (15, 5, 70, 10, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (16, 3, 52, 6, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (17, 3, 47, 7, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (18, 3, 40, 8, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (19, 3, 58, 9, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (20, 3, 45, 10, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (21, 6, 55, 6, 3, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (22, 3, 48, 6, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (23, 4, 74, 11, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (24, 4, 88, 12, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (25, 4, 63, 13, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (26, 4, 95, 14, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (27, 4, 58, 15, 1, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (28, 5, 67, 11, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (29, 5, 90, 12, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (30, 5, 72, 13, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (31, 5, 84, 14, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (32, 5, 49, 15, 2, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (33, 6, 41, 11, 3, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (34, 6, 53, 12, 3, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (35, 6, 38, 13, 3, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (36, 6, 57, 14, 3, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (37, 6, 46, 15, 3, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (38, 3, 44, 11, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (39, 3, 56, 12, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (40, 3, 35, 13, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (41, 3, 51, 14, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (42, 3, 42, 15, 4, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (43, 3, 49, 11, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (44, 3, 58, 12, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (45, 3, 43, 13, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (46, 3, 54, 14, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();

INSERT INTO `marks` (`Id`, `EnteredById`, `Obtained`, `StudentId`, `SubjectId`, `UpdatedAt`)
VALUES (47, 3, 37, 15, 5, '2026-11-20 10:30:00.000000');
SELECT ROW_COUNT();


CREATE UNIQUE INDEX `IX_classes_ClassTeacherId` ON `classes` (`ClassTeacherId`);

CREATE UNIQUE INDEX `IX_classes_GradeName_Section` ON `classes` (`GradeName`, `Section`);

CREATE INDEX `IX_marks_EnteredById` ON `marks` (`EnteredById`);

CREATE UNIQUE INDEX `IX_marks_StudentId_SubjectId` ON `marks` (`StudentId`, `SubjectId`);

CREATE INDEX `IX_marks_SubjectId` ON `marks` (`SubjectId`);

CREATE UNIQUE INDEX `IX_students_ClassId_RollNo` ON `students` (`ClassId`, `RollNo`);

CREATE UNIQUE INDEX `IX_subjects_Name` ON `subjects` (`Name`);

CREATE UNIQUE INDEX `IX_teaching_assignments_ClassId_SubjectId` ON `teaching_assignments` (`ClassId`, `SubjectId`);

CREATE INDEX `IX_teaching_assignments_SubjectId` ON `teaching_assignments` (`SubjectId`);

CREATE INDEX `IX_teaching_assignments_TeacherId` ON `teaching_assignments` (`TeacherId`);

CREATE UNIQUE INDEX `IX_users_LoginId` ON `users` (`LoginId`);

INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
VALUES ('20261124031825_InitialCreate', '10.0.12');

COMMIT;

