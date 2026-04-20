# GAP Stack — Grafana, Alertmanager, Prometheus

A complete, production-ready demo of an observability stack with real-time data streaming, pre-configured dashboards, and active alerting.

## 🎯 What's Included

- **Prometheus** — Metrics collection and storage
- **Alertmanager** — Alert routing and management
- **Grafana** — Data visualization and dashboards (pre-configured!)
- **Node Exporter** — System metrics exporter (sample data source)
- **OpenTelemetry Collector** — Unified telemetry collection pipeline
- **Mock Application** — Generates realistic telemetry data for demonstration

## ⚡ Quick Start (Recommended)

### On macOS / Linux

```bash
chmod +x start-demo.sh
./start-demo.sh
```

### On Windows

**Option 1: Using Git Bash or WSL**
```bash
bash start-demo.sh
```

**Option 2: Using Command Prompt (native Windows)**
```bat
start-demo.bat
```

Then open Grafana at [http://localhost:3000](http://localhost:3000) — login: **admin** / **admin**

The dashboard will be pre-loaded with live data!

## ⚙️ Prerequisites

1. **Create a `.env` file** in the root directory with your configuration:
```env
SMTP_SMARTHOST=smtp.gmail.com:587
SMTP_FROM=alerts@example.com
SMTP_AUTH_USERNAME=alerts@example.com
SMTP_AUTH_PASSWORD=your-app-password-here
```

2. **Ensure Docker and Docker Compose are installed:**
   - [Docker Desktop](https://www.docker.com/products/docker-desktop) (includes Docker Compose)
   - Or install [Docker Engine](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/) separately

## 🎁 What You Get Out of the Box

- ✅ 12-panel pre-configured dashboard with real-time metrics
- ✅ 13 active alert rules monitoring your stack
- ✅ Live data streaming from mock application
- ✅ Complete OTEL pipeline (App → Collector → Prometheus → Grafana)
- ✅ Host system metrics (CPU, memory, disk, network)
- ✅ Automatic provisioning — everything works instantly!

## 📁 Project Structure

```
parsing_prometheus-spike/
├── start-demo.bat                           # 🚀 Demo launcher for Windows (native)
├── start-demo.sh                            # 🚀 Demo launcher for macOS/Linux/WSL
├── README.md                                # This file
├── .env                                     # Configuration file (you create this)
├── docker-compose.yml                       # Main orchestration file
├── prometheus/
│   ├── prometheus.yml                       # Prometheus configuration
│   └── alert_rules.yml                      # 13 alert definitions
├── alertmanager/
│   ├── alertmanager.yml                     # Alertmanager routing config (template)
│   └── alertmanager.generated.yml           # Generated config (created at startup)
├── scripts/
│   ├── generate-alertmanager-config.ps1     # Config generator (PowerShell)
│   └── generate-alertmanager-config.sh      # Config generator (Bash)
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── datasource.yml               # Auto-configure Prometheus
│       └── dashboards/
│           ├── dashboard.yml                # Dashboard provisioning
│           └── gap-complete-dashboard.json  # Pre-built 12-panel dashboard
├── otel-collector/
│   └── otel-config.yml                      # OpenTelemetry Collector config
└── mock-app/
    ├── app.py                               # Mock app generating metrics
    ├── Dockerfile                            # Container for mock app
    └── requirements.txt                     # Python dependencies
```

## 🚀 Configuration

### Create a `.env` file

Before starting the demo, create a `.env` file in the root directory with your configuration:

```env
# Alertmanager SMTP Configuration
SMTP_SMARTHOST=smtp.gmail.com:587
SMTP_FROM=alerts@example.com
SMTP_AUTH_USERNAME=alerts@example.com
SMTP_AUTH_PASSWORD=replace-with-app-password

# Optional: Email receivers
ALERT_EMAIL_DEFAULT_TO=ops@example.com
ALERT_EMAIL_WARNING_TO=team-alerts@example.com
ALERT_EMAIL_CRITICAL_TO=oncall@example.com

# Optional: Slack webhooks
SLACK_WEBHOOK_WARNING=https://hooks.slack.com/services/REPLACE/WARNING/WEBHOOK
SLACK_WEBHOOK_CRITICAL=https://hooks.slack.com/services/REPLACE/CRITICAL/WEBHOOK
SLACK_CHANNEL_WARNING=#gap-warning-alerts
SLACK_CHANNEL_CRITICAL=#gap-critical-alerts
```

**Note:** The startup script will automatically generate `alertmanager/alertmanager.generated.yml` by substituting variables from your `.env` file.

## 🚀 Manual Start

### 1. Generate Alertmanager Config

**On macOS / Linux / WSL:**
```bash
bash scripts/generate-alertmanager-config.sh
```

**On Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File scripts\generate-alertmanager-config.ps1
```

### 2. Start the Stack

```bash
docker-compose up -d
```

### Alert Destinations

Alertmanager now routes notifications by severity:

- `critical` alerts go to email and/or Slack
- `warning` alerts go to email and/or Slack  
- unmatched alerts fall back to the default email destination

All destination values are configured in your `.env` file.

### 2. Access the Services

| Service | URL | Notes |
|---------|-----|-------|
| **Grafana** | [http://localhost:3000](http://localhost:3000) | Login: admin / admin |
| **Prometheus** | [http://localhost:9090](http://localhost:9090) | Query interface and targets |
| **Alertmanager** | [http://localhost:9093](http://localhost:9093) | View and manage alerts |
| **Node Exporter** | [http://localhost:9100/metrics](http://localhost:9100/metrics) | Raw metrics endpoint |
| **OTEL Collector** | [http://localhost:8889/metrics](http://localhost:8889/metrics) | OTEL metrics endpoint |

### 3. Stop the Stack

```bash
docker-compose down
```

### 4. Stop and Remove All Data

```bash
docker-compose down -v
```

## 📊 Key Concepts

### Data Flow

```
Mock App → OTEL Collector → Prometheus → Grafana
                                ↓
                          Alertmanager → Notifications
```

### Alert Groups

1. **System Alerts** — Instance down, high CPU/memory, low disk, scrape failures
2. **Mock App Alerts** — Error rate, slow responses, request spikes, active users
3. **OTEL Collector Alerts** — Collector down, host CPU/memory utilization

## 🛠 Troubleshooting

| Issue | Solution |
|-------|----------|
| Prometheus not scraping | Check `http://localhost:9090/targets` for target status |
| Alerts not firing | Verify rules at `http://localhost:9090/rules` |
| Grafana no data | Ensure Prometheus datasource is configured in Grafana settings |
| Containers crashing | Run `docker-compose logs <service-name>` to check logs |

## 📚 Useful PromQL Queries

```promql
# Check if services are up
up

# Request rate per endpoint
sum by (endpoint) (rate(otel_http_requests_total[1m]))

# Error rate
sum(rate(otel_http_requests_total{status=~"5.."}[5m])) / sum(rate(otel_http_requests_total[5m]))

# Response time p95
histogram_quantile(0.95, sum by (le) (rate(otel_http_response_duration_seconds_bucket[5m])))

# CPU utilization
avg(otel_system_cpu_utilization) * 100

# Memory utilization
avg(otel_system_memory_utilization) * 100
```
