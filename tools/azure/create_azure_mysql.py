"""Milestone 3: create the cloud database with the Azure CLI (no portal clicking).

Creates, with the cheapest / free-tier settings only:
  Resource group  rg-school-grading
  Azure Database for MySQL Flexible Server 8.4, Burstable Standard_B1ms,
  20 GB storage (auto-grow OFF, auto-scale IOPS OFF), HA OFF,
  7-day locally-redundant backups (geo-redundant OFF),
  public access for this PC's IP + all Azure services (for the App Service later),
  and a $1/month budget alert.

The admin password is generated here and written ONLY to the git-ignored file
tools/azure/azure_mysql.local.json (never printed).

    az login              (once)
    tools\\.venv\\Scripts\\python -I tools\\azure\\create_azure_mysql.py
"""

import json
import secrets
import string
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "screenshots"))
from text_image import render  # noqa: E402

AZ = ROOT / "tools" / "azure-cli" / "bin" / "az.cmd"
CONFIG = Path(__file__).with_name("azure_mysql.local.json")    # secret, git-ignored
RESOURCES = Path(__file__).with_name("azure_resources.json")    # not secret: names + region
OUT = ROOT / "docs" / "screenshots"

RESOURCE_GROUP = "rg-school-grading"
REGIONS = ["uaenorth", "centralindia", "southeastasia", "westeurope", "eastus"]
ADMIN_USER = "gradingadmin"
BUDGET_NAME = "school-grading-budget"


class AzError(Exception):
    pass


def az(*args, secret: str | None = None):
    """Run one az command and return its JSON output (or None)."""
    result = subprocess.run([str(AZ), *args, "--only-show-errors", "-o", "json"],
                            capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        message = result.stderr.strip()
        if secret:
            message = message.replace(secret, "********")
        raise AzError(message)
    text = result.stdout.strip()
    return json.loads(text) if text else None


def new_password() -> str:
    # 24 characters: upper + lower + digits (meets Azure's complexity rules,
    # and no symbols that could break a connection string)
    alphabet = string.ascii_letters + string.digits
    while True:
        pw = "".join(secrets.choice(alphabet) for _ in range(24))
        if any(c.isupper() for c in pw) and any(c.islower() for c in pw) and any(c.isdigit() for c in pw):
            return pw


def my_public_ip() -> str:
    with urllib.request.urlopen("https://api.ipify.org", timeout=15) as r:
        return r.read().decode().strip()


def outbound_ips_on_3306(samples: int = 30) -> set[str]:
    import re
    found = set()
    for i in range(samples):
        try:
            with urllib.request.urlopen(f"http://portquiz.net:3306/?n={i}", timeout=10) as r:
                match = re.search(r"\b(\d{1,3}(?:\.\d{1,3}){3})\b", r.read().decode("utf-8", "ignore"))
                if match:
                    found.add(match.group(1))
        except OSError:
            pass
    return found


def allowed_regions_from_policy() -> list[str] | None:
    """Azure for Students limits which regions you may use (an 'allowed locations' policy)."""
    try:
        assignments = az("policy", "assignment", "list")
    except AzError:
        return None
    for a in assignments or []:
        for key, value in (a.get("parameters") or {}).items():
            if "location" in key.lower() and isinstance(value, dict) and isinstance(value.get("value"), list):
                return [v.lower() for v in value["value"]]
    return None


def main():
    log = ["PS> python tools\\azure\\create_azure_mysql.py", ""]

    # ---- 1. which subscription? ----
    account = az("account", "show")
    print("Subscription:", account["name"])
    if "student" not in account["name"].lower():
        sys.exit("The active subscription is not 'Azure for Students' - stopping (nothing created).")
    subscription_id = account["id"]
    log += [f"# Subscription: {account['name']} (state: {account['state']})", ""]

    # ---- 2. regions this subscription may use ----
    allowed = allowed_regions_from_policy()
    regions = [r for r in REGIONS if allowed is None or r in allowed]
    if allowed is not None:
        print("Allowed regions (policy):", ", ".join(allowed))
        extra = [r for r in allowed if r not in regions]
        regions += extra  # any other allowed region as a last resort
    print("Trying regions in this order:", ", ".join(regions))

    # ---- 3. the MySQL resource provider must be registered once ----
    print("Registering Microsoft.DBforMySQL provider (once per subscription)...")
    az("provider", "register", "--namespace", "Microsoft.DBforMySQL", "--wait")

    # ---- 4. password + names (password goes ONLY into the git-ignored file) ----
    server = "school-grading-mysql-" + "".join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(4))
    password = new_password()
    host = f"{server}.mysql.database.azure.com"
    CONFIG.write_text(json.dumps({"host": host, "user": ADMIN_USER, "password": password}, indent=2),
                      encoding="utf-8")
    ip = my_public_ip()
    print("Server name:", server, "| this PC's public IP will be allowed")

    # ---- 5. resource group + server, falling back to the next region if blocked ----
    chosen = None
    for region in regions:
        try:
            print(f"[{region}] creating resource group...")
            az("group", "create", "--name", RESOURCE_GROUP, "--location", region)
            print(f"[{region}] creating MySQL Flexible Server (takes 5-15 minutes)...")
            az("mysql", "flexible-server", "create",
               "--resource-group", RESOURCE_GROUP, "--name", server, "--location", region,
               "--version", "8.4",
               "--tier", "Burstable", "--sku-name", "Standard_B1ms",
               "--storage-size", "20", "--storage-auto-grow", "Disabled", "--auto-scale-iops", "Disabled",
               "--high-availability", "Disabled",
               "--backup-retention", "7", "--geo-redundant-backup", "Disabled",
               "--admin-user", ADMIN_USER, "--admin-password", password,
               "--public-access", ip,
               "--yes", secret=password)
            chosen = region
            break
        except AzError as e:
            reason = str(e).splitlines()[-1] if str(e) else "unknown error"
            print(f"[{region}] not possible: {reason[:300]}")
            # remove an empty resource group created in a region we could not use
            try:
                if not az("resource", "list", "--resource-group", RESOURCE_GROUP):
                    az("group", "delete", "--name", RESOURCE_GROUP, "--yes")
            except AzError:
                pass
    if chosen is None:
        sys.exit("Could not create the server in any allowed region.")
    print("Created in region:", chosen)

    # ---- 6. firewall: allow all Azure services (needed by App Service in Milestone 6) ----
    az("mysql", "flexible-server", "firewall-rule", "create",
       "--resource-group", RESOURCE_GROUP, "--name", server,
       "--rule-name", "AllowAllAzureServicesAndResourcesWithinAzureIps",
       "--start-ip-address", "0.0.0.0", "--end-ip-address", "0.0.0.0")

    # ---- 6b. some internet connections use SEVERAL public IPs (load-balanced lines).
    #          portquiz.net answers on port 3306 and shows which IP arrived,
    #          so we allow every IP this PC really uses for MySQL traffic.
    for n, extra_ip in enumerate(sorted(outbound_ips_on_3306() - {ip}), start=1):
        az("mysql", "flexible-server", "firewall-rule", "create",
           "--resource-group", RESOURCE_GROUP, "--name", server, "--rule-name", f"HomeInternet{n}",
           "--start-ip-address", extra_ip, "--end-ip-address", extra_ip)
        print(f"Also allowed outbound IP #{n + 1} of this internet connection")

    # ---- 7. $1 monthly budget alert (email to the subscription Owner) ----
    budget_status = create_budget(subscription_id)

    # ---- 8. read everything back from Azure and save a summary ----
    s = az("mysql", "flexible-server", "show", "--resource-group", RESOURCE_GROUP, "--name", server)
    rules = az("mysql", "flexible-server", "firewall-rule", "list",
               "--resource-group", RESOURCE_GROUP, "--name", server)
    summary = {
        "resourceGroup": RESOURCE_GROUP, "region": chosen, "server": server, "host": s["fullyQualifiedDomainName"],
        "adminUser": ADMIN_USER, "version": s["version"], "tier": s["sku"]["tier"], "sku": s["sku"]["name"],
        "storageGB": s["storage"]["storageSizeGb"], "storageAutoGrow": s["storage"]["autoGrow"],
        "autoScaleIops": s["storage"].get("autoIoScaling"), "iops": s["storage"].get("iops"),
        "highAvailability": s["highAvailability"]["mode"], "backupRetentionDays": s["backup"]["backupRetentionDays"],
        "geoRedundantBackup": s["backup"]["geoRedundantBackup"], "publicAccess": s["network"]["publicNetworkAccess"],
        "state": s["state"], "budget": budget_status,
    }
    RESOURCES.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    log += [
        f"az group create --name {RESOURCE_GROUP} --location {chosen}",
        f"az mysql flexible-server create --resource-group {RESOURCE_GROUP} --name {server} \\",
        f"    --location {chosen} --version 8.4 --tier Burstable --sku-name Standard_B1ms \\",
        "    --storage-size 20 --storage-auto-grow Disabled --auto-scale-iops Disabled \\",
        "    --high-availability Disabled --backup-retention 7 --geo-redundant-backup Disabled \\",
        f"    --admin-user {ADMIN_USER} --admin-password ******** --public-access <this PC's IP>",
        "az mysql flexible-server firewall-rule create ... --rule-name AllowAllAzureServicesAndResourcesWithinAzureIps \\",
        "    --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0",
        "",
        "# az mysql flexible-server show  (read back from Azure)",
        "",
    ]
    width = max(len(k) for k in summary)
    log += [f"  {k.ljust(width)} : {v}" for k, v in summary.items()]
    log += ["", "# Firewall rules", ""]
    log += [f"  {r['name']:<50} " + ("0.0.0.0 - 0.0.0.0  (all Azure services)"
                                       if r["startIpAddress"] == "0.0.0.0" else "<this PC's internet IP>")
            for r in rules]
    OUT.mkdir(parents=True, exist_ok=True)
    render(log, OUT / "m3_11_az_cli_create_server.png", title="Azure CLI - create MySQL Flexible Server",
           font_size=15)
    print("\n".join(log))
    print("\nsaved m3_11_az_cli_create_server.png")


def create_budget(subscription_id: str) -> str:
    url = (f"https://management.azure.com/subscriptions/{subscription_id}"
           f"/providers/Microsoft.Consumption/budgets/{BUDGET_NAME}?api-version=2023-05-01")
    body = {
        "properties": {
            "category": "Cost", "amount": 1, "timeGrain": "Monthly",
            "timePeriod": {"startDate": "2026-11-01T00:00:00Z", "endDate": "2027-10-31T00:00:00Z"},
            "notifications": {
                "Actual_GreaterThan_50_Percent": {
                    "enabled": True, "operator": "GreaterThan", "threshold": 50,
                    "contactEmails": [], "contactRoles": ["Owner"], "thresholdType": "Actual"},
                "Actual_GreaterThan_100_Percent": {
                    "enabled": True, "operator": "GreaterThan", "threshold": 100,
                    "contactEmails": [], "contactRoles": ["Owner"], "thresholdType": "Actual"},
            },
        }
    }
    body_file = Path(__file__).with_name("budget_body.local.json")
    body_file.write_text(json.dumps(body), encoding="utf-8")
    try:
        az("rest", "--method", "put", "--url", url, "--body", f"@{body_file}")
        status = "created ($1/month, alerts at 50% and 100% to the subscription Owner)"
    except AzError as e:
        status = "not supported on this subscription: " + str(e).splitlines()[-1][:200]
    finally:
        body_file.unlink(missing_ok=True)
    print("Budget:", status)
    return status


if __name__ == "__main__":
    main()
