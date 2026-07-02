from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(..., examples=["OK"])
    service: str = Field(..., examples=["mini-bop-api"])
    phase: str = Field(..., examples=["25.1"])
    project_root: str = Field(..., examples=["/mnt/f/SSD_DEV/windows/projects/mini-bop"])


class PipelineStatusResponse(BaseModel):
    overall_status: str = Field(..., examples=["HEALTHY"])
    generated_at: Optional[str] = Field(None, examples=["2026-07-01T22:00:53.815592+00:00"])
    checks: Dict[str, Any] = Field(
        default_factory=dict,
        description="Raw Phase 24 checks keyed by check name.",
    )


class MonitoringCheckResponse(BaseModel):
    name: str = Field(..., examples=["spark_trade_curated"])
    status: str = Field(..., examples=["OK"])
    row_count: Optional[int] = Field(None, examples=[5])
    path: Optional[str] = Field(None, examples=["hdfs://localhost:9000/data/mini_bop/spark/trade_curated"])
    details: Optional[str] = Field(None, examples=["rows=5"])
    error: Optional[str] = Field(None, examples=[None])


class TradeRecord(BaseModel):
    trade_id: Optional[int] = Field(None, examples=[1])
    external_trade_id: Optional[str] = Field(None, examples=["TRD-000001"])
    trade_currency: Optional[str] = Field(None, examples=["EUR"])
    buy_sell: Optional[str] = Field(None, examples=["B"])
    notional_amount: Optional[float] = Field(None, examples=[98750000.0])
    amount_eur: Optional[float] = Field(None, examples=[98750000.0])
    trade_status: Optional[str] = Field(None, examples=["PROCESSED"])


class ExposureRow(BaseModel):
    trade_currency: Optional[str] = Field(None, examples=["EUR"])
    book_id: Optional[int] = Field(None, examples=[1])
    portfolio_id: Optional[int] = Field(None, examples=[1])
    counterparty_id: Optional[int] = Field(None, examples=[1])
    trade_count: Optional[int] = Field(None, examples=[4])
    total_amount_eur: Optional[float] = Field(None, examples=[114193750.0])
    total_notional_amount: Optional[float] = Field(None, examples=[114193750.0])


class CheckpointResponse(BaseModel):
    last_processed_batch_id: Optional[int] = Field(None, examples=[2])
    checkpoint_status: Optional[str] = Field(None, examples=["READY"])
    updated_at: Optional[str] = Field(None, examples=["2026-07-01 17:06:00"])


class ApiErrorResponse(BaseModel):
    detail: Any = Field(..., examples=[{"message": "Dataset not found or HDFS is unavailable."}])
    hint: Optional[str] = Field(None, examples=["Start HDFS with start-dfs.sh and retry."])
