CREATE OR REPLACE PACKAGE pkg_common AS

    FUNCTION to_date_safe(p_value VARCHAR2) RETURN DATE;
    FUNCTION to_number_safe(p_value VARCHAR2) RETURN NUMBER;

    FUNCTION normalize_text(p_value VARCHAR2) RETURN VARCHAR2;
    FUNCTION normalize_code(p_value VARCHAR2) RETURN VARCHAR2;
    FUNCTION normalize_buy_sell(p_value VARCHAR2) RETURN CHAR;

    FUNCTION is_valid_buy_sell(p_value VARCHAR2) RETURN BOOLEAN;

END pkg_common;
/

CREATE OR REPLACE PACKAGE BODY pkg_common AS

    FUNCTION to_date_safe(p_value VARCHAR2) RETURN DATE IS
    BEGIN
        IF p_value IS NULL THEN
            RETURN NULL;
        END IF;

        RETURN TO_DATE(TRIM(p_value), 'YYYY-MM-DD');

    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END to_date_safe;

    FUNCTION to_number_safe(p_value VARCHAR2) RETURN NUMBER IS
        v_value VARCHAR2(100);
    BEGIN
        IF p_value IS NULL THEN
            RETURN NULL;
        END IF;

        v_value := TRIM(p_value);

        -- Normalize common decimal formats before conversion.
        -- Examples:
        -- 1000.25  -> 1000.25
        -- 1000,25  -> 1000.25
        -- 1,000.25 -> 1000.25
        -- 1.000,25 -> 1000.25
        IF INSTR(v_value, ',') > 0 AND INSTR(v_value, '.') > 0 THEN
            IF INSTR(v_value, ',') > INSTR(v_value, '.') THEN
                v_value := REPLACE(v_value, '.', '');
                v_value := REPLACE(v_value, ',', '.');
            ELSE
                v_value := REPLACE(v_value, ',', '');
            END IF;
        ELSE
            v_value := REPLACE(v_value, ',', '.');
        END IF;

        RETURN TO_NUMBER(v_value, '999999999999999999D999999999', 'NLS_NUMERIC_CHARACTERS=.,');

    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END to_number_safe;

    FUNCTION normalize_text(p_value VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_value IS NULL THEN
            RETURN NULL;
        END IF;

        RETURN UPPER(TRIM(p_value));
    END normalize_text;

    FUNCTION normalize_code(p_value VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN normalize_text(p_value);
    END normalize_code;

    FUNCTION normalize_buy_sell(p_value VARCHAR2) RETURN CHAR IS
        v_value VARCHAR2(20);
    BEGIN
        v_value := normalize_text(p_value);

        IF v_value IN ('B', 'BUY') THEN
            RETURN 'B';
        ELSIF v_value IN ('S', 'SELL') THEN
            RETURN 'S';
        END IF;

        RETURN NULL;
    END normalize_buy_sell;

    FUNCTION is_valid_buy_sell(p_value VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN normalize_buy_sell(p_value) IS NOT NULL;
    END is_valid_buy_sell;

END pkg_common;
/
