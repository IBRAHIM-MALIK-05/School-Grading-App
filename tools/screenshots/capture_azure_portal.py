"""Azure Portal screenshots (Milestone 3, later Milestone 6).

Opens a VISIBLE Brave window with its own browser profile
(tools/.azure_browser_profile, git-ignored). The first time you sign in to
your Azure for Students account in that window; the profile remembers it.
Before each screenshot the account name and subscription ID are blurred,
because the screenshots go into a public GitHub repository.

    tools\\.venv\\Scripts\\python -I tools\\screenshots\\capture_azure_portal.py
"""

import json
import subprocess
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "screenshots"
PROFILE = ROOT / "tools" / ".azure_browser_profile"
BRAVE = Path(r"C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe")
AZ = ROOT / "tools" / "azure-cli" / "bin" / "az.cmd"
RESOURCES = ROOT / "tools" / "azure" / "azure_resources.json"

# Blur: GUIDs (subscription / tenant IDs) and the signed-in account / directory name
BLUR_JS = r"""() => {
  const secret = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|@students|students\.|DEFAULT DIRECTORY/i;
  for (const el of document.querySelectorAll('body *')) {
    const own = [...el.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent).join('');
    if (own.trim() && secret.test(own)) el.style.filter = 'blur(6px)';
  }
}"""


def az_json(*args):
    out = subprocess.run([str(AZ), *args, "--only-show-errors", "-o", "json"],
                         capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def server_url():
    res = json.loads(RESOURCES.read_text(encoding="utf-8"))
    account = az_json("account", "show")
    return (f"https://portal.azure.com/#@{account['tenantId']}/resource/subscriptions/{account['id']}"
            f"/resourceGroups/{res['resourceGroup']}/providers/Microsoft.DBforMySQL"
            f"/flexibleServers/{res['server']}"), res


def frame_with_text(page, text, timeout_s):
    """The portal shows some pages inside iframes, so look in every frame."""
    end = time.time() + timeout_s
    while time.time() < end:
        for frame in page.frames:
            try:
                if frame.evaluate("t => !!document.body && document.body.innerText.includes(t)", text):
                    return frame
            except Exception:
                pass
        page.wait_for_timeout(1000)
    raise TimeoutError(f"'{text}' did not appear in the portal")


def tidy(page):
    """Close pop-ups and blur private details in every frame."""
    for label in ("Close", "Dismiss"):
        for btn in page.get_by_role("button", name=label, exact=True).all():
            try:
                if btn.is_visible():
                    btn.click(timeout=2000)
            except Exception:
                pass
    for frame in page.frames:
        try:
            frame.evaluate(BLUR_JS)
        except Exception:
            pass


def shot(page, name, wait_ms=5000):
    page.wait_for_timeout(wait_ms)  # portal pages load in pieces
    tidy(page)
    page.wait_for_timeout(800)
    page.screenshot(path=str(OUT / name))
    print("saved", name)


def open_menu_item(page, group, label):
    """Click an item in the resource's left menu, opening its group first."""
    item = page.get_by_text(label, exact=True)
    if item.count() == 0 or not item.first.is_visible():
        page.get_by_text(group, exact=True).first.click()
        page.wait_for_timeout(1200)
        item = page.get_by_text(label, exact=True)
    item.first.click()


def main():
    url, res = server_url()
    OUT.mkdir(parents=True, exist_ok=True)
    with sync_playwright() as p:
        context = p.chromium.launch_persistent_context(
            str(PROFILE), executable_path=str(BRAVE), headless=False,
            viewport={"width": 1440, "height": 860}, args=["--no-first-run"])
        page = context.pages[0] if context.pages else context.new_page()
        page.goto(url + "/overview")
        print(">>> If asked, sign in with your Azure for Students account in the Brave window.")
        frame_with_text(page, res["server"], timeout_s=15 * 60)  # time to sign in
        frame_with_text(page, "Burstable", timeout_s=120)
        shot(page, "m3_04_azure_portal_overview.png")

        open_menu_item(page, "Settings", "Compute + storage")
        frame_with_text(page, "Storage size", timeout_s=120)
        shot(page, "m3_05_azure_compute_storage.png")
        # (No Networking screenshot: it would show the home internet IP addresses.)
        context.close()


if __name__ == "__main__":
    main()
