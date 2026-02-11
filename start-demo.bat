@echo off
echo ========================================
echo   GAP Stack - Complete Demo Launcher
echo   Grafana + Alertmanager + Prometheus
echo   with OpenTelemetry Collector
echo ========================================
echo.

echo [1/4] Stopping any existing containers...
docker-compose down -v 2>nul

echo.
echo [2/4] Building mock application...
docker-compose build --no-cache mock-app

echo.
echo [3/4] Starting all services...
docker-compose up -d

echo.
echo [4/4] Waiting for services to be ready...
timeout /t 15 /nobreak >nul

echo.
echo ========================================
echo   ALL SERVICES RUNNING!
echo ========================================
echo.
echo Access the following URLs:
echo.
echo   Grafana Dashboard:     http://localhost:3000
echo   ^(Login: admin / admin^)
echo.
echo   Prometheus:            http://localhost:9090
echo   Alertmanager:          http://localhost:9093
echo   OTEL Collector:        http://localhost:8889/metrics
echo.
echo ========================================
echo   DEMO FEATURES
echo ========================================
echo.
echo   * Pre-configured Dashboard: "GAP Complete Monitoring Dashboard"
echo   * Real-time metrics from mock application
echo   * 10+ Alert rules monitoring the stack
echo   * OpenTelemetry data pipeline in action
echo   * Host system metrics collection
echo.
echo ========================================
echo.
echo Checking service health...
echo.

timeout /t 5 /nobreak >nul

docker-compose ps

echo.
echo ========================================
echo.
echo To view logs:           docker-compose logs -f
echo To view specific logs:  docker-compose logs -f mock-app
echo To stop:                docker-compose down
echo To stop and cleanup:    docker-compose down -v
echo.
echo ========================================
echo.
echo Opening Grafana in your browser...
timeout /t 3 /nobreak >nul
start http://localhost:3000

echo.
echo Press any key to view live logs from mock app...
pause >nul

docker-compose logs -f mock-app
