# Stock Market Analysis in SQL + Streamlit

Run the app:
    pip install -r requirements.txt
    streamlit run app.py

Submission SQL (MySQL 8): sql/stock_analysis_mysql.sql  (edit the six CSV paths in Section A first)

- data/   the six NSE CSVs
- db.py   loads CSVs into SQLite for the app (dates converted to YYYY-MM-DD)
- sql/tables.sql, sql/analysis.sql   SQLite versions of the same SQL, used by the app
- app.py  Streamlit dashboard; all numbers come from SQL
