/*
    Mini BOP - Phase 10
    Partitioning Strategy

    IMPORTANT:
    This script is intentionally non-destructive.

    It does NOT replace the existing TRADE, TRADE_EVENT or ETL tables.
    Instead, it creates partitioned demo/archive tables using CTAS + partition DDL
    so the strategy can be studied and validated safely.

    Why not ALTER existing tables directly?
    Oracle does not allow simple online conversion of a normal heap table into
    a partitioned table in all editions/scenarios without table redefinition.
    In real banks, partitioning is normally planned during design or applied via
    DBMS_REDEFINITION / controlled migration windows.
*/

PROMPT ===========================================
PROMPT MINI BOP - PHASE 10
PROMPT PARTITIONING STRATEGY DDL
PROMPT ===========================================

PROMPT Dropping demo partitioned objects if they exist...
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE trade_part_demo PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE trade_event_part_demo PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

PROMPT Creating partitioned demo table TRADE_PART_DEMO...
CREATE TABLE trade_part_demo
(
    trade_id           NUMBER          NOT NULL,
    external_trade_id  VARCHAR2(50)    NOT NULL,
    source_system      VARCHAR2(30)    NOT NULL,
    trade_date         DATE            NOT NULL,
    settlement_date    DATE,
    portfolio_id       NUMBER          NOT NULL,
    book_id            NUMBER          NOT NULL,
    counterparty_id    NUMBER          NOT NULL,
    instrument_id      NUMBER          NOT NULL,
    buy_sell           CHAR(1)         NOT NULL,
    quantity           NUMBER(18,4)    NOT NULL,
    trade_price        NUMBER(18,6)    NOT NULL,
    trade_currency     VARCHAR2(3)     NOT NULL,
    notional_amount    NUMBER(20,4),
    market_value       NUMBER(20,4),
    amount_eur         NUMBER(20,4),
    trade_status       VARCHAR2(20)    NOT NULL,
    created_at         TIMESTAMP       NOT NULL,
    updated_at         TIMESTAMP
)
PARTITION BY RANGE (trade_date)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
    PARTITION p_trade_before_2026 VALUES LESS THAN (DATE '2026-01-01')
);

PROMPT Loading current TRADE rows into TRADE_PART_DEMO...
INSERT INTO trade_part_demo
SELECT trade_id,
       external_trade_id,
       source_system,
       trade_date,
       settlement_date,
       portfolio_id,
       book_id,
       counterparty_id,
       instrument_id,
       buy_sell,
       quantity,
       trade_price,
       trade_currency,
       notional_amount,
       market_value,
       amount_eur,
       trade_status,
       created_at,
       updated_at
FROM trade;

COMMIT;

PROMPT Creating indexes on TRADE_PART_DEMO...
CREATE INDEX ix_trade_part_demo_date
    ON trade_part_demo (trade_date)
    LOCAL;

CREATE INDEX ix_trade_part_demo_book_date
    ON trade_part_demo (book_id, trade_date)
    LOCAL;

CREATE INDEX ix_trade_part_demo_counterparty
    ON trade_part_demo (counterparty_id)
    LOCAL;

CREATE UNIQUE INDEX ux_trade_part_demo_ext_src
    ON trade_part_demo (external_trade_id, source_system)
    GLOBAL;

PROMPT Creating partitioned demo table TRADE_EVENT_PART_DEMO...
CREATE TABLE trade_event_part_demo
(
    trade_event_id  NUMBER        NOT NULL,
    trade_id        NUMBER        NOT NULL,
    event_type      VARCHAR2(30)  NOT NULL,
    event_status    VARCHAR2(20)  NOT NULL,
    event_message   VARCHAR2(4000),
    created_at      TIMESTAMP     NOT NULL
)
PARTITION BY RANGE (created_at)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
(
    PARTITION p_event_before_2026 VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00')
);

PROMPT Loading current TRADE_EVENT rows into TRADE_EVENT_PART_DEMO...
INSERT INTO trade_event_part_demo
SELECT trade_event_id,
       trade_id,
       event_type,
       event_status,
       event_message,
       created_at
FROM trade_event;

COMMIT;

PROMPT Creating indexes on TRADE_EVENT_PART_DEMO...
CREATE INDEX ix_trade_event_part_demo_trade
    ON trade_event_part_demo (trade_id)
    LOCAL;

CREATE INDEX ix_trade_event_part_demo_created
    ON trade_event_part_demo (created_at)
    LOCAL;

PROMPT Gathering statistics...
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRADE_PART_DEMO');
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRADE_EVENT_PART_DEMO');
END;
/

PROMPT Partitioning strategy demo objects created.
