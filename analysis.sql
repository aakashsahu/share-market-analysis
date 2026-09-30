-- ============================================================
-- Task queries, SQLite syntax (used by the Streamlit app).
-- The MySQL 8 submission version is sql/stock_analysis_mysql.sql
-- Requires sql/tables.sql to have been run first.
-- Each block starts with "-- TASK n: title" (the app reads these).
-- ============================================================

-- TASK 1: How much history do we have?
SELECT COUNT(*) AS trading_days, MIN(date) AS first_day, MAX(date) AS last_day FROM bajaj_auto;

-- TASK 2: Eicher's five best closes
SELECT date, close_price FROM eicher_motors ORDER BY close_price DESC LIMIT 5;

-- TASK 3: TCS, year by year
SELECT strftime('%Y', date) AS year, ROUND(AVG(close_price), 2) AS avg_close
FROM tcs GROUP BY strftime('%Y', date) ORDER BY year;

-- TASK 4: Find the holes (NULL deliverable_qty)
SELECT 'bajaj_auto' AS stock, date FROM bajaj_auto WHERE deliverable_qty IS NULL
UNION ALL SELECT 'eicher_motors', date FROM eicher_motors WHERE deliverable_qty IS NULL
UNION ALL SELECT 'hero_motocorp', date FROM hero_motocorp WHERE deliverable_qty IS NULL
UNION ALL SELECT 'infosys', date FROM infosys WHERE deliverable_qty IS NULL
UNION ALL SELECT 'tcs', date FROM tcs WHERE deliverable_qty IS NULL
UNION ALL SELECT 'tvs_motors', date FROM tvs_motors WHERE deliverable_qty IS NULL;

-- TASK 5: Moving averages (table bajaj1, built in tables.sql; first non-NULL rows shown)
SELECT * FROM bajaj1 WHERE ma20 IS NOT NULL ORDER BY date LIMIT 5;

-- TASK 6: Master table (one row per date, closing price of each stock)
SELECT * FROM master_table ORDER BY date DESC LIMIT 5;

-- TASK 7: Golden cross signals (table bajaj2; Buy/Sell days shown)
SELECT * FROM bajaj2 WHERE signal <> 'Hold' ORDER BY date;

-- TASK 8: How often did it trigger?
SELECT signal, COUNT(*) AS days FROM bajaj2 GROUP BY signal ORDER BY signal;

-- TASK 9: Signal on a given day (2018-06-21)
SELECT signal FROM bajaj2 WHERE date = '2018-06-21';

-- TASK 10: All six stocks in one query
WITH counts AS (
  SELECT stock, SUM(signal = 'Buy') AS buys, SUM(signal = 'Sell') AS sells
  FROM signals_all GROUP BY stock
), latest AS (
  SELECT stock, date, signal,
         ROW_NUMBER() OVER (PARTITION BY stock ORDER BY date DESC) AS rn
  FROM signals_all WHERE signal <> 'Hold'
)
SELECT c.stock, c.buys, c.sells, l.date AS last_signal_date, l.signal AS last_signal
FROM counts c JOIN latest l ON l.stock = c.stock AND l.rn = 1
ORDER BY c.stock;

-- TASK 11: Who went up? (raw prices)
WITH ends AS (SELECT stock, MIN(date) AS f, MAX(date) AS l FROM prices_all GROUP BY stock)
SELECT e.stock, a.close_price AS first_close, b.close_price AS last_close,
       ROUND(100.0 * (b.close_price - a.close_price) / a.close_price, 1) AS pct_change
FROM ends e
JOIN prices_all a ON a.stock = e.stock AND a.date = e.f
JOIN prices_all b ON b.stock = e.stock AND b.date = e.l
ORDER BY pct_change DESC;

-- TASK 12: The data trap (worst single day per stock)
WITH m AS (
  SELECT stock, date, close_price,
         100.0 * (close_price / LAG(close_price) OVER (PARTITION BY stock ORDER BY date) - 1) AS pct_move
  FROM prices_all
), r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY stock ORDER BY pct_move) AS rn
  FROM m WHERE pct_move IS NOT NULL
)
SELECT stock, date, close_price, ROUND(pct_move, 1) AS pct_move FROM r WHERE rn = 1 ORDER BY pct_move;

-- TASK 13: Fix it (bonus-adjusted % change for TCS and Infosys)
WITH adjusted AS (
  SELECT 'TCS' AS stock, date,
         CASE WHEN date < '2018-05-31' THEN close_price / 2 ELSE close_price END AS adj_close
  FROM tcs
  UNION ALL
  SELECT 'Infosys', date,
         CASE WHEN date < '2015-06-15' THEN close_price / 2 ELSE close_price END
  FROM infosys
)
SELECT stock,
       ROUND(100.0 * (MAX(CASE WHEN date = '2018-07-31' THEN adj_close END)
                    / MAX(CASE WHEN date = '2015-01-01' THEN adj_close END) - 1), 1) AS adjusted_pct_change
FROM adjusted
WHERE date BETWEEN '2015-01-01' AND '2018-07-31'
GROUP BY stock ORDER BY stock;
