"""Screenshots of the feature upgrade (Manage Classes, strict Class Teacher rules,
result-card readiness, Print / Save PDF, Review & Submit). New files only: m7b_*.png
(the existing screenshots are never overwritten).

Needs: the web build served on port 8765 and the API it points to running
(mobile/lib/services/api_config.dart - the live Azure API by default):
    python -m http.server 8765 -d mobile\\build\\web
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m7b_features.py
Afterwards reset the data (import_to_azure.py --reset, or the local reset steps).
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from flutter_driver import FlutterApp, run  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
URL = "http://127.0.0.1:8765/"


class SafeApp(FlutterApp):
    """Refuses to overwrite any screenshot that already exists."""

    def shot(self, name: str):
        if not name.startswith("m7b_") or (self.out_dir / name).exists():
            raise RuntimeError(f"refusing to overwrite / misname {name}")
        super().shot(name)


def login(app, login_id, expect):
    app.type_into("Login ID", login_id)
    app.type_into("Password", "123")
    app.tap("Login", last=True)
    app.wait_text(expect, timeout=60000)  # the free Azure plan may be waking up


def logout(app):
    app.open_drawer()
    app.tap("Logout")
    app.wait_text("School Grading System")


def scenario(app: FlutterApp):
    app.__class__ = SafeApp
    app.wait_text("School Grading System")

    # ---------------- Admin: Manage Classes ----------------
    login(app, "admin@school.com", "Welcome School Admin")
    app.wait_text("Manage Classes")
    app.shot("m7b_01_admin_home_manage_classes.png")

    app.tap("Manage Classes")
    app.wait_text("tap one to change its teachers")
    app.shot("m7b_02_manage_classes_list.png")

    app.tap("New class")
    app.wait_text("Subject teachers")
    app.type_into("Class name", "Class 10")
    app.type_into("Section", "A")
    app.scroll(300)
    app.tap("English (out of 100)")
    app.pause(500)
    app.tap("Teacher Ahsan", last=True)
    app.pause(500)
    app.tap("Mathematics (out of 100)")
    app.pause(500)
    app.tap("Teacher Maryam", last=True)
    app.pause(500)
    app.scroll(-600)
    app.shot("m7b_03_new_class_form.png")
    app.tap("No Class Teacher yet")
    app.pause(600)
    app.shot("m7b_04_class_teacher_dropdown.png")  # teachers leading another class are greyed out
    app.page.keyboard.press("Escape")
    app.pause(500)
    app.tap("Create class", last=True)
    app.wait_text("Class 10 - A", timeout=30000)
    app.scroll(2000)
    app.shot("m7b_05_class_created.png")
    app.scroll(-2000)

    app.tap("Class 9 - C")
    app.wait_text("Teachers of Class 9 - C")
    app.shot("m7b_06_edit_class_teachers.png")
    app.back()
    app.back()
    app.wait_text("Welcome School Admin")
    logout(app)

    # ---------------- Teacher: Save Progress, Review & Submit ----------------
    login(app, "sania@school.com", "Welcome Teacher Sania")
    app.tap("Class 8 - B")  # Chemistry 8-B: only Sarah has a mark
    app.wait_text("Review & Submit Marks")
    app.shot("m7b_07_marks_entry_hint_badge.png")

    for i, v in [(1, "40"), (2, "35"), (3, "52")]:  # leave Bilal empty on purpose
        app.type_into_nth_input(i, v)
    app.tap("Save Progress")
    app.wait_text("Progress saved")
    app.shot("m7b_08_progress_saved.png")
    app.wait_gone("Progress saved", timeout=10000)

    app.tap("Review & Submit Marks")
    app.wait_text("students graded")
    app.shot("m7b_09_review_missing_mark.png")  # Confirm disabled while a mark is missing
    app.tap("Go Back & Edit")
    app.wait_text("Review & Submit Marks")
    app.type_into_nth_input(4, "44")
    app.tap("Review & Submit Marks")
    app.wait_text("5 of 5 students graded")
    app.shot("m7b_10_review_all_graded.png")
    app.tap("Confirm & Final Submit")
    app.wait_text("Welcome Teacher Sania", timeout=30000)
    app.pause(300)
    app.shot("m7b_11_final_submitted.png")
    app.wait_gone("Final Submitted!", timeout=10000)

    # ---------------- My Class: subjects + result-card readiness ----------------
    app.tap("Open my class")
    app.wait_text("2. Result cards")
    app.shot("m7b_12_my_class_subjects.png")
    app.scroll(650)
    app.shot("m7b_13_readiness_waiting_on.png")
    app.tap("View incomplete card")
    app.wait_text("Print / Save PDF")
    app.shot("m7b_14_card_print_disabled_incomplete.png")
    app.back()
    app.back()
    app.wait_text("Welcome Teacher Sania")

    # ---------------- Manage Students: own class only, delete from all subjects ----------------
    app.open_drawer()
    app.tap("Manage Students")
    app.wait_text("5 students in Class 8 - B")
    app.tap("Add student")
    app.wait_text("Add student to Class 8 - B")
    app.type_into("Student name", "Hamza Ali")
    app.type_into("Roll number", "6")
    app.tap("Add", last=True)
    app.wait_text("6 students in Class 8 - B")
    app.wait_gone("Hamza Ali added", timeout=10000)
    app.shot("m7b_15_manage_students_own_class.png")
    app.tap_label("Delete student", index=5)
    app.wait_text("Delete Hamza Ali?")
    app.shot("m7b_16_delete_confirm_all_subjects.png")
    app.tap("Delete from all subjects", last=True)
    app.wait_text("removed from all subjects")
    app.shot("m7b_17_deleted_message.png")
    app.back()
    app.wait_text("Welcome Teacher Sania")
    logout(app)

    # ---------------- Subject teacher sees the removal notice ----------------
    login(app, "ahsan@school.com", "Welcome Teacher Ahsan")
    app.tap("Class 8 - B")  # English 8-B
    app.wait_text("was removed by the Class Teacher of Class 8 - B")
    app.shot("m7b_18_subject_teacher_removal_notice.png")
    app.back()
    logout(app)

    # ---------------- Class Teacher of 9-A: ready cards + Print / Save PDF ----------------
    login(app, "maryam@school.com", "Welcome Teacher Maryam")
    app.tap("Open my class")
    app.wait_text("2. Result cards")
    app.scroll(650)
    app.shot("m7b_19_readiness_all_ready.png")
    app.tap("View / Print Result Card")
    app.wait_text("Print / Save PDF")
    app.shot("m7b_20_card_print_button.png")
    app.back()
    app.back()
    logout(app)

    # ---------------- Principal / VP: view only, no print ----------------
    login(app, "vp@school.com", "Class Grading Status")
    app.tap("Class 9 - A")
    app.wait_text("2. Result cards")
    app.scroll(650)
    app.tap("View Result Card")
    app.wait_text("Percentage")
    app.shot("m7b_21_vp_card_view_only.png")


if __name__ == "__main__":
    run(URL, OUT, scenario)
