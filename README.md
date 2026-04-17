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

Just run this:

```bat
.\start-demo.bat
```

Then open Grafana at [http://localhost:3000](http://localhost:3000) — login: **admin** / **admin**

The dashboard will be pre-loaded with live data!

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
├── start-demo.bat                           # 🚀 One-click demo launcher
├── README.md                                # This file
├── docker-compose.yml                       # Main orchestration file
├── prometheus/
│   ├── prometheus.yml                       # Prometheus configuration
│   └── alert_rules.yml                      # 13 alert definitions
├── alertmanager/
│   └── alertmanager.yml                     # Alertmanager routing config
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

## 🚀 Manual Start

### 1. Start the Stack

```bash
docker-compose up -d
```

### Alert Destinations

Alertmanager now routes notifications by severity:

- `critical` alerts go to both Slack and email
- `warning` alerts go to both Slack and email
- unmatched alerts fall back to the default email destination

Set the destination values in `.env` before starting the stack:

```env
SMTP_SMARTHOST=smtp.gmail.com:587
SMTP_FROM=alerts@example.com
SMTP_AUTH_USERNAME=alerts@example.com
SMTP_AUTH_PASSWORD=replace-with-app-password
ALERT_EMAIL_DEFAULT_TO=ops@example.com
ALERT_EMAIL_WARNING_TO=team-alerts@example.com
ALERT_EMAIL_CRITICAL_TO=oncall@example.com
SLACK_WEBHOOK_WARNING=https://hooks.slack.com/services/REPLACE/WARNING/WEBHOOK
SLACK_WEBHOOK_CRITICAL=https://hooks.slack.com/services/REPLACE/CRITICAL/WEBHOOK
SLACK_CHANNEL_WARNING=#gap-warning-alerts
SLACK_CHANNEL_CRITICAL=#gap-critical-alerts
```

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
