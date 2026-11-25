START TRANSACTION;
CREATE TABLE `student_removals` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `ClassId` int NOT NULL,
    `StudentName` varchar(100) NOT NULL,
    `RollNo` varchar(10) NOT NULL,
    `RemovedById` int NOT NULL,
    `RemovedByRole` varchar(20) NOT NULL,
    `RemovedAt` datetime(6) NOT NULL,
    PRIMARY KEY (`Id`),
    CONSTRAINT `FK_student_removals_classes_ClassId` FOREIGN KEY (`ClassId`) REFERENCES `classes` (`Id`) ON DELETE RESTRICT,
    CONSTRAINT `FK_student_removals_users_RemovedById` FOREIGN KEY (`RemovedById`) REFERENCES `users` (`Id`) ON DELETE RESTRICT
);

CREATE INDEX `IX_student_removals_ClassId` ON `student_removals` (`ClassId`);

CREATE INDEX `IX_student_removals_RemovedById` ON `student_removals` (`RemovedById`);

INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
VALUES ('20261125192922_AddStudentRemovals', '10.0.12');

COMMIT;

