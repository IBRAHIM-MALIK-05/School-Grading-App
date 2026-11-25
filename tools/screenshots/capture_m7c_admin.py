"""Screenshots of the Login + Admin Panel upgrade: Staff / Admin login, Admin Panel tabs with
search, Subjects, the Subject-first Create / Edit Account form, and the Class editor with
searchable pickers. New files only: m7c_*.png (existing screenshots are never overwritten).

Needs: a web build served on http://127.0.0.1:8766/ and the API it points to running:
    python -m http.server 8766 -d <web build folder>
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m7c_admin.py
Afterwards reset the data (local reset steps or import_to_azure.py --reset).
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from flutter_driver import FlutterApp, run  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
URL = "http://127.0.0.1:8766/"


class SafeApp(FlutterApp):
    """Refuses to overwrite any screenshot that already exists."""

    def shot(self, name: str):
        if not name.startswith("m7c_") or (self.out_dir / name).exists():
            raise RuntimeError(f"refusing to overwrite / misname {name}")
        self.page.mouse.move(200, 30)  # park the mouse on the title so no hover tooltip shows
        self.pause(600)
        super().shot(name)


def scenario(app: FlutterApp):
    app.__class__ = SafeApp
    app.wait_text("School Grading System")

    # ---------------- Staff / Admin login ----------------
    app.wait_text("Teacher / Vice Principal Login")
    app.shot("m7c_01_login_staff.png")

    app.type_into("Login ID", "admin@school.com")
    app.type_into("Password", "123")
    app.tap("Login", last=False)
    app.wait_text("Please use \"Login as Admin\"")
    app.shot("m7c_02_admin_refused_on_staff_login.png")

    app.tap("Login as Admin", last=True)
    app.wait_text("Back to Staff Login")
    app.type_into("Admin Login ID", "sania@school.com")
    app.type_into("Password", "123")
    app.tap("Login as Admin", last=False)
    app.wait_text("This portal is for Admins only")
    app.shot("m7c_03_teacher_refused_on_admin_login.png")

    app.type_into("Admin Login ID", "admin@school.com")
    app.type_into("Password", "123")
    app.pause(300)
    app.shot("m7c_04_admin_login_view.png")
    app.tap("Login as Admin", last=False)
    app.wait_text("showing 6 of 6 accounts", timeout=60000)
    app.shot("m7c_05_admin_panel_users_tab.png")

    app.type_into("Search users", "class teacher")
    app.wait_text("showing 4 of 6")
    app.shot("m7c_06_users_search.png")
    app.tap_label("Clear search")
    app.pause(400)

    # ---------------- Subjects tab ----------------
    app.tap("Subjects")
    app.wait_text("Showing 5 of 5 subjects")
    app.shot("m7c_07_subjects_tab.png")
    app.tap("Add subject")
    app.wait_text("Subject name")
    app.type_into("Subject name", "english")
    app.tap("Add", last=True)
    app.wait_text("already exists")
    app.shot("m7c_08_subject_duplicate_refused.png")
    app.type_into("Subject name", "Computer Science")
    app.pause(300)
    app.shot("m7c_09_add_subject_dialog.png")
    app.tap("Add", last=True)
    app.wait_text("Showing 6 of 6 subjects")
    app.wait_gone("Computer Science added", timeout=10000)
    app.type_into("Search subjects", "comp")
    app.wait_text("Showing 1 of 6")
    app.shot("m7c_10_subjects_search.png")
    app.tap_label("Edit Computer Science")
    app.wait_text("Edit Computer Science")
    app.type_into("Maximum marks", "75")
    app.pause(300)
    app.shot("m7c_11_edit_subject_dialog.png")
    app.tap("Save", last=True)
    app.wait_text("Out of 75")
    app.tap_label("Clear search")
    app.pause(400)

    # ---------------- Users tab: Create account (Subject -> Class) ----------------
    app.tap("Users")
    app.wait_text("showing 6 of 6")
    app.tap("Create account")
    app.wait_text("Subjects to teach")
    app.type_into("Full name", "Ali Raza")
    app.type_into("Gmail", "ali.raza@gmail.com")
    app.tap("Class Teacher of")
    app.wait_text("Search classes")
    app.shot("m7c_12_class_teacher_of_picker.png")  # classes with a Class Teacher are greyed out
    app.tap("Class 9 - C", last=True)
    app.pause(500)

    app.scroll(500)
    app.tap("1. Subject")
    app.wait_text("Step 1 - Pick a subject")
    app.type_into("Search subjects", "math")
    app.pause(500)
    app.shot("m7c_13_subject_picker_search.png")
    app.tap("Mathematics", last=True)
    app.pause(700)
    app.scroll(400)  # keep the button clear of the bottom "Create account" bar
    app.tap("2. Pick class(es)")
    app.wait_text("Step 2 - Classes for Mathematics")
    app.tap("Class 8 - A", last=True)
    app.tap("Class 8 - B", last=True)
    app.pause(300)
    app.shot("m7c_14_classes_for_subject_picker.png")
    app.tap("Done")
    app.pause(600)

    app.tap("1. Subject")
    app.wait_text("Step 1 - Pick a subject")
    app.type_into("Search subjects", "comp")
    app.pause(400)
    app.tap("Computer Science", last=True)
    app.pause(700)
    app.scroll(400)  # keep the button clear of the bottom "Create account" bar
    app.tap("2. Pick class(es)")
    app.wait_text("Step 2 - Classes for Computer Science")
    app.tap("Class 9 - C", last=True)
    app.tap("Done")
    app.pause(600)
    app.scroll(800)
    app.shot("m7c_15_account_form_chips.png")

    app.tap("Create account", last=True)
    app.wait_text("Account created")
    app.shot("m7c_16_credentials.png")
    app.tap("Done")
    app.wait_text("showing 7 of 7")

    # ---------------- Edit the new teacher ----------------
    app.type_into("Search users", "ali")
    app.wait_text("showing 1 of 7")
    app.tap_label("Edit Ali Raza")
    app.wait_text("Will teach (3)")
    app.scroll(800)
    app.shot("m7c_17_edit_user_form.png")
    app.back()
    app.wait_text("showing 1 of 7")
    app.tap_label("Clear search")
    app.pause(400)

    # ---------------- Classes tab ----------------
    app.tap("Classes")
    app.wait_text("Showing 5 of 5 classes")
    app.shot("m7c_18_classes_tab.png")
    app.type_into("Search classes", "maryam")
    app.wait_text("Showing")
    app.pause(500)
    app.shot("m7c_19_classes_search.png")
    app.tap_label("Clear search")
    app.pause(400)

    app.scroll(2000)
    app.tap("Edit Class 9 - C")
    app.wait_text("Subjects & teachers")
    app.shot("m7c_20_edit_class_form.png")
    app.tap("Class Teacher:")
    app.wait_text("Search teachers")
    app.shot("m7c_21_class_teacher_picker_eligible_only.png")
    app.page.keyboard.press("Escape")
    app.pause(500)
    app.back()
    app.scroll(-3000)
    app.wait_text("Showing 5 of 5 classes")

    # ---------------- New class: add subjects + pick teachers ----------------
    app.tap("New class")
    app.wait_text("No subjects yet")
    app.type_into("Class name", "Class 10")
    app.type_into("Section", "A")
    app.tap("Add subjects")
    app.wait_text("Add subjects to this class")
    app.tap("English", last=True)
    app.tap("Computer Science", last=True)
    app.pause(300)
    app.shot("m7c_22_add_subjects_picker.png")
    app.tap("Done")
    app.pause(600)
    app.tap("Teacher for English")
    app.wait_text("Search teachers")
    app.type_into("Search teachers", "ah")
    app.pause(400)
    app.shot("m7c_23_subject_teacher_picker.png")
    app.tap("Teacher Ahsan", last=True)
    app.pause(500)
    app.tap("Create class", last=True)
    app.wait_text("Please pick a teacher")
    app.scroll(400)
    app.shot("m7c_24_pick_teacher_error.png")
    app.tap("Teacher for Computer Science")
    app.wait_text("Search teachers")
    app.tap("Ali Raza", last=True)
    app.pause(500)
    app.shot("m7c_25_new_class_ready.png")
    app.tap("Create class", last=True)
    app.wait_text("Showing 6 of 6 classes", timeout=30000)
    app.scroll(2500)
    app.shot("m7c_26_class_created.png")


if __name__ == "__main__":
    run(URL, OUT, scenario)
