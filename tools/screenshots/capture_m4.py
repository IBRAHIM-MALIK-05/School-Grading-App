"""Milestone 4 screenshots (+ the rest of the Milestone 2 database shots).

Needs: XAMPP running, migration applied, and the API running on
http://localhost:5080  (cd api/SchoolGradingApi && dotnet run --launch-profile http)

    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m4.py
"""

import json
import sys
import urllib.parse
from pathlib import Path

from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).parent))
from text_image import render  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
API_DIR = ROOT / "api" / "SchoolGradingApi"
PMA = "http://localhost/phpmyadmin/index.php"
DB = "school_grading"
SWAGGER = "http://localhost:5080/swagger/index.html"


def save(page, name, full_page=False):
    page.wait_for_timeout(500)
    if full_page:
        # Make the window as tall as the page (instead of Playwright's full_page),
        # so phpMyAdmin's fixed sidebar/console are drawn correctly.
        size = page.viewport_size
        height = page.evaluate("() => document.documentElement.scrollHeight")
        page.set_viewport_size({"width": size["width"], "height": min(max(height, size["height"]), 2400)})
        page.wait_for_timeout(400)
        page.screenshot(path=str(OUT / name))
        page.set_viewport_size(size)
    else:
        page.screenshot(path=str(OUT / name))
    print("saved", name)


# ---------------------------------------------------------------- phpMyAdmin
def phpmyadmin_shots(browser):
    page = browser.new_page(viewport={"width": 1366, "height": 768})

    page.goto(f"{PMA}?route=/database/structure&db={DB}", wait_until="networkidle")
    save(page, "m2_07_tables_list.png")

    page.goto(f"{PMA}?route=/table/structure&db={DB}&table=users", wait_until="networkidle")
    save(page, "m2_08_users_structure.png", full_page=True)

    page.goto(f"{PMA}?route=/table/structure&db={DB}&table=marks", wait_until="networkidle")
    save(page, "m2_09_marks_structure.png", full_page=True)

    page.goto(f"{PMA}?route=/table/relation&db={DB}&table=marks", wait_until="networkidle")
    save(page, "m2_10_marks_foreign_keys.png", full_page=True)

    for i, table in enumerate(["users", "classes", "students", "teaching_assignments", "marks"]):
        page.goto(f"{PMA}?route=/sql&db={DB}&table={table}&pos=0", wait_until="networkidle")
        save(page, f"m2_{12 + i}_{table}_rows.png", full_page=(table != "marks"))

    # A JOIN query: the Class Teacher's tracker for Class 8 - B, written in SQL
    query = (
        "SELECT s.Name AS Subject, u.FullName AS Teacher,\n"
        "       COUNT(m.Id) AS MarksEntered,\n"
        "       IF(ta.SubmittedAt IS NULL, 'Not submitted', 'Submitted') AS Status\n"
        "FROM teaching_assignments ta\n"
        "JOIN subjects s ON s.Id = ta.SubjectId\n"
        "JOIN users u ON u.Id = ta.TeacherId\n"
        "LEFT JOIN students st ON st.ClassId = ta.ClassId\n"
        "LEFT JOIN marks m ON m.StudentId = st.Id AND m.SubjectId = ta.SubjectId\n"
        "WHERE ta.ClassId = 2\n"
        "GROUP BY ta.Id ORDER BY s.Id;"
    )
    page.goto(f"{PMA}?route=/database/sql&db={DB}", wait_until="networkidle")
    # put the text into the visible SQL editor (CodeMirror) directly
    page.evaluate(
        "q => document.querySelector('#sqlqueryform .CodeMirror').CodeMirror.setValue(q)",
        query,
    )
    page.wait_for_timeout(300)
    page.click("#button_submit_query")
    page.wait_for_selector("text=Showing rows", timeout=15000)
    save(page, "m2_17_join_query_tracker.png")
    page.close()

    # Designer ERD: drag every table into a tidy grid
    page = browser.new_page(viewport={"width": 1600, "height": 1000})
    page.goto(f"{PMA}?route=/database/designer&db={DB}", wait_until="networkidle")
    page.wait_for_timeout(2000)
    page.evaluate(
        "() => { const t = document.getElementById('school_grading.__efmigrationshistory');"
        " if (t) t.style.display = 'none'; }"
    )
    layout = {  # table -> (left, top) inside the canvas
        "classes": (40, 40),
        "teaching_assignments": (450, 30),
        "subjects": (930, 60),
        "students": (40, 330),
        "users": (460, 330),
        "marks": (930, 330),
    }
    # 1) put every table at its place (no overlaps)
    page.evaluate(
        """layout => { for (const [name, pos] of Object.entries(layout)) {
               const t = document.getElementById('school_grading.' + name);
               t.style.left = pos[0] + 'px'; t.style.top = pos[1] + 'px'; } }""",
        layout,
    )
    page.wait_for_timeout(300)
    # 2) a tiny real drag of one table makes phpMyAdmin redraw all relation lines
    head = page.locator(f"table[id='{DB}.users'] tr.header").first.bounding_box()
    x, y = head["x"] + head["width"] * 0.6, head["y"] + head["height"] / 2
    page.mouse.move(x, y)
    page.mouse.down()
    page.mouse.move(x + 6, y + 4, steps=5)
    page.mouse.move(x, y, steps=5)
    page.mouse.up()
    page.wait_for_timeout(500)
    page.mouse.move(5, 5)
    save(page, "m2_11_designer_erd.png")
    page.close()


# ---------------------------------------------------------------- terminal-style images
def text_shots():
    # Project structure (like Solution Explorer)
    skip = {"bin", "obj", ".vs", "Properties"}
    lines = ["api/", "├── SchoolGrading.slnx", "├── dotnet-tools.json", "└── SchoolGradingApi/"]

    def walk(folder: Path, prefix: str):
        entries = sorted([p for p in folder.iterdir() if p.name not in skip],
                         key=lambda p: (p.is_file(), p.name.lower()))
        for i, p in enumerate(entries):
            last = i == len(entries) - 1
            lines.append(prefix + ("└── " if last else "├── ") + p.name + ("/" if p.is_dir() else ""))
            if p.is_dir():
                walk(p, prefix + ("    " if last else "│   "))

    walk(API_DIR, "    ")
    render(lines, OUT / "m4_01_project_structure.png", title="Solution: SchoolGrading.slnx")

    render([
        "PS D:\\desktop\\school_grading_app\\api\\SchoolGradingApi> dotnet ef migrations add InitialCreate",
        "#  (same as  Add-Migration InitialCreate  in Visual Studio's Package Manager Console)",
        "Build started...",
        "Build succeeded.",
        "Done. To undo this action, use 'ef migrations remove'",
        "",
        "PS D:\\desktop\\school_grading_app\\api\\SchoolGradingApi> dir Migrations",
        "    20261124031825_InitialCreate.cs",
        "    20261124031825_InitialCreate.Designer.cs",
        "    AppDbContextModelSnapshot.cs",
    ], OUT / "m4_02_add_migration.png", title="Add-Migration")

    log = (API_DIR.parent / "database_update.log").read_text(encoding="utf-8", errors="ignore").splitlines()
    created = [l.strip() for l in log if l.strip().startswith("CREATE TABLE `") and "__EFMigrationsHistory" not in l]
    inserts = sum(1 for l in log if l.strip().startswith("INSERT INTO `") and "__EFMigrationsHistory" not in l)
    out = [
        "PS D:\\desktop\\school_grading_app\\api\\SchoolGradingApi> dotnet ef database update",
        "#  (same as  Update-Database  in Visual Studio's Package Manager Console)",
        "Build started...",
        "Build succeeded.",
        "info: Acquiring an exclusive lock for migration application.",
        "info: Applying migration '20261124031825_InitialCreate'.",
    ]
    out += ["      " + c.rstrip(" (") + " (...)" for c in created]
    out += [f"      ... {inserts} INSERT statements (demo data: users, subjects, classes,",
            "          students, teaching_assignments, marks) ...",
            "      CREATE UNIQUE INDEX / FOREIGN KEY constraints ...",
            "Done."]
    render(out, OUT / "m4_03_update_database.png", title="Update-Database")


# ---------------------------------------------------------------- Swagger UI
def swagger_try(page, op_id, body=None):
    block = page.locator(f"#{op_id}")
    block.locator(".opblock-summary").first.click()
    page.wait_for_timeout(400)
    block.locator("button.try-out__btn").click()
    if body is not None:
        area = block.locator("textarea.body-param__text")
        area.fill(json.dumps(body, indent=2))
    block.locator("button.execute").click()
    block.locator(".live-responses-table").wait_for(timeout=15000)
    page.wait_for_timeout(500)
    return block


def swagger_shots(browser):
    page = browser.new_page(viewport={"width": 1366, "height": 900})
    page.goto(SWAGGER, wait_until="networkidle")
    page.wait_for_selector(".opblock", timeout=20000)
    save(page, "m4_04_swagger_endpoints.png", full_page=True)

    # Login as Admin
    block = swagger_try(page, "operations-Auth-post_api_auth_login",
                        {"loginId": "admin@school.com", "password": "123"})
    block.scroll_into_view_if_needed()
    block.screenshot(path=str(OUT / "m4_05_swagger_login.png"))
    print("saved m4_05_swagger_login.png")
    token = json.loads(block.locator(".live-responses-table .microlight").first.inner_text())["token"]
    block.locator(".opblock-summary").first.click()

    # Authorize button -> paste token
    page.locator("button.authorize").first.click()
    modal = page.locator(".modal-ux")
    modal.locator("input").first.fill(token)
    save(page, "m4_06_swagger_authorize.png")
    modal.locator("button.authorize").click()
    page.wait_for_timeout(300)
    modal.locator("button.btn-done").click()

    # A protected endpoint working with the token
    block = swagger_try(page, "operations-Classes-get_api_classes")
    block.scroll_into_view_if_needed()
    block.screenshot(path=str(OUT / "m4_07_swagger_overview.png"))
    print("saved m4_07_swagger_overview.png")
    block.locator(".opblock-summary").first.click()

    # A clear JSON error: the Admin has no teaching subjects -> 403
    block = swagger_try(page, "operations-Assignments-get_api_assignments_mine")
    block.scroll_into_view_if_needed()
    block.screenshot(path=str(OUT / "m4_08_swagger_error_403.png"))
    print("saved m4_08_swagger_error_403.png")
    page.close()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    text_shots()
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        phpmyadmin_shots(browser)
        swagger_shots(browser)
        browser.close()


if __name__ == "__main__":
    main()
