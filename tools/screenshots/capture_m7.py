"""Milestone 7 screenshots: the Flutter app running on the REAL API + MySQL.

Needs: XAMPP MySQL on, the API running on http://localhost:5080
(dotnet run --launch-profile http), and the web build served on port 8765:
    python -m http.server 8765 -d mobile\\build\\web
Then:
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m7.py

At the end the script STOPS the API on purpose to capture the
"cannot connect to the server" error screens.
"""

import re
import subprocess
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).parent))
from flutter_driver import FlutterApp, run  # noqa: E402
from text_image import render  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
URL = "http://127.0.0.1:8765/"
PMA = "http://localhost/phpmyadmin/index.php"


def login(app: FlutterApp, login_id: str, password: str, expect: str):
    app.type_into("Login ID", login_id)
    app.type_into("Password", password)
    app.tap("Login", last=True)
    app.wait_text(expect)


def logout(app: FlutterApp):
    app.open_drawer()
    app.tap("Logout")
    app.wait_text("School Grading System")


def slow_network(app: FlutterApp, latency_ms: int):
    """Chrome DevTools network throttling, so the loading spinner is visible."""
    cdp = app.page.context.new_cdp_session(app.page)
    cdp.send("Network.enable")
    cdp.send("Network.emulateNetworkConditions", {
        "offline": False, "latency": latency_ms,
        "downloadThroughput": -1, "uploadThroughput": -1,
    })
    return cdp


def stop_api():
    """Really switch the API off (end the SchoolGradingApi.exe process)."""
    subprocess.run(["taskkill", "/IM", "SchoolGradingApi.exe", "/F"], check=False)
    print("API stopped")


def scenario(app: FlutterApp):
    # ---------------- Login against the API ----------------
    app.wait_text("School Grading System")
    app.shot("m7_01_login.png")

    app.type_into("Login ID", "sania@school.com")
    app.type_into("Password", "wrong")
    app.tap("Login", last=True)
    app.wait_text("Invalid Login ID or password")  # 401 message from the API
    app.shot("m7_02_login_error_401.png")

    # ---------------- Admin ----------------
    login(app, "admin@school.com", "123", "Welcome School Admin")
    app.wait_text("ahsan@school.com")
    app.shot("m7_03_admin_users_from_mysql.png")

    app.open_drawer()
    app.tap("Create Account")
    app.wait_text("Full name")
    app.type_into("Full name", "Ali Raza")
    app.type_into("Gmail", "ali.raza@gmail.com")
    app.tap("Not a class teacher")
    app.pause(500)
    app.tap("Class 9 - C")
    app.pause(500)
    app.scroll(700)
    app.tap("Class 9 - C", last=True)
    app.pause(500)
    app.tap("Physics (out of 60)")
    app.pause(300)
    app.scroll(300)
    app.shot("m7_04_create_account_form.png")

    app.tap("Create account", last=True)
    app.wait_text("Account created")  # POST /api/auth/register -> 201
    app.shot("m7_05_credentials_from_api.png")

    app.tap("Copy")
    app.pause(500)
    match = re.search(r"Temporary password: (\S+)", app.clipboard_text())
    if not match:
        raise RuntimeError("could not read the temporary password from the clipboard")
    ali_password = match.group(1)
    print("Ali temp password:", ali_password)
    app.pause(4500)
    app.tap("Done")
    app.wait_text("Welcome School Admin")
    app.scroll(1500)
    app.shot("m7_06_users_after_create.png")
    app.scroll(-1500)
    logout(app)

    # ---------------- New teacher: forced password change ----------------
    login(app, "ali@school.com", ali_password, "You are using a temporary password")
    app.shot("m7_07_forced_change_password.png")
    app.type_into("Temporary password", ali_password)
    app.type_into("New password", "NewPass123")
    app.type_into("Confirm new password", "NewPass123")
    app.tap("Save new password")
    app.wait_text("Physics • Out of 60")
    app.wait_gone("Password changed successfully", timeout=10000)
    app.shot("m7_08_new_teacher_dashboard.png")
    logout(app)

    # ---------------- Teacher Sania: upload marks ----------------
    login(app, "sania@school.com", "123", "Welcome Teacher Sania")
    app.shot("m7_09_teacher_dashboard.png")

    app.open_drawer()
    app.tap("My Subjects")
    app.pause(500)
    app.tap("Class 8 - B")  # Chemistry 8-B (only Sarah has a mark in MySQL)
    app.wait_text("Max marks: 60")
    app.shot("m7_10_marks_entry_from_api.png")

    for i, v in [(1, "40"), (2, "35"), (3, "52"), (4, "44")]:
        app.type_into_nth_input(i, v)
    app.tap("Submit", last=True)
    app.wait_text("Submit marks?")
    app.tap("Submit", last=True)
    app.wait_text("Welcome Teacher Sania")  # PUT /api/assignments/{id}/marks
    app.pause(300)
    app.shot("m7_11_marks_submitted.png")
    app.wait_gone("Marks submitted!", timeout=10000)

    # ---------------- Class Teacher: live tracker ----------------
    app.tap("Open my class")
    app.wait_text("Subject submissions")
    app.shot("m7_12_class_tracker_live.png")
    app.scroll(700)
    app.tap("Sarah")
    app.wait_text("Percentage")
    app.shot("m7_13_report_card_live.png")
    app.back()
    app.back()
    app.wait_text("Welcome Teacher Sania")

    # ---------------- Manage students (POST + DELETE) ----------------
    app.open_drawer()
    app.tap("Manage Students")
    app.wait_text("students in Class 8 - A")
    app.tap("Class 8 - A")
    app.pause(500)
    app.tap("Class 8 - B", last=True)
    app.wait_text("5 students in Class 8 - B")
    app.tap("Add student")
    app.wait_text("Add student to Class 8 - B")
    app.type_into("Student name", "Hamza Ali")
    app.type_into("Roll number", "6")
    app.tap("Add", last=True)
    app.wait_text("6 students in Class 8 - B")
    app.shot("m7_14_student_added.png")
    app.wait_gone("Hamza Ali added", timeout=10000)
    app.tap_label("Delete student", index=5)
    app.wait_text("Delete student?")
    app.tap("Delete", last=True)
    app.wait_text("5 students in Class 8 - B")
    app.shot("m7_15_student_deleted.png")
    app.back()
    logout(app)

    # ---------------- Maryam publishes 9-A ----------------
    login(app, "maryam@school.com", "123", "Welcome Teacher Maryam")
    app.tap("Open my class")
    app.wait_text("Ready to publish")
    app.scroll(2000)
    app.scroll(800)
    app.tap("Publish results")
    app.wait_text("Publish results?")
    app.tap("Publish", last=True)
    app.wait_text("Results published.")
    app.wait_gone("Results published.", timeout=10000)
    app.scroll(-2000)
    app.shot("m7_16_published.png")
    app.back()
    app.wait_text("Welcome Teacher Maryam")
    app.tap("Class 9 - A")
    app.wait_text("Marks are locked")
    app.shot("m7_17_marks_locked.png")
    app.back()
    logout(app)

    # ---------------- Principal / VP ----------------
    login(app, "vp@school.com", "123", "Class Grading Status")
    app.shot("m7_18_vp_dashboard_live.png")

    cdp = slow_network(app, 2500)
    app.tap_label("Refresh")
    app.pause(400)
    app.shot("m7_19_loading_spinner.png")
    app.wait_text("Class Grading Status", timeout=20000)
    cdp.send("Network.emulateNetworkConditions", {
        "offline": False, "latency": 0, "downloadThroughput": -1, "uploadThroughput": -1})

    # ---------------- API switched off ----------------
    stop_api()
    app.pause(1500)
    app.tap_label("Refresh")
    app.wait_text("Cannot connect to the server", timeout=30000)
    app.shot("m7_20_api_off_error_retry.png")

    logout(app)
    app.type_into("Login ID", "vp@school.com")
    app.type_into("Password", "123")
    app.tap("Login", last=True)
    app.wait_text("Cannot connect to the server", timeout=30000)
    app.shot("m7_21_login_api_off.png")


def database_shots():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = browser.new_page(viewport={"width": 1700, "height": 640})
        page.goto(f"{PMA}?route=/sql&db=school_grading&table=users&pos=0", wait_until="networkidle")
        page.wait_for_timeout(500)
        page.screenshot(path=str(OUT / "m7_22_db_users_after_app.png"))
        print("saved m7_22_db_users_after_app.png")

        page.set_viewport_size({"width": 1366, "height": 768})
        query = (
            "SELECT st.RollNo, st.FullName, m.Obtained, u.FullName AS EnteredBy, m.UpdatedAt,\n"
            "       ta.SubmittedAt AS ChemistrySubmittedAt\n"
            "FROM marks m\n"
            "JOIN students st ON st.Id = m.StudentId\n"
            "JOIN users u ON u.Id = m.EnteredById\n"
            "JOIN teaching_assignments ta ON ta.ClassId = st.ClassId AND ta.SubjectId = m.SubjectId\n"
            "WHERE st.ClassId = 2 AND m.SubjectId = 4\n"
            "ORDER BY st.RollNo;"
        )
        page.goto(f"{PMA}?route=/database/sql&db=school_grading", wait_until="networkidle")
        page.evaluate("q => document.querySelector('#sqlqueryform .CodeMirror').CodeMirror.setValue(q)", query)
        page.wait_for_timeout(300)
        page.click("#button_submit_query")
        page.wait_for_selector("text=Showing rows", timeout=15000)
        page.wait_for_timeout(500)
        page.screenshot(path=str(OUT / "m7_23_db_marks_after_app.png"))
        print("saved m7_23_db_marks_after_app.png")

        page.goto(f"{PMA}?route=/sql&db=school_grading&table=classes&pos=0", wait_until="networkidle")
        page.wait_for_timeout(500)
        page.screenshot(path=str(OUT / "m7_24_db_classes_published.png"))
        print("saved m7_24_db_classes_published.png")
        browser.close()


def code_shot():
    services = ROOT / "mobile" / "lib" / "services"
    lines = ["# lib/services/current_service.dart  (the ONE line that switches mock -> API)", ""]
    lines += (services / "current_service.dart").read_text(encoding="utf-8").splitlines()
    lines += ["", "# lib/services/api_config.dart  (the ONE line that sets the server address)", ""]
    lines += (services / "api_config.dart").read_text(encoding="utf-8").splitlines()
    lines += ["", "# lib/services/api_data_service.dart  (one endpoint, e.g. login)", ""]
    source = (services / "api_data_service.dart").read_text(encoding="utf-8").splitlines()
    start = next(i for i, l in enumerate(source) if "Future<AppUser> login(" in l) - 1
    lines += source[start:start + 9]
    render(lines, OUT / "m7_25_code_api_switch.png", title="Flutter -> API switch", font_size=16)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    code_shot()
    run(URL, OUT, scenario)
    database_shots()
