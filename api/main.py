from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, List

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

try:
    from services.spark_reader import MiniBopDataReader
except ModuleNotFoundError:
    from api.services.spark_reader import MiniBopDataReader

PROJECT_ROOT = Path(os.environ.get("MINI_BOP_PROJECT_ROOT", "/mnt/f/SSD_DEV/windows/projects/mini-bop"))
MONITORING_REPORT = PROJECT_ROOT / "monitoring" / "reports" / "pipeline_health.json"

app = FastAPI(
    title="Mini BOP Analytics API",
    description="REST API and dashboard exposing Mini BOP Spark/HDFS analytics outputs.",
    version="25.0.0",
)

BASE_DIR = Path(__file__).resolve().parent
app.mount("/static", StaticFiles(directory=str(BASE_DIR / "static")), name="static")
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))
reader = MiniBopDataReader()


def _load_monitoring_report() -> Dict[str, Any]:
    if MONITORING_REPORT.exists():
        with MONITORING_REPORT.open("r", encoding="utf-8") as f:
            return json.load(f)
    return {
        "overall_status": "UNKNOWN",
        "message": f"Monitoring report not found at {MONITORING_REPORT}",
        "checks": [],
    }


@app.get("/health")
def health() -> Dict[str, Any]:
    return {
        "status": "OK",
        "service": "mini-bop-analytics-api",
        "project_root": str(PROJECT_ROOT),
    }


@app.get("/pipeline/status")
def pipeline_status() -> Dict[str, Any]:
    return _load_monitoring_report()


@app.get("/metrics")
def metrics() -> Dict[str, Any]:
    report = _load_monitoring_report()
    checks = report.get("checks", [])
    return {
        "overall_status": report.get("overall_status", "UNKNOWN"),
        "generated_at": report.get("generated_at"),
        "checks_count": len(checks),
        "ok_checks": len([c for c in checks if c.get("status") == "OK"]),
        "error_checks": len([c for c in checks if c.get("status") == "ERROR"]),
        "checks": checks,
    }


@app.get("/trades/current")
def current_trades(limit: int = 50) -> Dict[str, Any]:
    rows = reader.current_trades(limit=limit)
    return {"count": len(rows), "rows": rows}


@app.get("/trades/top")
def top_trades(limit: int = 10) -> Dict[str, Any]:
    rows = reader.top_trades(limit=limit)
    return {"count": len(rows), "rows": rows}


@app.get("/exposure/currency")
def exposure_by_currency() -> Dict[str, Any]:
    rows = reader.exposure_by_currency()
    return {"count": len(rows), "rows": rows}


@app.get("/exposure/book")
def exposure_by_book() -> Dict[str, Any]:
    rows = reader.exposure_by_book()
    return {"count": len(rows), "rows": rows}


@app.get("/incremental/checkpoint")
def incremental_checkpoint() -> Dict[str, Any]:
    rows = reader.incremental_checkpoint()
    return {"count": len(rows), "rows": rows}


@app.get("/monitoring/report")
def monitoring_report() -> Dict[str, Any]:
    return _load_monitoring_report()


@app.get("/dashboard", response_class=HTMLResponse)
def dashboard(request: Request) -> HTMLResponse:
    report = _load_monitoring_report()
    currency = reader.exposure_by_currency()
    top = reader.top_trades(limit=5)
    checkpoint = reader.incremental_checkpoint()
    trades = reader.current_trades(limit=10)
    metrics = {
        "overall_status": report.get("overall_status", "UNKNOWN"),
        "total_trades": len(trades),
        "currency_groups": len(currency),
        "top_trade_rows": len(top),
        "checkpoint_rows": len(checkpoint),
    }
    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "metrics": metrics,
            "currency": currency,
            "top": top,
            "checkpoint": checkpoint,
            "checks": report.get("checks", []),
        },
    )
