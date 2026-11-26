"""Milestone 3 (part 2): import the phpMyAdmin export into Azure Database for
MySQL Flexible Server and verify it against the local XAMPP database.

1. Fill in tools/azure/azure_mysql.local.json (created on first run, git-ignored):
     { "host": "<server>.mysql.database.azure.com", "user": "<admin user>", "password": "..." }
2. Run:
     tools\\.venv\\Scripts\\python -I tools\\azure\\import_to_azure.py
   Only reset the cloud data back to the demo data (no screenshots):
     tools\\.venv\\Scripts\\python -I tools\\azure\\import_to_azure.py --reset

The connection is encrypted (TLS) and the server certificate is checked.
Every step is printed and also saved as a screenshot (docs/screenshots/m3_*.png).
"""

import json
import sys
from pathlib import Path

import certifi
import pymysql
from pymysql.constants import CLIENT

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "screenshots"))
from text_image import render  # noqa: E402

CONFIG = Path(__file__).with_name("azure_mysql.local.json")
EXPORT_FILE = ROOT / "database" / "03_school_grading_export_for_azure.sql"
OUT = ROOT / "docs" / "screenshots"
DB = "school_grading"
TABLES = ["users", "subjects", "classes", "students", "teaching_assignments", "marks", "student_removals",
          "school_settings", "notifications"]


def load_config():
    if not CONFIG.exists():
        CONFIG.write_text(json.dumps(
            {"host": "<server-name>.mysql.database.azure.com", "user": "<admin-username>", "password": "<password>"},
            indent=2), encoding="utf-8")
        sys.exit(f"Created {CONFIG} - fill in host, user and password, then run again.")
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    if "<" in config["host"] or "<" in config["password"]:
        sys.exit(f"Please fill in {CONFIG} first.")
    return config


def connect_azure(config, database=None, multi=False):
    return pymysql.connect(
        host=config["host"], port=3306, user=config["user"], password=config["password"],
        database=database, charset="utf8mb4", autocommit=False,
        ssl={"ca": certifi.where()}, ssl_verify_cert=True, ssl_verify_identity=True,
        client_flag=CLIENT.MULTI_STATEMENTS if multi else 0, connect_timeout=20,
    )


def connect_local():
    return pymysql.connect(host="127.0.0.1", port=3306, user="root", password="",
                           database="school_grading", charset="utf8mb4")


def rows(cursor, sql):
    cursor.execute(sql)
    return cursor.fetchall()


def table_text(headers, data):
    """Simple text table for the terminal screenshots."""
    data = [["NULL" if v is None else str(v) for v in r] for r in data]
    widths = [max(len(h), *(len(r[i]) for r in data)) if data else len(h) for i, h in enumerate(headers)]
    line = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    out = [line, "| " + " | ".join(h.ljust(w) for h, w in zip(headers, widths)) + " |", line]
    out += ["| " + " | ".join(v.ljust(w) for v, w in zip(r, widths)) + " |" for r in data]
    out.append(line)
    return out


def step_connect(config):
    log = [f"PS> python tools\\azure\\import_to_azure.py", "",
           f"# Connecting to Azure Database for MySQL (TLS, certificate verified)",
           f"host : {config['host']}", f"user : {config['user']}", ""]
    with connect_azure(config) as conn, conn.cursor() as cur:
        version = rows(cur, "SELECT VERSION()")[0][0]
        cipher = rows(cur, "SHOW SESSION STATUS LIKE 'Ssl_version'")[0][1]
        settings = rows(cur, "SHOW VARIABLES WHERE Variable_name IN ("
                             "'require_secure_transport','lower_case_table_names',"
                             "'sql_require_primary_key','sql_generate_invisible_primary_key',"
                             "'character_set_server','time_zone')")
        log += [f"Connected. MySQL version {version}, encrypted with {cipher}", ""]
        log += table_text(["Server setting", "Value"], settings)
        # create the empty database (same name + collation as in XAMPP)
        cur.execute(f"CREATE DATABASE IF NOT EXISTS {DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci")
        conn.commit()
        log += ["", f"CREATE DATABASE IF NOT EXISTS {DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;",
                "Query OK"]
    return log


def step_import(config):
    sql = EXPORT_FILE.read_text(encoding="utf-8")
    log = [f"# Importing {EXPORT_FILE.name} ({len(sql.encode())} bytes) into {DB} on Azure", ""]
    with connect_azure(config, DB, multi=True) as conn, conn.cursor() as cur:
        cur.execute(sql)
        statements = 1
        while cur.nextset():
            statements += 1
        conn.commit()
        log += [f"{statements} statements executed - import committed.", ""]
        tables = rows(cur, "SHOW TABLES")
        log += table_text([f"Tables_in_{DB} (Azure)"], tables)
    return log


def step_compare(config):
    log = ["# Row counts: local XAMPP (MariaDB) vs Azure MySQL", ""]
    data = []
    all_match = True
    with connect_local() as local, local.cursor() as lc, \
            connect_azure(config, DB) as azure, azure.cursor() as ac:
        for t in TABLES:
            local_n = rows(lc, f"SELECT COUNT(*) FROM {t}")[0][0]
            azure_n = rows(ac, f"SELECT COUNT(*) FROM {t}")[0][0]
            ok = local_n == azure_n
            all_match &= ok
            data.append([t, local_n, azure_n, "OK" if ok else "DIFFERENT"])
        fk = rows(ac, "SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS "
                      f"WHERE CONSTRAINT_SCHEMA = '{DB}'")[0][0]
        pk = rows(ac, "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS "
                      f"WHERE TABLE_SCHEMA = '{DB}' AND CONSTRAINT_TYPE = 'PRIMARY KEY'")[0][0]
        users = rows(ac, "SELECT Id, FullName, LoginId, Role, MustChangePassword FROM users ORDER BY Id")
    log += table_text(["Table", "Local rows", "Azure rows", "Check"], data)
    log += ["", f"Primary keys on Azure: {pk}   Foreign keys on Azure: {fk}",
            "ALL TABLES MATCH" if all_match else "!! SOME TABLES DIFFER !!", "",
            "# SELECT Id, FullName, LoginId, Role, MustChangePassword FROM users;  (Azure)", ""]
    log += table_text(["Id", "FullName", "LoginId", "Role", "MustChangePassword"], users)
    if not all_match:
        raise SystemExit("\n".join(log))
    return log


def step_join(config):
    query = (
        "SELECT CONCAT(c.GradeName, ' - ', c.Section) AS Class, s.Name AS Subject,\n"
        "       u.FullName AS Teacher, COUNT(m.Id) AS MarksEntered,\n"
        "       IF(ta.SubmittedAt IS NULL, 'pending', 'submitted') AS Status\n"
        "FROM teaching_assignments ta\n"
        "JOIN classes c  ON c.Id = ta.ClassId\n"
        "JOIN subjects s ON s.Id = ta.SubjectId\n"
        "JOIN users u    ON u.Id = ta.TeacherId\n"
        "LEFT JOIN students st ON st.ClassId = ta.ClassId\n"
        "LEFT JOIN marks m ON m.StudentId = st.Id AND m.SubjectId = ta.SubjectId\n"
        "WHERE c.GradeName = 'Class 8' AND c.Section = 'B'\n"
        "GROUP BY ta.Id ORDER BY s.Id;"
    )
    with connect_azure(config, DB) as conn, conn.cursor() as cur:
        data = rows(cur, query)
    log = ["# JOIN query on Azure: submission status of Class 8 - B", ""]
    log += query.splitlines() + [""]
    log += table_text(["Class", "Subject", "Teacher", "MarksEntered", "Status"], data)
    return log


def step_write_test(config):
    """INSERT + UPDATE on the cloud database, then DELETE so the demo data stays clean."""
    log = ["# Write test on Azure (INSERT -> UPDATE -> DELETE, demo data left unchanged)", ""]
    with connect_azure(config, DB) as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO students (FullName, RollNo, ClassId) VALUES ('Cloud Test', '99', 5)")
        new_id = cur.lastrowid
        conn.commit()
        log += ["INSERT INTO students (FullName, RollNo, ClassId) VALUES ('Cloud Test', '99', 5);",
                f"Query OK, 1 row affected (new Id = {new_id})", ""]
        cur.execute("UPDATE students SET FullName = 'Cloud Test (updated)' WHERE Id = %s", (new_id,))
        conn.commit()
        log += [f"UPDATE students SET FullName = 'Cloud Test (updated)' WHERE Id = {new_id};",
                "Query OK, 1 row affected", ""]
        data = rows(cur, f"SELECT Id, FullName, RollNo, ClassId FROM students WHERE Id = {new_id}")
        log += [f"SELECT Id, FullName, RollNo, ClassId FROM students WHERE Id = {new_id};"]
        log += table_text(["Id", "FullName", "RollNo", "ClassId"], data) + [""]
        cur.execute("DELETE FROM students WHERE Id = %s", (new_id,))
        # put the AUTO_INCREMENT counter back so the cloud copy matches the local one
        cur.execute("ALTER TABLE students AUTO_INCREMENT = 26")
        conn.commit()
        count = rows(cur, "SELECT COUNT(*) FROM students")[0][0]
        log += [f"DELETE FROM students WHERE Id = {new_id};", "Query OK, 1 row affected",
                f"students now has {count} rows (back to the demo data)"]
    return log


def main():
    config = load_config()
    if "--reset" in sys.argv:
        # Put the cloud database back to the clean demo data (e.g. after Postman / app tests)
        step_import(config)
        print("\n".join(step_compare(config)[:18]))
        print("Azure database reset to the clean demo data.")
        return
    OUT.mkdir(parents=True, exist_ok=True)
    steps = [
        (step_connect, "m3_06_azure_connect_tls.png", "Connect to Azure MySQL"),
        (step_import, "m3_07_azure_import.png", "Import into Azure MySQL"),
        (step_compare, "m3_08_azure_verify_rows.png", "Verify: local vs cloud"),
        (step_join, "m3_09_azure_join_query.png", "JOIN query on Azure"),
        (step_write_test, "m3_10_azure_insert_update.png", "INSERT / UPDATE on Azure"),
    ]
    for step, image, title in steps:
        log = step(config)
        print("\n".join(log), "\n")
        render(log, OUT / image, title=title, font_size=15)
        print("saved", image, "\n")


if __name__ == "__main__":
    main()
