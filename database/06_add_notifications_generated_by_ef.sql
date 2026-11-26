START TRANSACTION;
CREATE TABLE `notifications` (
    `Id` int NOT NULL AUTO_INCREMENT,
    `RecipientUserId` int NOT NULL,
    `SenderUserId` int NULL,
    `Type` varchar(40) NOT NULL,
    `Title` varchar(150) NOT NULL,
    `Message` varchar(1000) NOT NULL,
    `IsUrgent` tinyint(1) NOT NULL,
    `IsRead` tinyint(1) NOT NULL DEFAULT FALSE,
    `CreatedAt` datetime(6) NOT NULL,
    `NotificationDate` date NOT NULL,
    `AssignmentId` int NULL,
    PRIMARY KEY (`Id`),
    CONSTRAINT `FK_notifications_teaching_assignments_AssignmentId` FOREIGN KEY (`AssignmentId`) REFERENCES `teaching_assignments` (`Id`) ON DELETE SET NULL,
    CONSTRAINT `FK_notifications_users_RecipientUserId` FOREIGN KEY (`RecipientUserId`) REFERENCES `users` (`Id`) ON DELETE CASCADE,
    CONSTRAINT `FK_notifications_users_SenderUserId` FOREIGN KEY (`SenderUserId`) REFERENCES `users` (`Id`) ON DELETE SET NULL
);

CREATE TABLE `school_settings` (
    `Id` int NOT NULL,
    `ResultDate` date NULL,
    `UpdatedByUserId` int NULL,
    `UpdatedAt` datetime(6) NULL,
    PRIMARY KEY (`Id`),
    CONSTRAINT `FK_school_settings_users_UpdatedByUserId` FOREIGN KEY (`UpdatedByUserId`) REFERENCES `users` (`Id`) ON DELETE SET NULL
);

INSERT INTO `school_settings` (`Id`, `ResultDate`, `UpdatedAt`, `UpdatedByUserId`)
VALUES (1, NULL, NULL, NULL);
SELECT ROW_COUNT();


CREATE INDEX `IX_notifications_AssignmentId` ON `notifications` (`AssignmentId`);

CREATE INDEX `IX_notifications_RecipientUserId_NotificationDate_Type` ON `notifications` (`RecipientUserId`, `NotificationDate`, `Type`);

CREATE INDEX `IX_notifications_SenderUserId` ON `notifications` (`SenderUserId`);

CREATE INDEX `IX_school_settings_UpdatedByUserId` ON `school_settings` (`UpdatedByUserId`);

INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
VALUES ('20261126065741_AddNotifications', '10.0.12');

COMMIT;

