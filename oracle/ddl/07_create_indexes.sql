-- ============================================================
-- Mini BOP - Fase 1
-- Script 07 - Indexes
-- Execute conectado como MINI_BOP.
-- ============================================================

CREATE INDEX ix_stg_trade_raw_batch_status ON stg_trade_raw(batch_id, processing_status);
CREATE INDEX ix_stg_trade_raw_ext ON stg_trade_raw(external_trade_id, source_system);
CREATE INDEX ix_stg_trade_error_trade ON stg_trade_error(stg_trade_id);
CREATE INDEX ix_trade_date ON trade(trade_date);
CREATE INDEX ix_trade_book_date ON trade(book_id, trade_date);
CREATE INDEX ix_trade_cp_date ON trade(counterparty_id, trade_date);
CREATE INDEX ix_trade_instr_date ON trade(instrument_id, trade_date);
CREATE INDEX ix_etl_log_batch ON etl_log(batch_id, created_at);

PROMPT Indexes created successfully.
