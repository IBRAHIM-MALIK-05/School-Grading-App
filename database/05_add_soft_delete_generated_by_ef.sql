START TRANSACTION;
ALTER TABLE `users` ADD `isDeleted` tinyint(1) NOT NULL DEFAULT FALSE;

ALTER TABLE `classes` ADD `isDeleted` tinyint(1) NOT NULL DEFAULT FALSE;

UPDATE `classes` SET `isDeleted` = FALSE
WHERE `Id` = 1;
SELECT ROW_COUNT();


UPDATE `classes` SET `isDeleted` = FALSE
WHERE `Id` = 2;
SELECT ROW_COUNT();


UPDATE `classes` SET `isDeleted` = FALSE
WHERE `Id` = 3;
SELECT ROW_COUNT();


UPDATE `classes` SET `isDeleted` = FALSE
WHERE `Id` = 4;
SELECT ROW_COUNT();


UPDATE `classes` SET `isDeleted` = FALSE
WHERE `Id` = 5;
SELECT ROW_COUNT();


UPDATE `users` SET `isDeleted` = FALSE
WHERE `Id` = 1;
SELECT ROW_COUNT();


UPDATE `users` SET `isDeleted` = FALSE
WHERE `Id` = 2;
SELECT ROW_COUNT();


UPDATE `users` SET `isDeleted` = FALSE
WHERE `Id` = 3;
SELECT ROW_COUNT();


UPDATE `users` SET `isDeleted` = FALSE
WHERE `Id` = 4;
SELECT ROW_COUNT();


UPDATE `users` SET `isDeleted` = FALSE
WHERE `Id` = 5;
SELECT ROW_COUNT();


UPDATE `users` SET `isDeleted` = FALSE
WHERE `Id` = 6;
SELECT ROW_COUNT();


INSERT INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
VALUES ('20261125213126_AddSoftDelete', '10.0.12');

COMMIT;

