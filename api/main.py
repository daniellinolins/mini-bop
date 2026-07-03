from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from api.models.schemas import (
    ApiErrorResponse,
    CheckpointResponse,
    ExposureRow,
    HealthResponse,
    MonitoringCheckResponse,
    PipelineStatusResponse,
    TradeRecord,
)
from api.services.spark_reader import MiniBopDataReader

PROJECT_ROOT = Path(os.environ.get("MINI_BOP_PROJECT_ROOT", Path.cwd()))
REPORT_PATH = PROJECT_ROOT / "monitoring" / "reports" / "pipeline_health.json"
TEMPLATES_DIR = PROJECT_ROOT / "api" / "templates"
STATIC_DIR = PROJECT_ROOT / "api" / "static"

templates = Jinja2Templates(directory=str(TEMPLATES_DIR))
reader = MiniBopDataReader()

app = FastAPI(
    title="Mini BOP REST API",
    description=(
        "REST API and lightweight dashboard for the Mini BOP Enterprise Data Engineering platform. "
        "The API exposes pipeline health, Spark/HDFS analytics, current trades, "
        "incremental checkpoint information and monitoring outputs generated in phases 20-24."
    ),
    version="25.1.1",
    contact={"name": "Daniel Lins"},
    openapi_tags=[
        {"name": "Health", "description": "API and platform health checks."},
        {"name": "Monitoring", "description": "Pipeline observability and monitoring reports from Phase 24."},
        {"name": "Trades", "description": "Current trades and top trade views from Spark/HDFS datasets."},
        {"name": "Analytics", "description": "Aggregated exposures and analytical outputs from Spark SQL layers."},
        {"name": "Incremental", "description": "Incremental processing, checkpoint and Delta Lake concept outputs."},
        {"name": "Dashboard", "description": "Human-readable HTML dashboard."},
    ],
)

if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


def _safe_rows(rows: Any) -> List[Dict[str, Any]]:
    if rows is None:
        return []
    if isinstance(rows, list):
        return rows
    try:
        return rows.toPandas().to_dict(orient="records")
    except Exception:
        try:
            return [r.asDict(recursive=True) for r in rows.collect()]
        except Exception as exc:
            raise HTTPException(
                status_code=503,
                detail={
                    "message": "Could not read Spark/HDFS dataset.",
                    "hint": "Confirm HDFS is running with jps/start-dfs.sh and that Phase 20-24 outputs exist.",
                    "error": str(exc),
                },
            ) from exc


def _limit(rows: List[Dict[str, Any]], limit: int) -> List[Dict[str, Any]]:
    return rows[: max(limit, 0)]


def _checks_dict(report: Dict[str, Any]) -> Dict[str, Any]:
    checks = report.get("checks", {})
    if isinstance(checks, dict):
        return checks
    if isinstance(checks, list):
        result: Dict[str, Any] = {}
        for item in checks:
            if isinstance(item, dict):
                name = str(item.get("name") or item.get("check") or f"check_{len(result) + 1}")
                result[name] = {k: v for k, v in item.items() if k not in {"name", "check"}}
        return result
    return {}


def _flatten_checks(report: Dict[str, Any]) -> List[Dict[str, Any]]:
    flattened: List[Dict[str, Any]] = []
    for name, payload in _checks_dict(report).items():
        item = payload if isinstance(payload, dict) else {"value": payload}
        details_parts: List[str] = []
        for key in ("row_count", "rows", "last_processed_batch_id", "checkpoint_status", "duplicate_keys", "exists"):
            if key in item and item.get(key) is not None:
                details_parts.append(f"{key}={item.get(key)}")
        flattened.append(
            {
                "name": name,
                "status": str(item.get("status", "UNKNOWN")),
                "row_count": item.get("row_count") if isinstance(item.get("row_count"), int) else None,
                "path": item.get("path"),
                "details": "; ".join(details_parts) if details_parts else None,
                "error": item.get("error"),
            }
        )
    return flattened


def _dashboard_metrics(report: Dict[str, Any], currency_rows: List[Dict[str, Any]], checkpoint_rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    checks = _checks_dict(report)
    current = checks.get("incremental_current_trades", {}) if isinstance(checks.get("incremental_current_trades"), dict) else {}
    checkpoint = checks.get("incremental_checkpoint", {}) if isinstance(checks.get("incremental_checkpoint"), dict) else {}
    return {
        "overall_status": report.get("overall_status", "UNKNOWN"),
        "total_trades": current.get("row_count", len(_safe_rows(reader.current_trades(limit=100)))) if current else 0,
        "currency_groups": len(currency_rows),
        "checkpoint_rows": checkpoint.get("row_count", len(checkpoint_rows)) if checkpoint else len(checkpoint_rows),
    }


@app.get(
    "/health",
    tags=["Health"],
    response_model=HealthResponse,
    summary="Check API health",
    description="Returns a lightweight API health response without reading Spark or HDFS.",
)
def health() -> Dict[str, str]:
    return {
        "status": "OK",
        "service": "mini-bop-api",
        "phase": "25.1",
        "project_root": str(PROJECT_ROOT),
    }


@app.get(
    "/pipeline/status",
    tags=["Monitoring"],
    response_model=PipelineStatusResponse,
    responses={503: {"model": ApiErrorResponse}},
    summary="Read latest pipeline health report",
    description="Reads monitoring/reports/pipeline_health.json generated by Phase 24.",
)
def pipeline_status() -> Dict[str, Any]:
    if not REPORT_PATH.exists():
        raise HTTPException(
            status_code=503,
            detail={
                "message": "Pipeline health report not found.",
                "hint": "Run bash monitoring/scripts/240_collect_pipeline_metrics.sh first.",
            },
        )
    return json.loads(REPORT_PATH.read_text(encoding="utf-8"))


@app.get(
    "/metrics",
    tags=["Monitoring"],
    response_model=List[MonitoringCheckResponse],
    summary="Return flattened monitoring checks",
    description=(
        "Returns the checks from the latest Phase 24 pipeline health report as a simple list. "
        "This endpoint is optimized for Swagger and dashboards. Use /monitoring/report for the raw JSON."
    ),
)
def metrics() -> List[Dict[str, Any]]:
    return _flatten_checks(pipeline_status())


@app.get(
    "/trades/current",
    tags=["Trades"],
    response_model=List[TradeRecord],
    responses={503: {"model": ApiErrorResponse}},
    summary="List current trades",
    description=(
        "Reads the Phase 22 silver_current_trades dataset. "
        "Use currency, status and limit to filter the response."
    ),
)
def current_trades(
    currency: Optional[str] = Query(
        None,
        description="Optional ISO currency filter. Common values in the sample data are EUR and USD.",
        examples=["EUR"],
    ),
    status: Optional[str] = Query(
        None,
        description="Optional trade status filter. Common values are PROCESSED and AMENDED.",
        examples=["PROCESSED"],
    ),
    limit: int = Query(20, ge=1, le=100, description="Maximum number of rows to return.", examples=[20]),
) -> List[Dict[str, Any]]:
    rows = _safe_rows(reader.current_trades())
    if currency:
        rows = [r for r in rows if str(r.get("trade_currency", "")).upper() == currency.upper()]
    if status:
        rows = [r for r in rows if str(r.get("trade_status", "")).upper() == status.upper()]
    return _limit(rows, limit)


@app.get(
    "/trades/top",
    tags=["Trades"],
    response_model=List[TradeRecord],
    responses={503: {"model": ApiErrorResponse}},
    summary="Return top trades by amount",
    description="Reads the analytics top trades dataset and returns the highest amount trades.",
)
def top_trades(
    limit: int = Query(5, ge=1, le=50, description="Number of top trades to return.", examples=[5])
) -> List[Dict[str, Any]]:
    return _limit(_safe_rows(reader.top_trades()), limit)


@app.get(
    "/exposure/currency",
    tags=["Analytics"],
    response_model=List[ExposureRow],
    responses={503: {"model": ApiErrorResponse}},
    summary="Exposure by currency",
    description="Returns Phase 21 gold exposure aggregated by currency. Sample values include EUR and USD.",
)
def exposure_by_currency(
    currency: Optional[str] = Query(None, description="Optional ISO currency filter, for example EUR or USD.", examples=["EUR"])
) -> List[Dict[str, Any]]:
    rows = _safe_rows(reader.exposure_by_currency())
    if currency and isinstance(currency, str):
        rows = [r for r in rows if str(r.get("trade_currency", "")).upper() == currency.upper()]
    return rows


@app.get(
    "/exposure/book",
    tags=["Analytics"],
    responses={503: {"model": ApiErrorResponse}},
    summary="Exposure by book",
    description="Returns Phase 21 gold exposure aggregated by book. book_id can be used to filter a single book.",
)
def exposure_by_book(
    book_id: Optional[int] = Query(None, description="Optional book identifier. Example values in the sample data: 1, 2, 3.", examples=[1])
) -> List[Dict[str, Any]]:
    rows = _safe_rows(reader.exposure_by_book())
    if book_id is not None:
        rows = [r for r in rows if int(r.get("book_id", -1)) == book_id]
    return rows


@app.get(
    "/incremental/checkpoint",
    tags=["Incremental"],
    response_model=List[CheckpointResponse],
    responses={503: {"model": ApiErrorResponse}},
    summary="Read incremental checkpoint",
    description="Returns the Phase 22 control_incremental_checkpoint dataset with the latest processed batch.",
)
def incremental_checkpoint() -> List[Dict[str, Any]]:
    return _safe_rows(reader.incremental_checkpoint())


@app.get(
    "/monitoring/report",
    tags=["Monitoring"],
    responses={503: {"model": ApiErrorResponse}},
    summary="Return full monitoring report",
    description="Returns the complete JSON monitoring report generated by Phase 24.",
)
def monitoring_report() -> Dict[str, Any]:
    return pipeline_status()


@app.get(
    "/dashboard",
    tags=["Dashboard"],
    response_class=HTMLResponse,
    summary="Open Mini BOP dashboard",
    description="Renders a simple HTML dashboard using the same data exposed by the REST endpoints.",
)
def dashboard(request: Request):
    status = pipeline_status()
    currency = exposure_by_currency(currency=None)
    top = top_trades(limit=5)
    checkpoint = incremental_checkpoint()
    checks = _flatten_checks(status)
    metrics_summary = _dashboard_metrics(status, currency, checkpoint)
    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "status": status,
            "metrics": metrics_summary,
            "currency": currency,
            "top": top,
            "checkpoint": checkpoint,
            "checks": checks,
        },
    )
