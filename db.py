"""Data layer: loads the six CSVs into an in-memory SQLite database and runs the SQL analysis."""
import sqlite3
from datetime import datetime
from pathlib import Path

import pandas as pd

BASE = Path(__file__).parent
DATA_DIR = BASE / "data"
SQL_DIR = BASE / "sql"

# display name -> (table name, csv file)
STOCKS = {
    "Bajaj Auto": ("bajaj_auto", "Bajaj_Auto.csv"),
    "Eicher Motors": ("eicher_motors", "Eicher_Motors.csv"),
    "Hero Motocorp": ("hero_motocorp", "Hero_Motocorp.csv"),
    "Infosys": ("infosys", "Infosys.csv"),
    "TCS": ("tcs", "TCS.csv"),
    "TVS Motors": ("tvs_motors", "TVS_Motors.csv"),
}

COLUMNS = [
    "date", "open_price", "high_price", "low_price", "close_price", "wap",
    "no_of_shares", "no_of_trades", "total_turnover", "deliverable_qty",
    "pct_deli_qty", "spread_high_low", "spread_close_open",
]


def _load_csv(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    df.columns = COLUMNS
    # '31-July-2018' -> '2018-07-31' so text sorting == time sorting
    df["date"] = pd.to_datetime(df["date"], format="%d-%B-%Y").dt.strftime("%Y-%m-%d")
    return df.sort_values("date").reset_index(drop=True)


def build_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    for table, fname in STOCKS.values():
        _load_csv(DATA_DIR / fname).to_sql(table, conn, index=False)
    return conn


def run_script(conn: sqlite3.Connection, path: Path) -> None:
    conn.executescript(path.read_text())


def q(conn: sqlite3.Connection, sql: str, params=()) -> pd.DataFrame:
    return pd.read_sql_query(sql, conn, params=params)


def build_analysis_tables(conn: sqlite3.Connection) -> None:
    """Creates prices_all, signals_all, bajaj1, bajaj2, master_table."""
    run_script(conn, SQL_DIR / "tables.sql")
