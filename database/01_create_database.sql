-- 01_create_database.sql
-- Same as phpMyAdmin > Databases > "Create database" with the collation
-- utf8mb4_general_ci (this is what was done through the UI in Milestone 2).
-- utf8mb4 = full Unicode (Urdu names, emoji), general_ci = case-insensitive
-- comparison, and it is supported by both XAMPP (MariaDB 10.4) and
-- Azure Database for MySQL 8, so the later export/import works cleanly.
--
-- The TABLES are NOT created here: the ASP.NET Core API creates them with
-- Entity Framework Core code-first migrations (Milestone 4, Update-Database).

CREATE DATABASE IF NOT EXISTS school_grading
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
