"""Milestone 1 screenshots: clicks through the Flutter app (mock data) on a
390x844 phone screen and saves PNGs into docs/screenshots/.

Usage (from the repo root, with the web build served on port 8765):
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m1.py
"""

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from flutter_driver import FlutterApp, run  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
URL = "http://127.0.0.1:8765/"


def login(app: FlutterApp, login_id: str, password: str, expect: str):
    app.type_into("Login ID", login_id)
    app.type_into("Password", password)
    app.tap("Login", last=True)
    app.wait_text(expect)


def logout(app: FlutterApp):
    app.open_drawer()
    app.tap("Logout")
    app.wait_text("School Grading System")


def scenario(app: FlutterApp):
    # ---------------- Login ----------------
    app.wait_text("School Grading System")
    app.shot("m1_01_login.png")

    app.type_into("Login ID", "sania@school.com")
    app.type_into("Password", "wrong")
    app.tap("Login", last=True)
    app.wait_text("Invalid Login ID or password")
    app.shot("m1_02_login_error.png")

    app.tap("Forgot password?")
    app.wait_text("Forgot your password?")
    app.shot("m1_03_forgot_password.png")
    app.tap("OK")
    app.pause(500)

    # ---------------- Admin ----------------
    login(app, "admin@school.com", "123", "Welcome School Admin")
    app.shot("m1_04_admin_users.png")

    app.open_drawer()
    app.shot("m1_05_admin_drawer.png")
    app.tap("Create Account")
    app.wait_text("Full name")

    app.type_into("Full name", "Ali Raza")
    app.type_into("Gmail", "ali.raza@gmail.com")
    app.tap("Not a class teacher")  # open the dropdown
    app.pause(500)
    app.tap("Class 9 - C")
    app.pause(500)
    app.shot("m1_06_create_account.png")

    app.scroll(700)
    app.tap("Class 9 - C", last=True)  # expand the 9-C subjects
    app.pause(500)
    app.tap("Physics (out of 60)")
    app.pause(300)
    app.scroll(300)
    app.shot("m1_06b_create_account_subjects.png")

    app.tap("Create account", last=True)
    app.wait_text("Account created")
    app.shot("m1_07_credentials_dialog.png")

    app.tap("Copy")  # the dialog's own Copy button -> read it back from the clipboard
    app.pause(500)
    match = re.search(r"Temporary password: (\S+)", app.clipboard_text())
    if not match:
        raise RuntimeError("could not read the temporary password from the clipboard")
    ali_password = match.group(1)
    app.pause(4500)  # let the "Copied" message disappear (hidden behind the dialog)
    print("Ali temp password:", ali_password)

    app.tap("Done")
    app.wait_text("Welcome School Admin")
    app.scroll(1500)
    app.shot("m1_07b_users_after_create.png")
    app.scroll(-1500)

    # Reset Ahsan's password (order: VP, Sania, Ahsan ...)
    app.tap_label("Reset password", index=2)
    app.wait_text("Reset password?")
    app.shot("m1_09a_reset_password_confirm.png")
    app.tap("Reset", last=True)
    app.wait_text("Password reset")
    app.shot("m1_09_reset_password.png")
    app.tap("Done")
    app.pause(600)
    logout(app)

    # ---------------- New teacher: forced password change ----------------
    login(app, "ali@school.com", ali_password, "You are using a temporary password")
    app.shot("m1_10_forced_change_password.png")

    app.type_into("Temporary password", ali_password)
    app.type_into("New password", "abcdefgh")
    app.type_into("Confirm new password", "abcdefgh")
    app.tap("Save new password")
    app.wait_text("at least one letter and one number")
    app.shot("m1_11_password_rule_error.png")

    app.type_into("New password", "NewPass123")
    app.type_into("Confirm new password", "NewPass123")
    app.tap("Save new password")
    app.wait_text("Physics • Out of 60")
    app.wait_gone("Password changed successfully", timeout=10000)
    app.shot("m1_11b_new_teacher_dashboard.png")
    logout(app)

    # ---------------- Teacher Sania ----------------
    login(app, "sania@school.com", "123", "Welcome Teacher Sania")
    app.shot("m1_12_teacher_dashboard.png")

    app.open_drawer()
    app.shot("m1_13_teacher_drawer.png")
    app.tap("My Subjects")
    app.pause(500)

    app.tap("Class 8 - B")  # first one = Chemistry
    app.wait_text("Max marks: 60")
    app.shot("m1_14_marks_entry.png")

    app.type_into_nth_input(1, "75")
    app.tap("Save draft")
    app.wait_text("0 - 60")
    app.shot("m1_15_marks_validation.png")

    for i, v in [(1, "40"), (2, "35"), (3, "52"), (4, "44")]:
        app.type_into_nth_input(i, v)
    app.tap("Submit", last=True)
    app.wait_text("Submit marks?")
    app.shot("m1_16_submit_confirm.png")
    app.tap("Submit", last=True)
    app.wait_text("Welcome Teacher Sania")
    app.pause(300)
    app.shot("m1_17_dashboard_after_submit.png")

    # ---------------- Class Teacher view (8-B) ----------------
    app.wait_gone("Marks submitted!", timeout=10000)
    app.tap("Open my class")
    app.wait_text("Subject submissions")
    app.shot("m1_18_class_tracker.png")

    app.scroll(700)
    app.tap("Sarah")
    app.wait_text("Percentage")
    app.shot("m1_19_report_card_complete.png")
    app.back()

    app.tap("Ahmed")
    app.wait_text("Incomplete")
    app.shot("m1_20_report_card_incomplete.png")
    app.back()
    app.back()
    app.wait_text("Welcome Teacher Sania")

    # ---------------- Manage Students ----------------
    app.open_drawer()
    app.tap("Manage Students")
    app.wait_text("students in Class 8 - A")
    app.tap("Class 8 - A")  # open dropdown
    app.pause(500)
    app.tap("Class 8 - B", last=True)
    app.wait_text("students in Class 8 - B")
    app.shot("m1_21_manage_students.png")

    app.tap("Add student")
    app.wait_text("Add student to Class 8 - B")
    app.type_into("Student name", "Hamza Ali")
    app.type_into("Roll number", "6")
    app.shot("m1_22_add_student.png")
    app.tap("Add", last=True)
    app.wait_text("6 students in Class 8 - B")
    app.shot("m1_22b_student_added.png")
    app.wait_gone("Hamza Ali added", timeout=10000)
    app.back()
    app.wait_text("Welcome Teacher Sania")

    app.tap("Open my class")
    app.wait_text("Subject submissions")
    app.shot("m1_23_tracker_after_add.png")
    app.back()
    app.wait_text("Welcome Teacher Sania")

    app.open_drawer()
    app.tap("Manage Students")
    app.wait_text("students in Class 8 - A")
    app.tap("Class 8 - A")
    app.pause(500)
    app.tap("Class 8 - B", last=True)
    app.wait_text("6 students in Class 8 - B")
    app.tap_label("Delete student", index=5)  # Hamza = 6th row
    app.wait_text("Delete student?")
    app.shot("m1_24_delete_confirm.png")
    app.tap("Delete", last=True)
    app.wait_text("5 students in Class 8 - B")
    app.shot("m1_24b_student_deleted.png")
    app.back()
    logout(app)

    # ---------------- Maryam publishes 9-A ----------------
    login(app, "maryam@school.com", "123", "Welcome Teacher Maryam")
    app.tap("Open my class")
    app.wait_text("Ready to publish")
    app.scroll(2000)
    app.scroll(800)
    app.shot("m1_25_publish_ready.png")

    app.tap("Publish results")
    app.wait_text("Publish results?")
    app.tap("Publish", last=True)
    app.wait_text("Results published.")
    app.wait_gone("Results published.", timeout=10000)
    app.scroll(-2000)
    app.shot("m1_26_published.png")
    app.back()
    app.wait_text("Welcome Teacher Maryam")

    app.tap("Class 9 - A")
    app.wait_text("Marks are locked")
    app.shot("m1_27_marks_locked.png")
    app.back()

    app.open_drawer()
    app.tap("Manage Students")
    app.wait_text("students in Class 8 - A")
    app.tap("Class 8 - A")
    app.pause(500)
    app.tap("Class 9 - A", last=True)
    app.wait_text("class is locked")
    app.shot("m1_28_students_locked.png")
    app.back()
    logout(app)

    # ---------------- Principal / VP ----------------
    login(app, "vp@school.com", "123", "Class Grading Status")
    app.shot("m1_29_vp_dashboard.png")

    app.tap_label("Refresh")
    app.pause(150)
    app.shot("m1_31_loading_spinner.png")
    app.wait_text("Class Grading Status")

    app.scroll(400)
    app.tap("Class 8 - B")
    app.wait_text("Subject submissions")
    app.shot("m1_30_vp_class_readonly.png")


if __name__ == "__main__":
    run(URL, OUT, scenario)
