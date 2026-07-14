"""
Python stack app (FastAPI + Gunicorn/Uvicorn workers).
Fronted by: Nginx (servers/nginx-python) -> proxied further by edge/nginx-edge.
"""
import os
import socket
import time

from fastapi import FastAPI, Response
from fastapi.responses import JSONResponse
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

APP_NAME = "python-app"
START_TIME = time.time()

app = FastAPI(title=APP_NAME)

REQUEST_COUNT = Counter(
    "app_requests_total", "Total requests", ["path", "method", "status"]
)
REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds", "Request latency", ["path"]
)


@app.middleware("http")
async def metrics_middleware(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    REQUEST_LATENCY.labels(path=request.url.path).observe(duration)
    REQUEST_COUNT.labels(
        path=request.url.path, method=request.method, status=response.status_code
    ).inc()
    return response


@app.get("/")
def root():
    return {
        "app": APP_NAME,
        "stack": "python-fastapi",
        "hostname": socket.gethostname(),
        "message": "Hello from the Python stack, routed via Nginx.",
    }


@app.get("/health")
def health():
    return {"status": "ok", "uptime_seconds": round(time.time() - START_TIME, 2)}


@app.get("/api/info")
def info():
    return JSONResponse(
        {
            "app": APP_NAME,
            "language": "Python",
            "framework": "FastAPI",
            "server": "Gunicorn + UvicornWorker",
            "container_host": socket.gethostname(),
            "env": os.getenv("APP_ENV", "development"),
        }
    )


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
