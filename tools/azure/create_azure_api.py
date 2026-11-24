"""Milestone 6: create the Azure App Service that hosts the ASP.NET Core API.

  App Service plan  plan-school-grading   Linux, FREE tier F1 ($0/month)
  Web app           school-grading-api-<suffix>   .NET 10, HTTPS only, FTP off
  App settings      ConnectionStrings__DefaultConnection  (Azure MySQL, SslMode=Required)
                    Jwt__Key                              (new random production secret)

Secrets are read from / written to git-ignored files only:
  tools/azure/azure_mysql.local.json      (database password, from Milestone 3)
  tools/azure/azure_api.local.json        (JWT key, created here)
  tools/azure/publish_profile.local.xml   (deployment credentials for GitHub Actions)

    tools\\.venv\\Scripts\\python -I tools\\azure\\create_azure_api.py
"""

import json
import secrets
import string
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "screenshots"))
from text_image import render  # noqa: E402

AZ = ROOT / "tools" / "azure-cli" / "bin" / "az.cmd"
HERE = Path(__file__).parent
DB_SECRETS = HERE / "azure_mysql.local.json"
API_SECRETS = HERE / "azure_api.local.json"
PUBLISH_PROFILE = HERE / "publish_profile.local.xml"
DB_RESOURCES = HERE / "azure_resources.json"
API_RESOURCES = HERE / "azure_api_resources.json"
OUT = ROOT / "docs" / "screenshots"

PLAN = "plan-school-grading"


def az(*args, parse=True):
    result = subprocess.run([str(AZ), *args, "--only-show-errors", "-o", "json" if parse else "none"],
                            capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        raise SystemExit("az " + " ".join(args[:3]) + " failed:\n" + result.stderr.strip()[-800:])
    return json.loads(result.stdout) if parse and result.stdout.strip() else None


def main():
    db = json.loads(DB_RESOURCES.read_text(encoding="utf-8"))
    db_secret = json.loads(DB_SECRETS.read_text(encoding="utf-8"))
    rg, region = db["resourceGroup"], db["region"]
    app = "school-grading-api-" + db["server"].rsplit("-", 1)[-1]   # same suffix as the database

    account = az("account", "show")
    if "student" not in account["name"].lower():
        sys.exit("Active subscription is not 'Azure for Students' - nothing created.")

    print("Registering Microsoft.Web provider (once per subscription)...")
    az("provider", "register", "--namespace", "Microsoft.Web", "--wait", parse=False)

    print(f"Creating App Service plan {PLAN} (Linux, F1 Free) in {region}...")
    az("appservice", "plan", "create", "--resource-group", rg, "--name", PLAN,
       "--location", region, "--sku", "F1", "--is-linux", parse=False)

    print(f"Creating web app {app} (.NET 10)...")
    az("webapp", "create", "--resource-group", rg, "--plan", PLAN, "--name", app,
       "--runtime", "DOTNETCORE:10.0", parse=False)

    print("HTTPS only, TLS 1.2+, FTP off, start command...")
    az("webapp", "update", "--resource-group", rg, "--name", app, "--https-only", "true", parse=False)
    az("webapp", "config", "set", "--resource-group", rg, "--name", app,
       "--startup-file", "dotnet SchoolGradingApi.dll",
       "--min-tls-version", "1.2", "--ftps-state", "Disabled", parse=False)

    # ---- secrets -> App Settings (= environment variables inside the app) ----
    if API_SECRETS.exists():
        jwt_key = json.loads(API_SECRETS.read_text(encoding="utf-8"))["jwtKey"]
    else:
        jwt_key = "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(64))
        API_SECRETS.write_text(json.dumps({"app": app, "jwtKey": jwt_key}, indent=2), encoding="utf-8")
    connection = (f"server={db_secret['host']};port=3306;database=school_grading;"
                  f"user={db_secret['user']};password={db_secret['password']};SslMode=Required;")
    settings_file = HERE / "app_settings.local.json"
    settings_file.write_text(json.dumps([
        {"name": "ConnectionStrings__DefaultConnection", "value": connection, "slotSetting": False},
        {"name": "Jwt__Key", "value": jwt_key, "slotSetting": False},
        {"name": "ASPNETCORE_ENVIRONMENT", "value": "Production", "slotSetting": False},
    ]), encoding="utf-8")
    try:
        print("Saving app settings (values are not printed)...")
        az("webapp", "config", "appsettings", "set", "--resource-group", rg, "--name", app,
           "--settings", f"@{settings_file}", parse=False)
    finally:
        settings_file.unlink(missing_ok=True)

    # ---- deployment credentials for GitHub Actions (publish profile) ----
    # New apps have "basic auth" publishing turned off; the publish profile needs it on SCM only.
    az("resource", "update", "--resource-group", rg, "--namespace", "Microsoft.Web",
       "--resource-type", "basicPublishingCredentialsPolicies", "--parent", f"sites/{app}",
       "--name", "scm", "--set", "properties.allow=true", parse=False)
    result = subprocess.run([str(AZ), "webapp", "deployment", "list-publishing-profiles",
                             "--resource-group", rg, "--name", app, "--xml", "--only-show-errors"],
                            capture_output=True, text=True, encoding="utf-8")
    if result.returncode != 0:
        raise SystemExit("could not read the publish profile:\n" + result.stderr[-500:])
    PUBLISH_PROFILE.write_text(result.stdout.strip().strip('"').replace('\\"', '"'), encoding="utf-8")
    print("Publish profile saved to the git-ignored file", PUBLISH_PROFILE.name)

    # ---- read back + summary (no secret values) ----
    site = az("webapp", "show", "--resource-group", rg, "--name", app)
    plan = az("appservice", "plan", "show", "--resource-group", rg, "--name", PLAN)
    config = az("webapp", "config", "show", "--resource-group", rg, "--name", app)
    names = [s["name"] for s in az("webapp", "config", "appsettings", "list", "--resource-group", rg, "--name", app)]
    summary = {
        "resourceGroup": rg, "region": region, "plan": PLAN,
        "planSku": f"{plan['sku']['tier']} {plan['sku']['name']}", "planOs": "Linux" if "linux" in plan.get("kind", "").lower() else "Windows",
        "app": app, "url": f"https://{site['defaultHostName']}", "runtime": config["linuxFxVersion"],
        "httpsOnly": site["httpsOnly"], "minTls": config["minTlsVersion"], "ftps": config["ftpsState"],
        "startup": config["appCommandLine"], "appSettings": names, "state": site["state"],
    }
    API_RESOURCES.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    log = ["PS> python tools\\azure\\create_azure_api.py", "",
           f"az appservice plan create --resource-group {rg} --name {PLAN} --location {region} --sku F1 --is-linux",
           f"az webapp create --resource-group {rg} --plan {PLAN} --name {app} --runtime DOTNETCORE:10.0",
           f"az webapp update --name {app} --https-only true",
           f"az webapp config set --name {app} --startup-file \"dotnet SchoolGradingApi.dll\" \\",
           "    --min-tls-version 1.2 --ftps-state Disabled",
           f"az webapp config appsettings set --name {app} --settings @<git-ignored file>",
           "", "# read back from Azure", ""]
    width = max(len(k) for k in summary)
    for k, v in summary.items():
        if k == "appSettings":
            v = ", ".join(v) + "   (values hidden)"
        log.append(f"  {k.ljust(width)} : {v}")
    render(log, OUT / "m6_01_az_cli_create_app_service.png", title="Azure CLI - App Service (F1 Free)",
           font_size=15)
    print("\n".join(log))
    print("\nsaved m6_01_az_cli_create_app_service.png")


if __name__ == "__main__":
    main()
