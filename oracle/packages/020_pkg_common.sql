CREATE OR REPLACE PACKAGE pkg_common AS
    FUNCTION to_date_safe(p_value VARCHAR2) RETURN DATE;
    FUNCTION to_number_safe(p_value VARCHAR2) RETURN NUMBER;
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
    END;

    FUNCTION to_number_safe(p_value VARCHAR2) RETURN NUMBER IS
    BEGIN
        IF p_value IS NULL THEN
            RETURN NULL;
        END IF;

        RETURN TO_NUMBER(REPLACE(TRIM(p_value), ',', '.'));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION is_valid_buy_sell(p_value VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN UPPER(TRIM(p_value)) IN ('B', 'S', 'BUY', 'SELL');
    END;

END pkg_common;
/