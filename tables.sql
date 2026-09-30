-- ============================================================
-- Reusable tables. Every table starts with DROP TABLE IF EXISTS
-- so this file can be re-run.
-- ============================================================

-- TASK 5: Bajaj moving averages (20 and 50 trading days)
DROP TABLE IF EXISTS bajaj1;
CREATE TABLE bajaj1 AS
SELECT
  date,
  close_price,
  CASE WHEN ROW_NUMBER() OVER (ORDER BY date) >= 20
       THEN ROUND(AVG(close_price) OVER (ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW), 2)
  END AS ma20,
  CASE WHEN ROW_NUMBER() OVER (ORDER BY date) >= 50
       THEN ROUND(AVG(close_price) OVER (ORDER BY date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW), 2)
  END AS ma50
FROM bajaj_auto;

-- TASK 6: master table of closing prices
DROP TABLE IF EXISTS master_table;
CREATE TABLE master_table AS
SELECT b.date,
       b.close_price AS bajaj,
       t.close_price AS tcs,
       v.close_price AS tvs,
       i.close_price AS infosys,
       e.close_price AS eicher,
       h.close_price AS hero
FROM bajaj_auto b
JOIN tcs t            ON t.date = b.date
JOIN tvs_motors v     ON v.date = b.date
JOIN infosys i        ON i.date = b.date
JOIN eicher_motors e  ON e.date = b.date
JOIN hero_motocorp h  ON h.date = b.date;

-- TASK 7: Bajaj golden-cross signals
DROP TABLE IF EXISTS bajaj2;
CREATE TABLE bajaj2 AS
WITH t AS (
  SELECT date, close_price, ma20, ma50,
         LAG(ma20) OVER (ORDER BY date) AS prev_ma20,
         LAG(ma50) OVER (ORDER BY date) AS prev_ma50
  FROM bajaj1
)
SELECT date, close_price,
  CASE
    WHEN ma50 IS NULL OR prev_ma50 IS NULL THEN 'Hold'
    WHEN ma20 > ma50 AND prev_ma20 <= prev_ma50 THEN 'Buy'
    WHEN ma20 < ma50 AND prev_ma20 >= prev_ma50 THEN 'Sell'
    ELSE 'Hold'
  END AS signal
FROM t;

-- TASK 10 (support): all six stocks stacked, plus moving averages and signals per stock
DROP TABLE IF EXISTS prices_all;
CREATE TABLE prices_all AS
SELECT 'Bajaj Auto' AS stock, date, close_price FROM bajaj_auto
UNION ALL SELECT 'Eicher Motors', date, close_price FROM eicher_motors
UNION ALL SELECT 'Hero Motocorp', date, close_price FROM hero_motocorp
UNION ALL SELECT 'Infosys',       date, close_price FROM infosys
UNION ALL SELECT 'TCS',           date, close_price FROM tcs
UNION ALL SELECT 'TVS Motors',    date, close_price FROM tvs_motors;

DROP TABLE IF EXISTS signals_all;
CREATE TABLE signals_all AS
WITH ma AS (
  SELECT stock, date, close_price,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date) >= 20
         THEN AVG(close_price) OVER (PARTITION BY stock ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) END AS ma20,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date) >= 50
         THEN AVG(close_price) OVER (PARTITION BY stock ORDER BY date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) END AS ma50
  FROM prices_all
),
lagged AS (
  SELECT *,
    LAG(ma20) OVER (PARTITION BY stock ORDER BY date) AS prev_ma20,
    LAG(ma50) OVER (PARTITION BY stock ORDER BY date) AS prev_ma50
  FROM ma
)
SELECT stock, date, close_price, ma20, ma50,
  CASE
    WHEN ma50 IS NULL OR prev_ma50 IS NULL THEN 'Hold'
    WHEN ma20 > ma50 AND prev_ma20 <= prev_ma50 THEN 'Buy'
    WHEN ma20 < ma50 AND prev_ma20 >= prev_ma50 THEN 'Sell'
    ELSE 'Hold'
  END AS signal
FROM lagged;

-- TASK 13: adjust for 1:1 bonus issues (Infosys 2015-06-15, TCS 2018-05-31)
-- Prices BEFORE the event date are divided by 2; prices on/after stay as they are.
DROP TABLE IF EXISTS adjusted_prices;
CREATE TABLE adjusted_prices AS
SELECT stock, date, close_price,
  CASE
    WHEN stock = 'Infosys' AND date < '2015-06-15' THEN close_price / 2.0
    WHEN stock = 'TCS'     AND date < '2018-05-31' THEN close_price / 2.0
    ELSE close_price
  END AS adj_close
FROM prices_all;

-- Signals rebuilt on ADJUSTED prices (stretch challenge)
DROP TABLE IF EXISTS signals_adjusted;
CREATE TABLE signals_adjusted AS
WITH ma AS (
  SELECT stock, date, adj_close AS close_price,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date) >= 20
         THEN AVG(adj_close) OVER (PARTITION BY stock ORDER BY date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) END AS ma20,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date) >= 50
         THEN AVG(adj_close) OVER (PARTITION BY stock ORDER BY date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) END AS ma50
  FROM adjusted_prices
),
lagged AS (
  SELECT *,
    LAG(ma20) OVER (PARTITION BY stock ORDER BY date) AS prev_ma20,
    LAG(ma50) OVER (PARTITION BY stock ORDER BY date) AS prev_ma50
  FROM ma
)
SELECT stock, date, close_price, ma20, ma50,
  CASE
    WHEN ma50 IS NULL OR prev_ma50 IS NULL THEN 'Hold'
    WHEN ma20 > ma50 AND prev_ma20 <= prev_ma50 THEN 'Buy'
    WHEN ma20 < ma50 AND prev_ma20 >= prev_ma50 THEN 'Sell'
    ELSE 'Hold'
  END AS signal
FROM lagged;
