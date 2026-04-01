import requests
import os
import json
from dotenv import load_dotenv
# ==============================
# CONFIGURATION
# ==============================

load_dotenv()
GRAFANA_URL = "http://localhost:3000"
API_TOKEN = os.getenv("GRAFANA_TOKEN") # <-- paste your service account token here
OUTPUT_DIR = "grafana_dashboards"

# ==============================
# SETUP
# ==============================
headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ==============================
# STEP 1: Get all dashboards
# ==============================
search_url = f"{GRAFANA_URL}/api/search"

response = requests.get(search_url, headers=headers)

if response.status_code != 200:
    print("Failed to fetch dashboards:", response.text)
    exit()

dashboards = response.json()

print(f"Found {len(dashboards)} dashboards")

# ==============================
# STEP 2: Download each dashboard
# ==============================
for dashboard in dashboards:
    uid = dashboard.get("uid")
    title = dashboard.get("title")

    if not uid:
        continue

    print(f"Downloading: {title} (UID: {uid})")

    dashboard_url = f"{GRAFANA_URL}/api/dashboards/uid/{uid}"
    dash_response = requests.get(dashboard_url, headers=headers)

    if dash_response.status_code != 200:
        print(f"Failed to download {title}")
        continue

    dash_json = dash_response.json()

    # Clean filename
    safe_title = "".join(c for c in title if c.isalnum() or c in (" ", "_")).rstrip()
    filename = os.path.join(OUTPUT_DIR, f"{safe_title}.json")

    with open(filename, "w") as f:
        json.dump(dash_json, f, indent=4)

print("✅ All dashboards exported successfully!")

results=[]
g_api_status = True

print("Grafana URL: ", GRAFANA_URL)
g_api_url = f"{GRAFANA_URL.rstrip('/')}/api/search"
try:
                # Use headers only here
    api_headers = {"Authorization": f"Bearer {API_TOKEN}"}
    print("Grafana api key: ",API_TOKEN)
    g_api_resp = requests.get(g_api_url, headers=api_headers, timeout=5, verify=False)
    print(g_api_resp)
except Exception as e:
    g_api_status = False
    g_api_msg = f"Grafana API Key: Validation Failed ({str(e)})"
    results.append(g_api_msg)

print(results)