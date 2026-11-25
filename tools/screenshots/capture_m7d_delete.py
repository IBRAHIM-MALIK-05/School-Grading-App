"""Screenshots of Soft Delete / Hard Delete for Teachers and Classes.

  - Flutter (Admin Panel): Delete buttons, confirmation dialogs, a teacher who still has work
    is refused, a teacher and a class are soft-deleted (hidden in the app).
  - The database still holds both rows (isDeleted = 1).
  - Swagger (backend maintainer only, NOT in the app): GetDeleted, RestoreById, HardDeleteById.
New files only: m7d_*.png (existing screenshots are never overwritten).

Needs: the API on http://localhost:5080 (local XAMPP, clean demo data) and a web build pointed
at it, served on http://127.0.0.1:8766/
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m7d_delete.py
Afterwards reset the local data (drop school_grading, 01_create_database.sql, Update-Database).
"""

import json
import subprocess
import sys
import urllib.request
from pathlib import Path

from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).parent))
from flutter_driver import FlutterApp, run  # noqa: E402
from text_image import render  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
APP_URL = "http://127.0.0.1:8766/"
API = "http://localhost:5080/api"
SWAGGER = "http://localhost:5080/swagger/index.html"
MYSQL = r"d:\xampp\mysql\bin\mysql.exe"


def check_name(name: str):
    if not name.startswith("m7d_") or (OUT / name).exists():
        raise RuntimeError(f"refusing to overwrite / misname {name}")


class SafeApp(FlutterApp):
    """Refuses to overwrite any screenshot that already exists."""

    def shot(self, name: str):
        check_name(name)
        self.page.mouse.move(200, 30)  # park the mouse so no hover tooltip shows
        self.pause(600)
        super().shot(name)


def api(method, path, body=None, token=None):
    req = urllib.request.Request(API + path, method=method,
                                 data=None if body is None else json.dumps(body).encode())
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read() or b"null")


# ---------------------------------------------------------------- 1) Flutter app
def app_scenario(app: FlutterApp):
    app.__class__ = SafeApp
    app.wait_text("School Grading System")
    app.tap("Login as Admin", last=True)
    app.wait_text("Back to Staff Login")
    app.type_into("Admin Login ID", "admin@school.com")
    app.type_into("Password", "123")
    app.tap("Login as Admin", last=False)
    app.wait_text("showing 7 of 7 accounts", timeout=60000)
    app.shot("m7d_01_users_tab_delete_buttons.png")

    # A teacher who still leads a class + teaches subjects is refused (409)
    app.tap_label("Delete Teacher Sania")
    app.wait_text("Delete Teacher Sania?")
    app.shot("m7d_02_delete_teacher_confirm.png")
    app.tap("Delete", last=True)
    app.wait_text("is the Class Teacher of Class 8 - B")
    app.shot("m7d_03_teacher_with_work_refused.png")
    app.wait_gone("is the Class Teacher of Class 8 - B", timeout=15000)

    # A teacher with no class / subjects is soft-deleted
    app.type_into("Search users", "temp")
    app.wait_text("showing 1 of 7")
    app.tap_label("Delete Temp Teacher")
    app.wait_text("Delete Temp Teacher?")
    app.tap("Delete", last=True)
    app.wait_text("Temp Teacher was deleted")
    app.wait_text("showing 0 of 6")
    app.shot("m7d_04_teacher_deleted.png")
    app.wait_gone("Temp Teacher was deleted", timeout=15000)
    app.tap_label("Clear search")
    app.pause(400)

    # Classes tab: soft-delete Class 9 - C
    app.tap("Classes")
    app.wait_text("Showing 5 of 5 classes")
    app.shot("m7d_05_classes_tab_delete_buttons.png")
    app.scroll(2500)
    app.tap_label("Delete Class 9 - C")
    app.wait_text("Delete Class 9 - C?")
    app.shot("m7d_06_delete_class_confirm.png")
    app.tap("Delete", last=True)
    app.wait_text("Class 9 - C was deleted")
    app.scroll(-3000)
    app.wait_text("Showing 4 of 4 classes")
    app.shot("m7d_07_class_deleted.png")


# ---------------------------------------------------------------- 2) the rows are still in MySQL
def database_shot():
    queries = ["SELECT Id, FullName, LoginId, Role, isDeleted FROM users;",
               "SELECT Id, GradeName, Section, ClassTeacherId, isDeleted FROM classes;"]
    lines = []
    for q in queries:
        out = subprocess.run([MYSQL, "-u", "root", "-t", "-e", q, "school_grading"],
                             capture_output=True, text=True, check=True).stdout
        lines += [f"MariaDB [school_grading]> {q}"] + out.rstrip().splitlines() + [""]
    lines.append("-- isDeleted = 1 : hidden in the app, but the row is still stored (soft delete)")
    name = "m7d_08_database_rows_still_stored.png"
    check_name(name)
    render(lines, OUT / name, title="XAMPP MySQL - after the soft deletes")
    print("saved", name)


# ---------------------------------------------------------------- 3) Swagger (maintainer only)
def swagger_exec(page, op_id, params=None):
    block = page.locator(f"#{op_id}")
    block.locator(".opblock-summary").first.click()
    page.wait_for_timeout(400)
    block.locator("button.try-out__btn").click()
    for key, value in (params or {}).items():
        block.locator(f"tr[data-param-name='{key}'] input").fill(str(value))
    block.locator("button.execute").click()
    block.locator(".live-responses-table").wait_for(timeout=15000)
    page.wait_for_timeout(600)
    # never show a real JWT in a screenshot: blank it in the "Curl" box
    page.evaluate("""() => document.querySelectorAll('pre.curl').forEach(el => {
        el.textContent = el.textContent.replace(/eyJ[A-Za-z0-9_\\-.]+/g, '<JWT token hidden>'); })""")
    assert "eyJ" not in block.inner_text(), "token still visible"
    return block


def save_element(locator, name):
    check_name(name)
    locator.scroll_into_view_if_needed()
    locator.screenshot(path=str(OUT / name))
    print("saved", name)


def swagger_shots(token, temp_id):
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = browser.new_page(viewport={"width": 1366, "height": 900})
        page.goto(SWAGGER, wait_until="networkidle")
        page.wait_for_selector(".opblock", timeout=20000)
        page.evaluate("t => window.ui.preauthorizeApiKey('Bearer', t)", token)  # = the Authorize button

        save_element(page.locator(".opblock-tag-section").filter(has=page.locator("#operations-tag-Users")),
                     "m7d_09_swagger_users_endpoints.png")

        block = swagger_exec(page, "operations-Users-get_api_users_GetDeleted")
        save_element(block, "m7d_10_swagger_users_getdeleted.png")

        block = swagger_exec(page, "operations-Users-delete_api_users_HardDeleteById", {"id": 3})
        save_element(block, "m7d_11_swagger_harddelete_teacher_refused_409.png")

        block = swagger_exec(page, "operations-Classes-put_api_classes_RestoreById", {"id": 5})
        save_element(block, "m7d_12_swagger_restore_class.png")
        browser.close()

    # Hard delete of the soft-deleted Temp Teacher in a fresh page (a clean "Try it out" block)
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        page = browser.new_page(viewport={"width": 1366, "height": 900})
        page.goto(SWAGGER, wait_until="networkidle")
        page.wait_for_selector(".opblock", timeout=20000)
        page.evaluate("t => window.ui.preauthorizeApiKey('Bearer', t)", token)
        block = swagger_exec(page, "operations-Users-delete_api_users_HardDeleteById", {"id": temp_id})
        save_element(block, "m7d_13_swagger_harddelete_teacher_200.png")
        browser.close()


def main():
    token = api("POST", "/auth/login", {"loginId": "admin@school.com", "password": "123"})["token"]
    api("POST", "/auth/register", {"fullName": "Temp Teacher", "role": "teacher",
                                   "contactEmail": "temp.teacher@gmail.com",
                                   "classTeacherOfClassId": None, "assignmentIds": []}, token)
    temp_id = next(u["id"] for u in api("GET", "/users", token=token) if u["fullName"] == "Temp Teacher")

    run(APP_URL, OUT, app_scenario)
    database_shot()
    swagger_shots(token, temp_id)


if __name__ == "__main__":
    main()
