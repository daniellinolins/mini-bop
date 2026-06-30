CREATE OR REPLACE PACKAGE pkg_trade_types AS

    TYPE trade_rec IS RECORD (
        external_trade_id trade.external_trade_id%TYPE,
        source_system     trade.source_system%TYPE,
        trade_date        trade.trade_date%TYPE,
        settlement_date   trade.settlement_date%TYPE,
        portfolio_id      trade.portfolio_id%TYPE,
        book_id           trade.book_id%TYPE,
        counterparty_id   trade.counterparty_id%TYPE,
        instrument_id     trade.instrument_id%TYPE,
        buy_sell          trade.buy_sell%TYPE,
        quantity          trade.quantity%TYPE,
        trade_price       trade.trade_price%TYPE,
        trade_currency    trade.trade_currency%TYPE,
        notional_amount   trade.notional_amount%TYPE,
        market_value      trade.market_value%TYPE,
        amount_eur        trade.amount_eur%TYPE,
        trade_status      trade.trade_status%TYPE
    );

END pkg_trade_types;
/
