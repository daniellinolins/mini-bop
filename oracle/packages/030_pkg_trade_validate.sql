CREATE OR REPLACE PACKAGE pkg_trade_validate AS
    PROCEDURE validate_batch(p_batch_id NUMBER);
END pkg_trade_validate;
/

CREATE OR REPLACE PACKAGE BODY pkg_trade_validate AS

    FUNCTION next_error_id RETURN NUMBER IS
        v_error_id NUMBER;
    BEGIN
        SELECT NVL(MAX(stg_error_id), 0) + 1
          INTO v_error_id
          FROM stg_trade_error;

        RETURN v_error_id;
    END;

    PROCEDURE add_error(
        p_stg_trade_id  NUMBER,
        p_batch_id      NUMBER,
        p_error_code    VARCHAR2,
        p_error_message VARCHAR2,
        p_column_name   VARCHAR2 DEFAULT NULL
    ) IS
        v_error_id NUMBER;
    BEGIN
        v_error_id := next_error_id;

        INSERT INTO stg_trade_error (
            stg_error_id,
            stg_trade_id,
            batch_id,
            error_code,
            error_message,
            error_severity,
            column_name,
            created_at
        ) VALUES (
            v_error_id,
            p_stg_trade_id,
            p_batch_id,
            p_error_code,
            SUBSTR(p_error_message, 1, 1000),
            'ERROR',
            p_column_name,
            SYSTIMESTAMP
        );
    END add_error;

    PROCEDURE validate_batch(p_batch_id NUMBER) IS
        v_errors          NUMBER;
        v_trade_date      DATE;
        v_settlement_date DATE;
        v_quantity        NUMBER;
        v_price           NUMBER;
        v_exists          NUMBER;
    BEGIN
        pkg_log.info(p_batch_id, 'PKG_TRADE_VALIDATE', 'Starting trade validation');

        DELETE FROM stg_trade_error
         WHERE batch_id = p_batch_id;

        FOR r IN (
            SELECT *
              FROM stg_trade_raw
             WHERE batch_id = p_batch_id
               AND processing_status IN ('NEW', 'PENDING')
             ORDER BY stg_trade_id
        ) LOOP
            v_errors := 0;

            v_trade_date      := pkg_common.to_date_safe(r.trade_date_txt);
            v_settlement_date := pkg_common.to_date_safe(r.settlement_date_txt);
            v_quantity        := pkg_common.to_number_safe(r.quantity_txt);
            v_price           := pkg_common.to_number_safe(r.trade_price_txt);

            IF r.external_trade_id IS NULL THEN
                add_error(r.stg_trade_id, p_batch_id, 'EXT_TRADE_REQUIRED', 'External trade id is required', 'EXTERNAL_TRADE_ID');
                v_errors := v_errors + 1;
            END IF;

            IF v_trade_date IS NULL THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_TRADE_DATE', 'Trade date is invalid. Expected format YYYY-MM-DD', 'TRADE_DATE_TXT');
                v_errors := v_errors + 1;
            END IF;

            IF v_settlement_date IS NOT NULL AND v_trade_date IS NOT NULL AND v_settlement_date < v_trade_date THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_SETTLEMENT_DATE', 'Settlement date cannot be before trade date', 'SETTLEMENT_DATE_TXT');
                v_errors := v_errors + 1;
            END IF;

            IF pkg_common.normalize_buy_sell(r.buy_sell) IS NULL THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_BUY_SELL', 'Buy/Sell must be B, S, BUY or SELL', 'BUY_SELL');
                v_errors := v_errors + 1;
            END IF;

            IF v_quantity IS NULL OR v_quantity <= 0 THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_QUANTITY', 'Quantity must be greater than zero', 'QUANTITY_TXT');
                v_errors := v_errors + 1;
            END IF;

            IF v_price IS NULL OR v_price <= 0 THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_PRICE', 'Trade price must be greater than zero', 'TRADE_PRICE_TXT');
                v_errors := v_errors + 1;
            END IF;

            SELECT COUNT(*)
              INTO v_exists
              FROM currency
             WHERE currency_code = pkg_common.normalize_code(r.trade_currency);

            IF v_exists = 0 THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_CURRENCY', 'Currency does not exist', 'TRADE_CURRENCY');
                v_errors := v_errors + 1;
            END IF;

            SELECT COUNT(*)
              INTO v_exists
              FROM book
             WHERE book_code = pkg_common.normalize_code(r.book_code);

            IF v_exists = 0 THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_BOOK', 'Book does not exist', 'BOOK_CODE');
                v_errors := v_errors + 1;
            END IF;

            SELECT COUNT(*)
              INTO v_exists
              FROM portfolio
             WHERE portfolio_code = pkg_common.normalize_code(r.portfolio_code);

            IF v_exists = 0 THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_PORTFOLIO', 'Portfolio does not exist', 'PORTFOLIO_CODE');
                v_errors := v_errors + 1;
            END IF;

            SELECT COUNT(*)
              INTO v_exists
              FROM counterparty
             WHERE counterparty_code = pkg_common.normalize_code(r.counterparty_code);

            IF v_exists = 0 THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_COUNTERPARTY', 'Counterparty does not exist', 'COUNTERPARTY_CODE');
                v_errors := v_errors + 1;
            END IF;

            SELECT COUNT(*)
              INTO v_exists
              FROM instrument
             WHERE instrument_code = pkg_common.normalize_code(r.instrument_code);

            IF v_exists = 0 THEN
                add_error(r.stg_trade_id, p_batch_id, 'INVALID_INSTRUMENT', 'Instrument does not exist', 'INSTRUMENT_CODE');
                v_errors := v_errors + 1;
            END IF;

            UPDATE stg_trade_raw
               SET processing_status = CASE WHEN v_errors = 0 THEN 'VALIDATED' ELSE 'REJECTED' END,
                   error_count = v_errors,
                   processed_at = SYSTIMESTAMP
             WHERE stg_trade_id = r.stg_trade_id;
        END LOOP;

        pkg_log.info(p_batch_id, 'PKG_TRADE_VALIDATE', 'Trade validation finished');
    EXCEPTION
        WHEN OTHERS THEN
            pkg_log.error(p_batch_id, 'PKG_TRADE_VALIDATE', SQLERRM);
            RAISE;
    END validate_batch;

END pkg_trade_validate;
/
