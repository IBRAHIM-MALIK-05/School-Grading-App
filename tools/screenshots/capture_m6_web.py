"""Milestone 6 screenshots (headless): cloud Swagger, Newman run against Azure,
and the GitHub Actions run page (the repository is public, no login needed).

    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m6_web.py swagger newman
    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_m6_web.py actions <run-url>
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
BASE = "https://school-grading-api-bcgi.azurewebsites.net"
REPORT = ROOT / "postman" / "reports" / "azure_test_report.html"
CLI_OUTPUT = ROOT / "postman" / "reports" / "azure_cli_output.txt"


def save(page, name, full_page=False):
    page.wait_for_timeout(600)
    page.screenshot(path=str(OUT / name), full_page=full_page)
    print("saved", name)


def swagger(browser):
    page = browser.new_page(viewport={"width": 1366, "height": 900})
    page.goto(f"{BASE}/swagger/index.html", wait_until="networkidle", timeout=120000)
    page.wait_for_selector(".opblock", timeout=60000)
    save(page, "m6_07_swagger_on_azure.png")

    block = page.locator("#operations-Auth-post_api_auth_login")
    block.locator(".opblock-summary").first.click()
    page.wait_for_timeout(400)
    block.locator("button.try-out__btn").click()
    block.locator("textarea.body-param__text").fill(
        json.dumps({"loginId": "vp@school.com", "password": "123"}, indent=2))
    block.locator("button.execute").click()
    block.locator(".live-responses-table").wait_for(timeout=60000)
    page.wait_for_timeout(600)
    # blur the real production JWT (the screenshot goes into a public repo)
    page.evaluate("""() => document.querySelectorAll('.live-responses-table span, .live-responses-table code')
        .forEach(e => { if (/eyJ[\\w-]{20,}/.test(e.textContent) && e.children.length === 0) e.style.filter = 'blur(5px)'; })""")
    block.scroll_into_view_if_needed()
    block.screenshot(path=str(OUT / "m6_08_swagger_azure_login.png"))
    print("saved m6_08_swagger_azure_login.png")
    page.close()


def newman(browser):
    cli = re.sub(r"\x1b\[[0-9;]*m", "", CLI_OUTPUT.read_text(encoding="utf-8", errors="ignore")).splitlines()
    start = next(i for i, l in enumerate(cli) if l.startswith("newman"))
    second = next(i for i, l in enumerate(cli) if re.match(r"^\S 2\. ", l))
    table_start = next(i for i, l in enumerate(cli) if l.startswith("┌"))
    table_end = next(i for i in range(table_start, len(cli)) if cli[i].startswith("└"))
    folder1 = ["# " + l[2:] if re.match(r"^\S \d\. ", l) else l.rstrip() for l in cli[start:second]]
    render(["PS D:\\desktop\\school_grading_app> postman\\run_tests_azure.cmd", ""] + folder1
           + ["   ...", ""] + [l.rstrip() for l in cli[table_start:table_end + 1]],
           OUT / "m6_09_newman_azure_cli.png", title="Newman against Azure - 0 failures", font_size=14)

    page = browser.new_page(viewport={"width": 1366, "height": 900})
    page.goto(REPORT.as_uri(), wait_until="networkidle")
    save(page, "m6_09b_newman_azure_html_report.png")
    page.close()


def actions(browser, run_url):
    page = browser.new_page(viewport={"width": 1366, "height": 860})
    page.goto(run_url, wait_until="networkidle", timeout=120000)
    page.wait_for_timeout(2000)
    save(page, "m6_05_github_actions_run.png")
    # open the job to show every step with a green tick
    page.get_by_role("link", name=re.compile("build-and-deploy")).first.click()
    page.wait_for_timeout(5000)
    save(page, "m6_06_github_actions_steps.png")
    page.close()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="msedge", headless=True)
        if "swagger" in sys.argv:
            swagger(browser)
        if "newman" in sys.argv:
            newman(browser)
        if "actions" in sys.argv:
            actions(browser, sys.argv[sys.argv.index("actions") + 1])
        browser.close()


if __name__ == "__main__":
    main()
