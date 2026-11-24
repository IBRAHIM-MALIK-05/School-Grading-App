-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 24, 2026 at 11:57 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `school_grading`
--

-- --------------------------------------------------------

--
-- Table structure for table `classes`
--

DROP TABLE IF EXISTS `classes`;
CREATE TABLE IF NOT EXISTS `classes` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `GradeName` varchar(20) NOT NULL,
  `Section` varchar(5) NOT NULL,
  `ClassTeacherId` int(11) DEFAULT NULL,
  `ResultsPublishedAt` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `IX_classes_GradeName_Section` (`GradeName`,`Section`),
  UNIQUE KEY `IX_classes_ClassTeacherId` (`ClassTeacherId`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `classes`
--

INSERT INTO `classes` (`Id`, `GradeName`, `Section`, `ClassTeacherId`, `ResultsPublishedAt`) VALUES
(1, 'Class 8', 'A', 4, NULL),
(2, 'Class 8', 'B', 3, NULL),
(3, 'Class 9', 'A', 5, NULL),
(4, 'Class 9', 'B', 6, NULL),
(5, 'Class 9', 'C', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `marks`
--

DROP TABLE IF EXISTS `marks`;
CREATE TABLE IF NOT EXISTS `marks` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `StudentId` int(11) NOT NULL,
  `SubjectId` int(11) NOT NULL,
  `Obtained` int(11) NOT NULL,
  `EnteredById` int(11) NOT NULL,
  `UpdatedAt` datetime(6) NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `IX_marks_StudentId_SubjectId` (`StudentId`,`SubjectId`),
  KEY `IX_marks_EnteredById` (`EnteredById`),
  KEY `IX_marks_SubjectId` (`SubjectId`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `marks`
--

INSERT INTO `marks` (`Id`, `StudentId`, `SubjectId`, `Obtained`, `EnteredById`, `UpdatedAt`) VALUES
(1, 1, 4, 50, 3, '2026-11-20 10:30:00.000000'),
(2, 2, 4, 44, 3, '2026-11-20 10:30:00.000000'),
(3, 3, 4, 57, 3, '2026-11-20 10:30:00.000000'),
(4, 4, 4, 39, 3, '2026-11-20 10:30:00.000000'),
(5, 5, 4, 48, 3, '2026-11-20 10:30:00.000000'),
(6, 6, 1, 85, 4, '2026-11-20 10:30:00.000000'),
(7, 7, 1, 78, 4, '2026-11-20 10:30:00.000000'),
(8, 8, 1, 66, 4, '2026-11-20 10:30:00.000000'),
(9, 9, 1, 91, 4, '2026-11-20 10:30:00.000000'),
(10, 10, 1, 72, 4, '2026-11-20 10:30:00.000000'),
(11, 6, 2, 92, 5, '2026-11-20 10:30:00.000000'),
(12, 7, 2, 81, 5, '2026-11-20 10:30:00.000000'),
(13, 8, 2, 59, 5, '2026-11-20 10:30:00.000000'),
(14, 9, 2, 88, 5, '2026-11-20 10:30:00.000000'),
(15, 10, 2, 70, 5, '2026-11-20 10:30:00.000000'),
(16, 6, 5, 52, 3, '2026-11-20 10:30:00.000000'),
(17, 7, 5, 47, 3, '2026-11-20 10:30:00.000000'),
(18, 8, 5, 40, 3, '2026-11-20 10:30:00.000000'),
(19, 9, 5, 58, 3, '2026-11-20 10:30:00.000000'),
(20, 10, 5, 45, 3, '2026-11-20 10:30:00.000000'),
(21, 6, 3, 55, 6, '2026-11-20 10:30:00.000000'),
(22, 6, 4, 48, 3, '2026-11-20 10:30:00.000000'),
(23, 11, 1, 74, 4, '2026-11-20 10:30:00.000000'),
(24, 12, 1, 88, 4, '2026-11-20 10:30:00.000000'),
(25, 13, 1, 63, 4, '2026-11-20 10:30:00.000000'),
(26, 14, 1, 95, 4, '2026-11-20 10:30:00.000000'),
(27, 15, 1, 58, 4, '2026-11-20 10:30:00.000000'),
(28, 11, 2, 67, 5, '2026-11-20 10:30:00.000000'),
(29, 12, 2, 90, 5, '2026-11-20 10:30:00.000000'),
(30, 13, 2, 72, 5, '2026-11-20 10:30:00.000000'),
(31, 14, 2, 84, 5, '2026-11-20 10:30:00.000000'),
(32, 15, 2, 49, 5, '2026-11-20 10:30:00.000000'),
(33, 11, 3, 41, 6, '2026-11-20 10:30:00.000000'),
(34, 12, 3, 53, 6, '2026-11-20 10:30:00.000000'),
(35, 13, 3, 38, 6, '2026-11-20 10:30:00.000000'),
(36, 14, 3, 57, 6, '2026-11-20 10:30:00.000000'),
(37, 15, 3, 46, 6, '2026-11-20 10:30:00.000000'),
(38, 11, 4, 44, 3, '2026-11-20 10:30:00.000000'),
(39, 12, 4, 56, 3, '2026-11-20 10:30:00.000000'),
(40, 13, 4, 35, 3, '2026-11-20 10:30:00.000000'),
(41, 14, 4, 51, 3, '2026-11-20 10:30:00.000000'),
(42, 15, 4, 42, 3, '2026-11-20 10:30:00.000000'),
(43, 11, 5, 49, 3, '2026-11-20 10:30:00.000000'),
(44, 12, 5, 58, 3, '2026-11-20 10:30:00.000000'),
(45, 13, 5, 43, 3, '2026-11-20 10:30:00.000000'),
(46, 14, 5, 54, 3, '2026-11-20 10:30:00.000000'),
(47, 15, 5, 37, 3, '2026-11-20 10:30:00.000000');

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

DROP TABLE IF EXISTS `students`;
CREATE TABLE IF NOT EXISTS `students` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `FullName` varchar(100) NOT NULL,
  `RollNo` varchar(10) NOT NULL,
  `ClassId` int(11) NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `IX_students_ClassId_RollNo` (`ClassId`,`RollNo`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`Id`, `FullName`, `RollNo`, `ClassId`) VALUES
(1, 'Ali', '01', 1),
(2, 'Ayesha', '02', 1),
(3, 'Hamza', '03', 1),
(4, 'Hira', '04', 1),
(5, 'Omar', '05', 1),
(6, 'Sarah', '01', 2),
(7, 'Ahmed', '02', 2),
(8, 'Zain', '03', 2),
(9, 'Fatima', '04', 2),
(10, 'Bilal', '05', 2),
(11, 'Saad', '01', 3),
(12, 'Zara', '02', 3),
(13, 'Usama', '03', 3),
(14, 'Mahnoor', '04', 3),
(15, 'Fahad', '05', 3),
(16, 'Danish', '01', 4),
(17, 'Iqra', '02', 4),
(18, 'Hassan', '03', 4),
(19, 'Sana', '04', 4),
(20, 'Talha', '05', 4),
(21, 'Areeba', '01', 5),
(22, 'Junaid', '02', 5),
(23, 'Kinza', '03', 5),
(24, 'Rehan', '04', 5),
(25, 'Noor', '05', 5);

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

DROP TABLE IF EXISTS `subjects`;
CREATE TABLE IF NOT EXISTS `subjects` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(50) NOT NULL,
  `MaxMarks` int(11) NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `IX_subjects_Name` (`Name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`Id`, `Name`, `MaxMarks`) VALUES
(1, 'English', 100),
(2, 'Mathematics', 100),
(3, 'Physics', 60),
(4, 'Chemistry', 60),
(5, 'Biology', 60);

-- --------------------------------------------------------

--
-- Table structure for table `teaching_assignments`
--

DROP TABLE IF EXISTS `teaching_assignments`;
CREATE TABLE IF NOT EXISTS `teaching_assignments` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `ClassId` int(11) NOT NULL,
  `SubjectId` int(11) NOT NULL,
  `TeacherId` int(11) NOT NULL,
  `SubmittedAt` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `IX_teaching_assignments_ClassId_SubjectId` (`ClassId`,`SubjectId`),
  KEY `IX_teaching_assignments_SubjectId` (`SubjectId`),
  KEY `IX_teaching_assignments_TeacherId` (`TeacherId`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `teaching_assignments`
--

INSERT INTO `teaching_assignments` (`Id`, `ClassId`, `SubjectId`, `TeacherId`, `SubmittedAt`) VALUES
(1, 1, 1, 4, NULL),
(2, 1, 2, 5, NULL),
(3, 1, 3, 6, NULL),
(4, 1, 4, 3, '2026-11-20 10:30:00.000000'),
(5, 1, 5, 3, NULL),
(6, 2, 1, 4, '2026-11-20 10:30:00.000000'),
(7, 2, 2, 5, '2026-11-20 10:30:00.000000'),
(8, 2, 3, 6, NULL),
(9, 2, 4, 3, NULL),
(10, 2, 5, 3, '2026-11-20 10:30:00.000000'),
(11, 3, 1, 4, '2026-11-20 10:30:00.000000'),
(12, 3, 2, 5, '2026-11-20 10:30:00.000000'),
(13, 3, 3, 6, '2026-11-20 10:30:00.000000'),
(14, 3, 4, 3, '2026-11-20 10:30:00.000000'),
(15, 3, 5, 3, '2026-11-20 10:30:00.000000'),
(16, 4, 1, 4, NULL),
(17, 4, 2, 5, NULL),
(18, 4, 3, 6, NULL),
(19, 4, 4, 3, NULL),
(20, 4, 5, 3, NULL),
(21, 5, 1, 4, NULL),
(22, 5, 2, 5, NULL),
(23, 5, 3, 6, NULL),
(24, 5, 4, 3, NULL),
(25, 5, 5, 3, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `FullName` varchar(100) NOT NULL,
  `LoginId` varchar(100) NOT NULL,
  `ContactEmail` varchar(150) DEFAULT NULL,
  `PasswordHash` varchar(100) NOT NULL,
  `Role` varchar(20) NOT NULL,
  `MustChangePassword` tinyint(1) NOT NULL,
  `CreatedAt` datetime(6) NOT NULL,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `IX_users_LoginId` (`LoginId`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`Id`, `FullName`, `LoginId`, `ContactEmail`, `PasswordHash`, `Role`, `MustChangePassword`, `CreatedAt`) VALUES
(1, 'School Admin', 'admin@school.com', NULL, '$2a$11$c6gJO2BSfKjGK2cigDfJZOnxFT6ddgxsJnwSCAYt2VHHGDpaTrTk2', 'admin', 0, '2026-11-20 09:00:00.000000'),
(2, 'VP Sarah', 'vp@school.com', NULL, '$2a$11$knbs2jFie66WoIHXYKVkOetGaC0bkXmUDHQmjGEIDfPLqP2D9rREq', 'vp', 0, '2026-11-20 09:00:00.000000'),
(3, 'Teacher Sania', 'sania@school.com', NULL, '$2a$11$zUYQ3hSJRte1VA7nbAlzwO0h9woXmWqkT0LuUm2mVhfYVeCCWoWfi', 'teacher', 0, '2026-11-20 09:00:00.000000'),
(4, 'Teacher Ahsan', 'ahsan@school.com', NULL, '$2a$11$PvGvQ3bx/UDjVC9CcTBFF.POtBi5GnNJ0HOyAt4fhTsvU1IDEzEoa', 'teacher', 0, '2026-11-20 09:00:00.000000'),
(5, 'Teacher Maryam', 'maryam@school.com', NULL, '$2a$11$iHSQXgmL3I4mPMVdCiK...me1Q.I8AZCK/4fcH.MwqdJ0hXSqa5CK', 'teacher', 0, '2026-11-20 09:00:00.000000'),
(6, 'Teacher Usman', 'usman@school.com', NULL, '$2a$11$kl2OEPRuYn2EsnpUzv8bbeuzGlNUJyCiLAf6l49ujBC6ygeilXizW', 'teacher', 0, '2026-11-20 09:00:00.000000');

-- --------------------------------------------------------

--
-- Table structure for table `__efmigrationshistory`
--

DROP TABLE IF EXISTS `__efmigrationshistory`;
CREATE TABLE IF NOT EXISTS `__efmigrationshistory` (
  `MigrationId` varchar(150) NOT NULL,
  `ProductVersion` varchar(32) NOT NULL,
  PRIMARY KEY (`MigrationId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `__efmigrationshistory`
--

INSERT INTO `__efmigrationshistory` (`MigrationId`, `ProductVersion`) VALUES
('20261124031825_InitialCreate', '10.0.12');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `classes`
--
ALTER TABLE `classes`
  ADD CONSTRAINT `FK_classes_users_ClassTeacherId` FOREIGN KEY (`ClassTeacherId`) REFERENCES `users` (`Id`) ON DELETE SET NULL;

--
-- Constraints for table `marks`
--
ALTER TABLE `marks`
  ADD CONSTRAINT `FK_marks_students_StudentId` FOREIGN KEY (`StudentId`) REFERENCES `students` (`Id`) ON DELETE CASCADE,
  ADD CONSTRAINT `FK_marks_subjects_SubjectId` FOREIGN KEY (`SubjectId`) REFERENCES `subjects` (`Id`),
  ADD CONSTRAINT `FK_marks_users_EnteredById` FOREIGN KEY (`EnteredById`) REFERENCES `users` (`Id`);

--
-- Constraints for table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `FK_students_classes_ClassId` FOREIGN KEY (`ClassId`) REFERENCES `classes` (`Id`);

--
-- Constraints for table `teaching_assignments`
--
ALTER TABLE `teaching_assignments`
  ADD CONSTRAINT `FK_teaching_assignments_classes_ClassId` FOREIGN KEY (`ClassId`) REFERENCES `classes` (`Id`),
  ADD CONSTRAINT `FK_teaching_assignments_subjects_SubjectId` FOREIGN KEY (`SubjectId`) REFERENCES `subjects` (`Id`),
  ADD CONSTRAINT `FK_teaching_assignments_users_TeacherId` FOREIGN KEY (`TeacherId`) REFERENCES `users` (`Id`);
SET FOREIGN_KEY_CHECKS=1;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
