#!/bin/bash

# Cross-platform start script for GAP Stack
# Works on Windows (Git Bash/WSL), macOS, and Linux

set -e

echo "========================================"
echo "  GAP Stack - Complete Demo Launcher"
echo "  Grafana + Alertmanager + Prometheus"
echo "  with OpenTelemetry Collector"
echo "========================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Function to print errors and exit
print_error() {
    echo "❌ ERROR: $1" >&2
    exit 1
}

# Function to print info
print_info() {
    echo "✓ $1"
}

# Step 1: Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    print_error "Docker Compose is not installed or not in PATH"
fi

# Step 2: Determine which docker-compose command to use
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

print_info "Using: $DOCKER_COMPOSE"
echo ""

# Step 3: Generate Alertmanager config
echo "[1/5] Generating Alertmanager config..."

if [ ! -f "$REPO_ROOT/.env" ]; then
    print_error "Missing .env file. Please create it with your configuration."
fi

# Run the bash script to generate config
if [ -f "$REPO_ROOT/scripts/generate-alertmanager-config.sh" ]; then
    bash "$REPO_ROOT/scripts/generate-alertmanager-config.sh" || print_error "Failed to generate Alertmanager config"
else
    print_error "Missing script: scripts/generate-alertmanager-config.sh"
fi

print_info "Alertmanager config generated"
echo ""

# Step 4: Stop any existing containers
echo "[2/5] Stopping any existing containers..."
cd "$REPO_ROOT"
$DOCKER_COMPOSE down -v 2>/dev/null || true
print_info "Existing containers stopped"
echo ""

# Step 5: Build mock application
echo "[3/5] Building mock application..."
$DOCKER_COMPOSE build --no-cache mock-app || print_error "Failed to build mock application"
print_info "Mock application built"
echo ""

# Step 6: Start all services
echo "[4/5] Starting all services..."
$DOCKER_COMPOSE up -d || print_error "Failed to start services"
print_info "All services started"
echo ""

# Step 7: Wait for services to be ready
echo "[5/5] Waiting for services to be ready..."
echo "(Waiting 15 seconds for all containers to initialize...)"
sleep 15
print_info "Services are ready"
echo ""

echo "========================================"
echo "  ALL SERVICES RUNNING!"
echo "========================================"
echo ""
echo "Access the following URLs:"
echo ""
echo "  🎨 Grafana Dashboard:     http://localhost:12000"
echo "     (Login: admin / admin)"
echo ""
echo "  📊 Prometheus:            http://localhost:9090"
echo "  🚨 Alertmanager:          http://localhost:9093"
echo "  📈 OTEL Collector:        http://localhost:8889/metrics"
echo ""
echo "========================================"
echo "  DEMO FEATURES"
echo "========================================"
echo ""
echo "  ✓ Pre-configured Dashboard: 12-panel monitoring dashboard"
echo "  ✓ Real-time metrics from mock application"
echo "  ✓ 13+ Alert rules monitoring the stack"
echo "  ✓ OpenTelemetry data pipeline in action"
echo "  ✓ Complete observability stack"
echo ""
echo "To stop all services, run:"
echo "  $DOCKER_COMPOSE down"
echo ""
