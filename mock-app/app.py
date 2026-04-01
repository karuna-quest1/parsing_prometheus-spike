"""
Mock Application - Generates sample telemetry data for learning
This simulates a real application sending metrics, traces, and logs via OpenTelemetry
"""

import sys
import time
import random
import os

# Force unbuffered output
sys.stdout.reconfigure(line_buffering=True)
sys.stderr.reconfigure(line_buffering=True)

from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.resources import Resource

# Configuration
OTEL_ENDPOINT = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://otel-collector:4317")
SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "mock-demo-app")

print(f"🚀 Starting {SERVICE_NAME}")
print(f"📡 Sending metrics to: {OTEL_ENDPOINT}")

# Set up OpenTelemetry
resource = Resource.create({
    "service.name": SERVICE_NAME,
    "service.version": "1.0.0",
    "deployment.environment": "demo",
    "team": "platform",
})

# Configure metric exporter
metric_exporter = OTLPMetricExporter(
    endpoint=OTEL_ENDPOINT,
    insecure=True,
)

# Set up metric reader with 10-second export interval
metric_reader = PeriodicExportingMetricReader(
    metric_exporter,
    export_interval_millis=10000,
)

# Initialize MeterProvider
meter_provider = MeterProvider(
    resource=resource,
    metric_readers=[metric_reader],
)
metrics.set_meter_provider(meter_provider)

# Get a meter
meter = metrics.get_meter(__name__)

# Create various metric instruments
request_counter = meter.create_counter(
    name="http_requests_total",
    description="Total number of HTTP requests",
    unit="1",
)

response_time_histogram = meter.create_histogram(
    name="http_response_duration_seconds",
    description="HTTP response duration in seconds",
    unit="s",
)

active_users_gauge = meter.create_up_down_counter(
    name="active_users",
    description="Number of currently active users",
    unit="1",
)

cpu_temperature = meter.create_observable_gauge(
    name="system_cpu_temperature",
    description="Mock CPU temperature",
    unit="celsius",
    callbacks=[lambda options: [metrics.Observation(random.uniform(45, 85))]],
)

memory_usage = meter.create_observable_gauge(
    name="system_memory_usage_bytes",
    description="Mock memory usage in bytes",
    unit="bytes",
    callbacks=[lambda options: [metrics.Observation(random.uniform(2e9, 8e9))]],
)

system_cpu_utilization = meter.create_observable_gauge(
    name="system_cpu_utilization",
    description="Mock CPU utilization",
    unit="",
    callbacks=[lambda options: [metrics.Observation(0.95)]],
)

system_memory_utilization = meter.create_observable_gauge(
    name="system_memory_utilization",
    description="Mock memory utilization",
    unit="",
    callbacks=[lambda options: [metrics.Observation(0.95)]],
)


# Simulate application behavior
def simulate_traffic():
    """Simulate web traffic with varying patterns"""

    endpoints = ["/api/users", "/api/products", "/api/orders", "/api/health", "/api/metrics"]
    methods = ["GET", "POST", "PUT", "DELETE"]
    status_codes = [200, 201, 400, 404, 500]
    status_weights = [70, 10, 5, 10, 5]  # Mostly successful requests

    iteration = 0
    active_user_count = 0

    print("✅ Application started - generating metrics...\n")

    while True:
        iteration += 1

        # Simulate varying load throughout the day
        # Higher traffic during certain periods
        load_multiplier = 1 + abs(random.gauss(0, 0.3))
        num_requests = int(random.randint(5, 15) * load_multiplier)

        for _ in range(num_requests):
            # Generate random request
            endpoint = random.choice(endpoints)
            method = random.choice(methods)
            status = random.choices(status_codes, weights=status_weights)[0]

            # Simulate response time (slower for errors and POST/PUT)
            base_time = 0.05
            if status >= 500:
                response_time = random.uniform(1.0, 3.0)
            elif status >= 400:
                response_time = random.uniform(0.1, 0.5)
            elif method in ["POST", "PUT"]:
                response_time = random.uniform(0.1, 0.8)
            else:
                response_time = random.uniform(base_time, 0.3)

            # Record metrics
            request_counter.add(
                1,
                {
                    "endpoint": endpoint,
                    "method": method,
                    "status": str(status),
                }
            )

            response_time_histogram.record(
                response_time,
                {
                    "endpoint": endpoint,
                    "method": method,
                }
            )

        # Simulate user sessions (users join and leave)
        user_change = random.randint(-3, 5)
        active_user_count = max(0, active_user_count + user_change)
        active_users_gauge.add(user_change)

        # Print status every 10 iterations
        if iteration % 10 == 0:
            print(f"📊 Iteration {iteration} | Requests: {num_requests} | Active Users: {active_user_count}")

        # Wait before next batch
        time.sleep(5)

if __name__ == "__main__":
    try:
        simulate_traffic()
    except KeyboardInterrupt:
        print("\n👋 Shutting down gracefully...")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        # Flush remaining metrics
        meter_provider.force_flush()
        print("✅ Metrics flushed. Goodbye!")
