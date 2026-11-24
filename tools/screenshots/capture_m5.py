"""Milestone 5 screenshots: Postman collection + Newman run + HTML report +
database checks after the API tests.

Needs: postman\\run_tests_local.cmd already run (report + CLI output exist), XAMPP on.
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m5.py
"""

import json
import re
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

sys.path.insert(0, str(Path(__file__).parent))
from text_image import render  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
POSTMAN = ROOT / "postman"
REPORT = POSTMAN / "reports" / "local_test_report.html"
PMA = "http://localhost/phpmyadmin/index.php"


def save(page, name):
    page.wait_for_timeout(500)
    page.screenshot(path=str(OUT / name))
    print("saved", name)


def text_shots():
    collection = json.loads((POSTMAN / "SchoolGrading.postman_collection.json").read_text(encoding="utf-8"))
    lines = ["School Grading API   (Postman collection v2.1)"]
    for f in collection["item"]:
        lines.append(f"├── 📁 {f['name']}".replace("📁 ", "[folder] "))
        for r in f["item"]:
            method = r["request"]["method"]
            lines.append(f"│     {method:<7}{r['name']}")
    render(lines, OUT / "m5_01_collection_structure.png", title="Postman collection", font_size=16)

    env = json.loads((POSTMAN / "SchoolGrading_Local.postman_environment.json").read_text(encoding="utf-8"))
    lines = [f"Environment: {env['name']}", ""]
    lines += [f"  {v['key']:<12} = {v['value']}" for v in env["values"]]
    lines += ["", "Collection variables (filled in automatically by the test scripts):", ""]
    lines += [f"  {v['key']}" for v in collection["variable"]]
    lines += ["", "# Example test script (Login - Admin):"]
    login = collection["item"][0]["item"][0]["event"][-1]["script"]["exec"]
    lines += ["  " + l for l in login]
    render(lines, OUT / "m5_02_environment_and_scripts.png", title="Environment + test script", font_size=16)

    cli = (POSTMAN / "reports" / "local_cli_output.txt").read_text(encoding="utf-8", errors="ignore")
    cli = re.sub(r"\x1b\[[0-9;]*m", "", cli).splitlines()
    start = next(i for i, l in enumerate(cli) if l.startswith("newman"))
    # folders start with a marker character, e.g. "□ 2. Auth - ..." -> show only folder 1
    second_folder = next(i for i, l in enumerate(cli) if re.match(r"^\S 2\. ", l))
    block = [l.rstrip() for l in cli[start:second_folder]]
    block = ["# " + l[2:] if re.match(r"^\S \d\. ", l) else l for l in block]
    render(["PS D:\\desktop\\school_grading_app> postman\\run_tests_local.cmd", ""] + block,
           OUT / "m5_03_newman_cli_run.png", title="Newman (Postman CLI runner)", font_size=15)

    table_start = next(i for i, l in enumerate(cli) if l.startswith("┌"))
    table_end = next(i for i in range(table_start, len(cli)) if cli[i].startswith("└"))
    render([l.rstrip() for l in cli[table_start:table_end + 1]],
           OUT / "m5_04_newman_summary.png", title="Newman summary - 0 failures", font_size=16, min_width=700)


def report_shots(browser):
    page = browser.new_page(viewport={"width": 1366, "height": 900})
    page.goto(REPORT.as_uri(), wait_until="networkidle")
    save(page, "m5_05_html_report_summary.png")

    page.click("#pills-requests-tab")
    page.wait_for_timeout(600)
    save(page, "m5_06_html_report_requests.png")

    # Open one error-case request (a 409) to show its response body + tests.
    # The report nests request cards inside collapsed folder sections, so we open
    # every collapsed parent, then the card's own details.
    card_id = page.evaluate(
        """name => {
            const a = [...document.querySelectorAll('#pills-requests .card-header a')]
                .find(x => x.textContent.includes(name));
            let el = a.closest('.card');
            for (let p = el.parentElement; p; p = p.parentElement) {
                if (p.classList && p.classList.contains('collapse')) p.classList.add('show');
            }
            document.querySelector(a.getAttribute('data-target')).classList.add('show');
            el.id = 'shot-card';
            return el.id;
        }""",
        "Publish 8-B - subjects still pending",
    )
    page.wait_for_timeout(800)
    card = page.locator("#" + card_id)
    card.scroll_into_view_if_needed()
    card.screenshot(path=str(OUT / "m5_07_html_report_error_case.png"))
    print("saved m5_07_html_report_error_case.png")
    page.close()


def database_shots(browser):
    # wide window so the MustChangePassword column is visible
    page = browser.new_page(viewport={"width": 1700, "height": 640})
    # The account created by "Register - new Teacher" is now really in MySQL
    page.goto(f"{PMA}?route=/sql&db=school_grading&table=users&pos=0", wait_until="networkidle")
    save(page, "m5_08_db_after_tests_users.png")
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
    save(page, "m5_09_db_after_tests_marks.png")
    page.close()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    text_shots()
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        report_shots(browser)
        database_shots(browser)
        browser.close()


if __name__ == "__main__":
    main()
