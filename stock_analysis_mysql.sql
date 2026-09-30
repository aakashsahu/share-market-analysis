-- =====================================================================
-- STOCK MARKET ANALYSIS: pure SQL solution (MySQL 8.0+)
-- Six NSE stocks, 2015-01-01 to 2018-07-31.
-- Runs top to bottom on a fresh database. Every table starts with
-- DROP TABLE IF EXISTS so the file can be re-run.
--
-- BEFORE RUNNING: edit the six file paths in SECTION A, and enable
--   SET GLOBAL local_infile = 1;   (Workbench: OPT_LOCAL_INFILE=1)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS stock_analysis;
USE stock_analysis;

-- ---------------------------------------------------------------------
-- SECTION A: load the CSVs (dates like 31-July-2018 -> DATE, '' -> NULL)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS bajaj_auto;
CREATE TABLE bajaj_auto (
  `date` DATE PRIMARY KEY,
  open_price DECIMAL(12,2), high_price DECIMAL(12,2), low_price DECIMAL(12,2),
  close_price DECIMAL(12,2), wap DECIMAL(16,4),
  no_of_shares BIGINT, no_of_trades BIGINT, total_turnover DECIMAL(20,2),
  deliverable_qty BIGINT, pct_deli_qty DECIMAL(6,2),
  spread_high_low DECIMAL(12,2), spread_close_open DECIMAL(12,2)
);
LOAD DATA LOCAL INFILE '/path/to/Bajaj_Auto.csv' INTO TABLE bajaj_auto
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@d,@o,@h,@l,@c,@w,@s,@tr,@to,@dq,@pd,@shl,@sco)
SET `date` = STR_TO_DATE(@d, '%d-%M-%Y'),
  open_price = NULLIF(@o,''), high_price = NULLIF(@h,''), low_price = NULLIF(@l,''),
  close_price = NULLIF(@c,''), wap = NULLIF(@w,''), no_of_shares = NULLIF(@s,''),
  no_of_trades = NULLIF(@tr,''), total_turnover = NULLIF(@to,''),
  deliverable_qty = NULLIF(@dq,''), pct_deli_qty = NULLIF(@pd,''),
  spread_high_low = NULLIF(@shl,''), spread_close_open = NULLIF(TRIM(@sco),'');

DROP TABLE IF EXISTS eicher_motors;
CREATE TABLE eicher_motors LIKE bajaj_auto;
LOAD DATA LOCAL INFILE '/path/to/Eicher_Motors.csv' INTO TABLE eicher_motors
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@d,@o,@h,@l,@c,@w,@s,@tr,@to,@dq,@pd,@shl,@sco)
SET `date` = STR_TO_DATE(@d, '%d-%M-%Y'),
  open_price = NULLIF(@o,''), high_price = NULLIF(@h,''), low_price = NULLIF(@l,''),
  close_price = NULLIF(@c,''), wap = NULLIF(@w,''), no_of_shares = NULLIF(@s,''),
  no_of_trades = NULLIF(@tr,''), total_turnover = NULLIF(@to,''),
  deliverable_qty = NULLIF(@dq,''), pct_deli_qty = NULLIF(@pd,''),
  spread_high_low = NULLIF(@shl,''), spread_close_open = NULLIF(TRIM(@sco),'');

DROP TABLE IF EXISTS hero_motocorp;
CREATE TABLE hero_motocorp LIKE bajaj_auto;
LOAD DATA LOCAL INFILE '/path/to/Hero_Motocorp.csv' INTO TABLE hero_motocorp
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@d,@o,@h,@l,@c,@w,@s,@tr,@to,@dq,@pd,@shl,@sco)
SET `date` = STR_TO_DATE(@d, '%d-%M-%Y'),
  open_price = NULLIF(@o,''), high_price = NULLIF(@h,''), low_price = NULLIF(@l,''),
  close_price = NULLIF(@c,''), wap = NULLIF(@w,''), no_of_shares = NULLIF(@s,''),
  no_of_trades = NULLIF(@tr,''), total_turnover = NULLIF(@to,''),
  deliverable_qty = NULLIF(@dq,''), pct_deli_qty = NULLIF(@pd,''),
  spread_high_low = NULLIF(@shl,''), spread_close_open = NULLIF(TRIM(@sco),'');

DROP TABLE IF EXISTS infosys;
CREATE TABLE infosys LIKE bajaj_auto;
LOAD DATA LOCAL INFILE '/path/to/Infosys.csv' INTO TABLE infosys
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@d,@o,@h,@l,@c,@w,@s,@tr,@to,@dq,@pd,@shl,@sco)
SET `date` = STR_TO_DATE(@d, '%d-%M-%Y'),
  open_price = NULLIF(@o,''), high_price = NULLIF(@h,''), low_price = NULLIF(@l,''),
  close_price = NULLIF(@c,''), wap = NULLIF(@w,''), no_of_shares = NULLIF(@s,''),
  no_of_trades = NULLIF(@tr,''), total_turnover = NULLIF(@to,''),
  deliverable_qty = NULLIF(@dq,''), pct_deli_qty = NULLIF(@pd,''),
  spread_high_low = NULLIF(@shl,''), spread_close_open = NULLIF(TRIM(@sco),'');

DROP TABLE IF EXISTS tcs;
CREATE TABLE tcs LIKE bajaj_auto;
LOAD DATA LOCAL INFILE '/path/to/TCS.csv' INTO TABLE tcs
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@d,@o,@h,@l,@c,@w,@s,@tr,@to,@dq,@pd,@shl,@sco)
SET `date` = STR_TO_DATE(@d, '%d-%M-%Y'),
  open_price = NULLIF(@o,''), high_price = NULLIF(@h,''), low_price = NULLIF(@l,''),
  close_price = NULLIF(@c,''), wap = NULLIF(@w,''), no_of_shares = NULLIF(@s,''),
  no_of_trades = NULLIF(@tr,''), total_turnover = NULLIF(@to,''),
  deliverable_qty = NULLIF(@dq,''), pct_deli_qty = NULLIF(@pd,''),
  spread_high_low = NULLIF(@shl,''), spread_close_open = NULLIF(TRIM(@sco),'');

DROP TABLE IF EXISTS tvs_motors;
CREATE TABLE tvs_motors LIKE bajaj_auto;
LOAD DATA LOCAL INFILE '/path/to/TVS_Motors.csv' INTO TABLE tvs_motors
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(@d,@o,@h,@l,@c,@w,@s,@tr,@to,@dq,@pd,@shl,@sco)
SET `date` = STR_TO_DATE(@d, '%d-%M-%Y'),
  open_price = NULLIF(@o,''), high_price = NULLIF(@h,''), low_price = NULLIF(@l,''),
  close_price = NULLIF(@c,''), wap = NULLIF(@w,''), no_of_shares = NULLIF(@s,''),
  no_of_trades = NULLIF(@tr,''), total_turnover = NULLIF(@to,''),
  deliverable_qty = NULLIF(@dq,''), pct_deli_qty = NULLIF(@pd,''),
  spread_high_low = NULLIF(@shl,''), spread_close_open = NULLIF(TRIM(@sco),'');

-- check: 889 rows each
SELECT COUNT(*), MIN(`date`), MAX(`date`) FROM bajaj_auto;

-- ---------------------------------------------------------------------
-- PART 1: get to know the data
-- ---------------------------------------------------------------------

-- TASK 1: how much history?  (expect 889, 2015-01-01, 2018-07-31)
SELECT COUNT(*) AS trading_days, MIN(`date`) AS first_day, MAX(`date`) AS last_day
FROM bajaj_auto;

-- TASK 2: Eicher's five best closes
SELECT `date`, close_price FROM eicher_motors ORDER BY close_price DESC LIMIT 5;

-- TASK 3: TCS year by year  (2016 average = 2419.00)
SELECT YEAR(`date`) AS `year`, ROUND(AVG(close_price), 2) AS avg_close
FROM tcs
GROUP BY YEAR(`date`)
ORDER BY `year`;

-- TASK 4: find the holes (NULL deliverable_qty)
SELECT 'bajaj_auto' AS stock, `date` FROM bajaj_auto WHERE deliverable_qty IS NULL
UNION ALL
SELECT 'eicher_motors', `date` FROM eicher_motors WHERE deliverable_qty IS NULL
UNION ALL
SELECT 'hero_motocorp', `date` FROM hero_motocorp WHERE deliverable_qty IS NULL
UNION ALL
SELECT 'infosys', `date` FROM infosys WHERE deliverable_qty IS NULL
UNION ALL
SELECT 'tcs', `date` FROM tcs WHERE deliverable_qty IS NULL
UNION ALL
SELECT 'tvs_motors', `date` FROM tvs_motors WHERE deliverable_qty IS NULL;

-- ---------------------------------------------------------------------
-- PART 2: the assignment
-- ---------------------------------------------------------------------

-- TASK 5: bajaj1 = date, close_price, ma20, ma50
DROP TABLE IF EXISTS bajaj1;
CREATE TABLE bajaj1 AS
SELECT
  `date`,
  close_price,
  CASE WHEN ROW_NUMBER() OVER (ORDER BY `date`) >= 20
       THEN ROUND(AVG(close_price) OVER (ORDER BY `date` ROWS BETWEEN 19 PRECEDING AND CURRENT ROW), 2)
  END AS ma20,
  CASE WHEN ROW_NUMBER() OVER (ORDER BY `date`) >= 50
       THEN ROUND(AVG(close_price) OVER (ORDER BY `date` ROWS BETWEEN 49 PRECEDING AND CURRENT ROW), 2)
  END AS ma50
FROM bajaj_auto;

-- TASK 6: master_table (one row per date, closing price of every stock)
DROP TABLE IF EXISTS master_table;
CREATE TABLE master_table AS
SELECT b.`date`,
       b.close_price AS bajaj,
       t.close_price AS tcs,
       v.close_price AS tvs,
       i.close_price AS infosys,
       e.close_price AS eicher,
       h.close_price AS hero
FROM bajaj_auto b
JOIN tcs t           ON t.`date` = b.`date`
JOIN tvs_motors v    ON v.`date` = b.`date`
JOIN infosys i       ON i.`date` = b.`date`
JOIN eicher_motors e ON e.`date` = b.`date`
JOIN hero_motocorp h ON h.`date` = b.`date`;

-- TASK 7: bajaj2 = date, close_price, signal (Buy / Sell / Hold)
DROP TABLE IF EXISTS bajaj2;
CREATE TABLE bajaj2 AS
WITH t AS (
  SELECT `date`, close_price, ma20, ma50,
         LAG(ma20) OVER (ORDER BY `date`) AS prev_ma20,
         LAG(ma50) OVER (ORDER BY `date`) AS prev_ma50
  FROM bajaj1
)
SELECT `date`, close_price,
  CASE
    WHEN ma50 IS NULL OR prev_ma50 IS NULL THEN 'Hold'
    WHEN ma20 > ma50 AND prev_ma20 <= prev_ma50 THEN 'Buy'
    WHEN ma20 < ma50 AND prev_ma20 >= prev_ma50 THEN 'Sell'
    ELSE 'Hold'
  END AS `signal`
FROM t;

-- TASK 8: how often did it trigger?  (Buy 12, Hold 866, Sell 11)
SELECT `signal`, COUNT(*) AS days FROM bajaj2 GROUP BY `signal` ORDER BY `signal`;

-- TASK 9: signal on a given day, as a function
DROP FUNCTION IF EXISTS bajaj_signal;
DELIMITER $$
CREATE FUNCTION bajaj_signal(d DATE)
RETURNS VARCHAR(4) DETERMINISTIC READS SQL DATA
BEGIN
  DECLARE s VARCHAR(4);
  SELECT `signal` INTO s FROM bajaj2 WHERE `date` = d;
  RETURN s;
END $$
DELIMITER ;

SELECT bajaj_signal('2018-06-21') AS signal_on_2018_06_21;   -- Buy
SELECT bajaj_signal('2015-05-18') AS check_buy;              -- Buy
SELECT bajaj_signal('2016-01-04') AS check_hold;             -- Hold

-- TASK 10: all six stocks in one query, no per-stock tables
-- (tables prices_all / signals_all are built here once and reused below)
DROP TABLE IF EXISTS prices_all;
CREATE TABLE prices_all AS
SELECT 'Bajaj Auto' AS stock, `date`, close_price FROM bajaj_auto
UNION ALL SELECT 'Eicher Motors', `date`, close_price FROM eicher_motors
UNION ALL SELECT 'Hero Motocorp', `date`, close_price FROM hero_motocorp
UNION ALL SELECT 'Infosys',       `date`, close_price FROM infosys
UNION ALL SELECT 'TCS',           `date`, close_price FROM tcs
UNION ALL SELECT 'TVS Motors',    `date`, close_price FROM tvs_motors;

WITH ma AS (
  SELECT stock, `date`, close_price,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY stock ORDER BY `date`) >= 20
         THEN AVG(close_price) OVER (PARTITION BY stock ORDER BY `date` ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) END AS ma20,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY stock ORDER BY `date`) >= 50
         THEN AVG(close_price) OVER (PARTITION BY stock ORDER BY `date` ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) END AS ma50
  FROM prices_all
),
lagged AS (
  SELECT *,
    LAG(ma20) OVER (PARTITION BY stock ORDER BY `date`) AS prev_ma20,
    LAG(ma50) OVER (PARTITION BY stock ORDER BY `date`) AS prev_ma50
  FROM ma
),
sig AS (
  SELECT stock, `date`,
    CASE
      WHEN ma50 IS NULL OR prev_ma50 IS NULL THEN 'Hold'
      WHEN ma20 > ma50 AND prev_ma20 <= prev_ma50 THEN 'Buy'
      WHEN ma20 < ma50 AND prev_ma20 >= prev_ma50 THEN 'Sell'
      ELSE 'Hold'
    END AS `signal`
  FROM lagged
),
counts AS (
  SELECT stock, SUM(`signal` = 'Buy') AS buys, SUM(`signal` = 'Sell') AS sells
  FROM sig GROUP BY stock
),
latest AS (
  SELECT stock, `date`, `signal`,
         ROW_NUMBER() OVER (PARTITION BY stock ORDER BY `date` DESC) AS rn
  FROM sig WHERE `signal` <> 'Hold'
)
SELECT c.stock, c.buys, c.sells,
       l.`date` AS last_signal_date, l.`signal` AS last_signal
FROM counts c
JOIN latest l ON l.stock = c.stock AND l.rn = 1
ORDER BY c.stock;
-- expect 56 Buys and 57 Sells in total

-- ---------------------------------------------------------------------
-- PART 3: question the result
-- ---------------------------------------------------------------------

-- TASK 11: who went up? (raw prices, first vs last trading day)
WITH ends AS (
  SELECT stock, MIN(`date`) AS first_day, MAX(`date`) AS last_day FROM prices_all GROUP BY stock
)
SELECT e.stock, a.close_price AS first_close, b.close_price AS last_close,
       ROUND(100.0 * (b.close_price - a.close_price) / a.close_price, 1) AS pct_change
FROM ends e
JOIN prices_all a ON a.stock = e.stock AND a.`date` = e.first_day
JOIN prices_all b ON b.stock = e.stock AND b.`date` = e.last_day
ORDER BY pct_change DESC;

-- TASK 12: the data trap (worst single day per stock)
WITH m AS (
  SELECT stock, `date`, close_price,
         100.0 * (close_price / LAG(close_price) OVER (PARTITION BY stock ORDER BY `date`) - 1) AS pct_move
  FROM prices_all
),
r AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY stock ORDER BY pct_move) AS rn
  FROM m WHERE pct_move IS NOT NULL
)
SELECT stock, `date`, close_price, ROUND(pct_move, 1) AS pct_move
FROM r WHERE rn = 1
ORDER BY pct_move;
-- Infosys 2015-06-15 (-49.9%) and TCS 2018-05-31 (-50.4%) are 1:1 bonus issues, not crashes.

-- TASK 13: fix it (divide pre-event prices by 2, then recompute the change)
WITH adjusted AS (
  SELECT 'TCS' AS stock, `date`,
         CASE WHEN `date` < '2018-05-31' THEN close_price / 2 ELSE close_price END AS adj_close
  FROM tcs
  UNION ALL
  SELECT 'Infosys', `date`,
         CASE WHEN `date` < '2015-06-15' THEN close_price / 2 ELSE close_price END
  FROM infosys
)
SELECT stock,
       ROUND(100.0 * (MAX(CASE WHEN `date` = '2018-07-31' THEN adj_close END)
                    / MAX(CASE WHEN `date` = '2015-01-01' THEN adj_close END) - 1), 1) AS adjusted_pct_change
FROM adjusted
WHERE `date` BETWEEN '2015-01-01' AND '2018-07-31'
GROUP BY stock
ORDER BY stock;
-- expect Infosys 38.2, TCS 52.4

-- STRETCH: signals rebuilt on adjusted TCS / Infosys prices
DROP TABLE IF EXISTS adjusted_prices;
CREATE TABLE adjusted_prices AS
SELECT stock, `date`, close_price,
  CASE
    WHEN stock = 'Infosys' AND `date` < '2015-06-15' THEN close_price / 2
    WHEN stock = 'TCS'     AND `date` < '2018-05-31' THEN close_price / 2
    ELSE close_price
  END AS adj_close
FROM prices_all;

WITH ma AS (
  SELECT stock, `date`,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY stock ORDER BY `date`) >= 20
         THEN AVG(adj_close) OVER (PARTITION BY stock ORDER BY `date` ROWS BETWEEN 19 PRECEDING AND CURRENT ROW) END AS ma20,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY stock ORDER BY `date`) >= 50
         THEN AVG(adj_close) OVER (PARTITION BY stock ORDER BY `date` ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) END AS ma50
  FROM adjusted_prices
),
lagged AS (
  SELECT *,
    LAG(ma20) OVER (PARTITION BY stock ORDER BY `date`) AS prev_ma20,
    LAG(ma50) OVER (PARTITION BY stock ORDER BY `date`) AS prev_ma50
  FROM ma
),
sig AS (
  SELECT stock, `date`,
    CASE
      WHEN ma50 IS NULL OR prev_ma50 IS NULL THEN 'Hold'
      WHEN ma20 > ma50 AND prev_ma20 <= prev_ma50 THEN 'Buy'
      WHEN ma20 < ma50 AND prev_ma20 >= prev_ma50 THEN 'Sell'
      ELSE 'Hold'
    END AS `signal`
  FROM lagged
)
SELECT stock, SUM(`signal` = 'Buy') AS buys, SUM(`signal` = 'Sell') AS sells
FROM sig
WHERE stock IN ('TCS', 'Infosys')
GROUP BY stock
ORDER BY stock;
