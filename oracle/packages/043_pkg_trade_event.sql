CREATE OR REPLACE PACKAGE pkg_trade_event AS

    PROCEDURE create_event(
        p_trade_id      NUMBER,
        p_event_type    VARCHAR2,
        p_event_status  VARCHAR2,
        p_event_message VARCHAR2 DEFAULT NULL
    );

    PROCEDURE trade_created(
        p_trade_id NUMBER,
        p_message  VARCHAR2 DEFAULT NULL
    );

    PROCEDURE trade_updated(
        p_trade_id NUMBER,
        p_message  VARCHAR2 DEFAULT NULL
    );

END pkg_trade_event;
/

CREATE OR REPLACE PACKAGE BODY pkg_trade_event AS

    FUNCTION next_trade_event_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(trade_event_id), 0) + 1
          INTO v_id
          FROM trade_event;

        RETURN v_id;
    END next_trade_event_id;

    FUNCTION normalize_event_type(p_event_type VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN SUBSTR(UPPER(TRIM(p_event_type)), 1, 30);
    END normalize_event_type;

    FUNCTION normalize_event_status(p_event_status VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN SUBSTR(UPPER(TRIM(p_event_status)), 1, 20);
    END normalize_event_status;

    PROCEDURE create_event(
        p_trade_id      NUMBER,
        p_event_type    VARCHAR2,
        p_event_status  VARCHAR2,
        p_event_message VARCHAR2 DEFAULT NULL
    ) IS
        v_trade_event_id NUMBER;
        v_event_type     trade_event.event_type%TYPE;
        v_event_status   trade_event.event_status%TYPE;
    BEGIN
        v_trade_event_id := next_trade_event_id;
        v_event_type     := normalize_event_type(p_event_type);
        v_event_status   := normalize_event_status(p_event_status);

        INSERT INTO trade_event (
            trade_event_id,
            trade_id,
            event_type,
            event_status,
            event_message,
            created_at
        ) VALUES (
            v_trade_event_id,
            p_trade_id,
            v_event_type,
            v_event_status,
            SUBSTR(p_event_message, 1, 4000),
            SYSTIMESTAMP
        );
    END create_event;

    PROCEDURE trade_created(
        p_trade_id NUMBER,
        p_message  VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        create_event(
            p_trade_id      => p_trade_id,
            p_event_type    => 'CAPTURE',
            p_event_status  => 'SUCCESS',
            p_event_message => NVL(p_message, 'TRADE_CREATED')
        );
    END trade_created;

    PROCEDURE trade_updated(
        p_trade_id NUMBER,
        p_message  VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        create_event(
            p_trade_id      => p_trade_id,
            p_event_type    => 'PROCESSING',
            p_event_status  => 'SUCCESS',
            p_event_message => NVL(p_message, 'TRADE_UPDATED')
        );
    END trade_updated;

END pkg_trade_event;
/
