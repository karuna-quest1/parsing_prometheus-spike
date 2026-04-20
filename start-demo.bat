@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   GAP Stack - Complete Demo Launcher
echo   Grafana + Alertmanager + Prometheus
echo   with OpenTelemetry Collector
echo ========================================
echo.

REM Check if .env file exists
if not exist "%~dp0.env" (
    echo ERROR: Missing .env file at %~dp0.env
    echo.
    echo Please create a .env file with your configuration.
    echo See README.md for details.
    exit /b 1
)

echo [1/5] Stopping any existing containers...
docker-compose down -v 2>nul

echo.
echo [2/5] Generating Alertmanager config...
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\generate-alertmanager-config.ps1"
if errorlevel 1 (
    echo ERROR: Failed to generate Alertmanager config
    echo.
    echo If you're on Windows with Git Bash or WSL, you can also run:
    echo   bash start-demo.sh
    exit /b 1
)

echo.
echo [3/5] Building mock application...
docker-compose build --no-cache mock-app
if errorlevel 1 (
    echo ERROR: Failed to build mock application
    exit /b 1
)

echo.
echo [4/5] Starting all services...
docker-compose up -d
if errorlevel 1 (
    echo ERROR: Failed to start services
    exit /b 1
)

echo.
echo [5/5] Waiting for services to be ready...
timeout /t 15 /nobreak >nul

echo.
echo ========================================
echo   ALL SERVICES RUNNING!
echo ========================================
echo.
echo Access the following URLs:
echo.
echo   Grafana Dashboard:     http://localhost:12000
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
echo.
echo To stop all services, run:
echo   docker-compose down
echo.
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
start http://localhost:12000

echo.
echo Press any key to view live logs from mock app...
pause >nul

docker-compose logs -f mock-app
goto :eof

:error
echo.
echo Failed to generate Alertmanager config from .env.
exit /b 1
