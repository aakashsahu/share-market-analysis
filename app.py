"""Streamlit app: Stock market analysis in pure SQL (six NSE stocks, Jan 2015 - Jul 2018).

Run with:  streamlit run app.py
Every number shown is computed by a SQL query. Python only runs the query and draws the chart.
"""
import re

import pandas as pd
import plotly.graph_objects as go
import streamlit as st

import db

st.set_page_config(page_title="Stock Market Analysis in SQL", page_icon="📈", layout="wide")

EVENTS = {"Infosys": "2015-06-15", "TCS": "2018-05-31"}  # 1:1 bonus issues found in Task 12
STOCK_NAMES = list(db.STOCKS.keys())
FIRST, LAST = "2015-01-01", "2018-07-31"


@st.cache_resource
def get_conn():
    conn = db.build_connection()
    db.build_analysis_tables(conn)
    return conn


conn = get_conn()


def Q(sql, params=()):
    return db.q(conn, sql, params)


@st.cache_data
def load_tasks():
    """Split sql/analysis.sql into {task number: (title, sql)} using the '-- TASK n:' markers."""
    text = (db.SQL_DIR / "analysis.sql").read_text()
    parts = re.split(r"^-- TASK (\d+): (.*)$", text, flags=re.M)
    return [(int(parts[i]), parts[i + 1].strip(), parts[i + 2].strip().rstrip(";")) for i in range(1, len(parts), 3)]


# ------------------------------------------------------------------ sidebar
st.sidebar.title("📈 Stock Analysis")
page = st.sidebar.radio(
    "Go to",
    ["Overview", "Task solutions", "Price & signals", "All stocks summary",
     "Who went up?", "The data trap", "SQL lab", "Insights"],
)
st.sidebar.caption("Six NSE stocks · Jan 2015 – Jul 2018 · pure SQL")


def line_fig(df, x, cols, height=450, ytitle=None):
    fig = go.Figure()
    for c in cols:
        fig.add_trace(go.Scatter(x=df[x], y=df[c], name=c))
    fig.update_layout(height=height, hovermode="x unified", margin=dict(l=10, r=10, t=10, b=10), yaxis_title=ytitle)
    return fig


# ================================================================== pages
if page == "Overview":
    st.title("Stock market analysis in SQL")
    st.write("Moving averages, golden-cross Buy/Sell signals, and the data problem hiding in plain sight. "
             "All figures are produced by SQL (see **Task solutions** and **SQL lab**).")

    info = Q("SELECT COUNT(*) AS trading_days, MIN(date) AS first_day, MAX(date) AS last_day FROM bajaj_auto").iloc[0]
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Stocks", len(STOCK_NAMES))
    c2.metric("Trading days each", int(info["trading_days"]))
    c3.metric("First day", info["first_day"])
    c4.metric("Last day", info["last_day"])

    st.subheader("Closing prices rebased to 100 (raw prices)")
    st.caption("The two lines that fall off a cliff are the data trap (see *The data trap*).")
    rebased = Q(
        """
        SELECT date,
          100.0 * bajaj   / FIRST_VALUE(bajaj)   OVER (ORDER BY date) AS Bajaj,
          100.0 * tcs     / FIRST_VALUE(tcs)     OVER (ORDER BY date) AS TCS,
          100.0 * tvs     / FIRST_VALUE(tvs)     OVER (ORDER BY date) AS TVS,
          100.0 * infosys / FIRST_VALUE(infosys) OVER (ORDER BY date) AS Infosys,
          100.0 * eicher  / FIRST_VALUE(eicher)  OVER (ORDER BY date) AS Eicher,
          100.0 * hero    / FIRST_VALUE(hero)    OVER (ORDER BY date) AS Hero
        FROM master_table ORDER BY date
        """
    )
    st.plotly_chart(line_fig(rebased, "date", rebased.columns[1:], ytitle="Index (start = 100)"), use_container_width=True)

    a, b = st.columns(2)
    with a:
        st.subheader("Eicher's five best closes")
        st.dataframe(Q("SELECT date, close_price FROM eicher_motors ORDER BY close_price DESC LIMIT 5"), hide_index=True)
    with b:
        st.subheader("TCS average close by year")
        st.dataframe(Q("SELECT strftime('%Y', date) AS year, ROUND(AVG(close_price), 2) AS avg_close "
                       "FROM tcs GROUP BY strftime('%Y', date) ORDER BY year"), hide_index=True)
        st.caption("2018 only has seven months of data.")

    st.subheader("Missing data (NULL deliverable_qty)")
    st.dataframe(Q(" UNION ALL ".join(
        f"SELECT '{t}' AS stock, date FROM {t} WHERE deliverable_qty IS NULL" for t, _ in db.STOCKS.values())),
        hide_index=True)
    st.caption("Six rows on only two distinct dates, spread across unrelated companies: "
               "this points to a gap in the exchange's reporting, not the companies.")

elif page == "Task solutions":
    st.title("Task solutions (1 to 13)")
    st.caption("Each task shows its SQL and the live result. Checkpoints come from the student guide.")
    checks = {
        1: "889 days, 2015-01-01 to 2018-07-31", 2: "Top close above 32,000; all five in September 2017",
        3: "2016 average is exactly 2419.00", 4: "Six rows on two distinct dates",
        5: "First ma20 on 2015-01-29 = 2415.53; first ma50 on 2015-03-13 = 2283.80",
        6: "889 rows; 2018-07-31 bajaj 2700.70, tvs 517.45", 7: "First Buy 2015-05-18, first Sell 2015-08-24",
        8: "Buy 12, Hold 866, Sell 11", 9: "Buy", 10: "56 Buys and 57 Sells in total",
        11: "TVS tops at 86.9%; two stocks negative", 12: "Two rows near -50%: Infosys and TCS",
        13: "Infosys 38.2, TCS 52.4",
    }
    for n, title, sql in load_tasks():
        with st.expander(f"Task {n}: {title}", expanded=(n == 1)):
            st.code(sql + ";", language="sql")
            res = Q(sql)
            st.dataframe(res, hide_index=True, use_container_width=True)
            st.caption(f"Checkpoint: {checks.get(n, '')}")
    st.info("Tables such as `bajaj1`, `bajaj2`, `master_table` are built in `sql/tables.sql`. "
            "The MySQL 8 submission file is `sql/stock_analysis_mysql.sql`.")

elif page == "Price & signals":
    st.title("Price, moving averages & golden-cross signals")
    c1, c2 = st.columns(2)
    stock = c1.selectbox("Stock", STOCK_NAMES)
    adjusted = c2.toggle(f"Use bonus-adjusted prices ({EVENTS[stock]})", value=True) if stock in EVENTS else False
    lo, hi = pd.Timestamp(FIRST).date(), pd.Timestamp(LAST).date()
    start, end = st.slider("Date range", min_value=lo, max_value=hi, value=(lo, hi))

    table = "signals_adjusted" if adjusted else "signals_all"
    df = Q(f"SELECT date, close_price, ma20, ma50, signal FROM {table} WHERE stock = ? AND date BETWEEN ? AND ? ORDER BY date",
           (stock, str(start), str(end)))
    fig = go.Figure()
    fig.add_trace(go.Scatter(x=df["date"], y=df["close_price"], name="Close", line=dict(color="#94a3b8", width=1.5)))
    fig.add_trace(go.Scatter(x=df["date"], y=df["ma20"], name="20-day avg", line=dict(color="#2563eb", width=2)))
    fig.add_trace(go.Scatter(x=df["date"], y=df["ma50"], name="50-day avg", line=dict(color="#f97316", width=2)))
    for sig, sym, col in (("Buy", "triangle-up", "#16a34a"), ("Sell", "triangle-down", "#dc2626")):
        s = df[df["signal"] == sig]
        fig.add_trace(go.Scatter(x=s["date"], y=s["ma20"], mode="markers", name=sig,
                                 marker=dict(symbol=sym, size=13, color=col)))
    if stock in EVENTS and not adjusted:
        fig.add_vline(x=EVENTS[stock], line_dash="dash", line_color="red")
    fig.update_layout(height=520, hovermode="x unified", margin=dict(l=10, r=10, t=30, b=10),
                      legend=dict(orientation="h", y=1.08), yaxis_title="Price (₹)")
    st.plotly_chart(fig, use_container_width=True)

    stats = Q(f"SELECT COALESCE(SUM(signal='Buy'),0) AS buys, COALESCE(SUM(signal='Sell'),0) AS sells FROM {table} "
              "WHERE stock = ? AND date BETWEEN ? AND ?", (stock, str(start), str(end))).iloc[0]
    m1, m2 = st.columns(2)
    m1.metric("Buy signals", int(stats["buys"]))
    m2.metric("Sell signals", int(stats["sells"]))
    st.subheader("Signal log")
    st.dataframe(Q(f"SELECT date, ROUND(close_price,2) AS close_price, ROUND(ma20,2) AS ma20, ROUND(ma50,2) AS ma50, signal "
                   f"FROM {table} WHERE stock = ? AND signal <> 'Hold' AND date BETWEEN ? AND ? ORDER BY date",
                   (stock, str(start), str(end))), hide_index=True, use_container_width=True)

    with st.expander("How is a signal defined?"):
        st.markdown("**Buy** = the single day the 20-day average moves above the 50-day average "
                    "(yesterday `ma20 <= ma50`, today `ma20 > ma50`). **Sell** is the mirror image. "
                    "Everything else, including days before a full window exists, is **Hold**.")
        st.code("CASE\n  WHEN ma50 IS NULL OR prev_ma50 IS NULL THEN 'Hold'\n"
                "  WHEN ma20 > ma50 AND prev_ma20 <= prev_ma50 THEN 'Buy'\n"
                "  WHEN ma20 < ma50 AND prev_ma20 >= prev_ma50 THEN 'Sell'\n  ELSE 'Hold'\nEND AS signal", language="sql")

    st.subheader("Signal on a given day (Task 9)")
    d = st.date_input("Pick a date", value=pd.Timestamp("2018-06-21").date(), min_value=lo, max_value=hi)
    r = Q("SELECT signal FROM signals_all WHERE stock = ? AND date = ?", (stock, str(d)))
    st.write(f"**{stock}** on {d}: " + (f"**{r.iloc[0, 0]}**" if len(r) else "no trading that day (market closed)"))

elif page == "All stocks summary":
    st.title("All six stocks in one query (Task 10)")
    summary = Q(dict((n, s) for n, _, s in load_tasks())[10])
    st.dataframe(summary, hide_index=True, use_container_width=True)
    tot = Q("SELECT SUM(signal='Buy') AS buys, SUM(signal='Sell') AS sells FROM signals_all").iloc[0]
    t1, t2 = st.columns(2)
    t1.metric("Total Buys", int(tot["buys"]))
    t2.metric("Total Sells", int(tot["sells"]))
    fig = go.Figure()
    fig.add_bar(x=summary["stock"], y=summary["buys"], name="Buys", marker_color="#16a34a")
    fig.add_bar(x=summary["stock"], y=summary["sells"], name="Sells", marker_color="#dc2626")
    fig.update_layout(barmode="group", height=380, margin=dict(l=10, r=10, t=10, b=10))
    st.plotly_chart(fig, use_container_width=True)

    st.subheader("TCS and Infosys signals: raw vs bonus-adjusted prices")
    st.dataframe(Q("""
        SELECT r.stock, r.buys AS raw_buys, r.sells AS raw_sells, a.buys AS adj_buys, a.sells AS adj_sells
        FROM (SELECT stock, SUM(signal='Buy') AS buys, SUM(signal='Sell') AS sells FROM signals_all GROUP BY stock) r
        JOIN (SELECT stock, SUM(signal='Buy') AS buys, SUM(signal='Sell') AS sells FROM signals_adjusted GROUP BY stock) a
          ON a.stock = r.stock
        WHERE r.stock IN ('TCS','Infosys') ORDER BY r.stock"""), hide_index=True)
    st.caption("The raw TCS and Infosys signals are distorted around the bonus-issue dates.")

elif page == "Who went up?":
    st.title("Who went up? (Tasks 11 and 13)")
    both = Q("""
        WITH ends AS (SELECT stock, MIN(date) AS f, MAX(date) AS l FROM adjusted_prices GROUP BY stock)
        SELECT e.stock, a.close_price AS first_close, b.close_price AS last_close,
               ROUND(100.0 * (b.close_price - a.close_price) / a.close_price, 1) AS raw_pct_change,
               ROUND(100.0 * (b.adj_close - a.adj_close) / a.adj_close, 1) AS adjusted_pct_change
        FROM ends e
        JOIN adjusted_prices a ON a.stock = e.stock AND a.date = e.f
        JOIN adjusted_prices b ON b.stock = e.stock AND b.date = e.l
        ORDER BY adjusted_pct_change DESC""")
    st.dataframe(both, hide_index=True, use_container_width=True)
    fig = go.Figure()
    fig.add_bar(x=both["stock"], y=both["raw_pct_change"], name="Raw", marker_color="#94a3b8")
    fig.add_bar(x=both["stock"], y=both["adjusted_pct_change"], name="Adjusted", marker_color="#2563eb")
    fig.update_layout(barmode="group", height=420, yaxis_title="% change, first to last day", margin=dict(l=10, r=10, t=10, b=10))
    st.plotly_chart(fig, use_container_width=True)
    st.info("On raw prices TCS (-23.8%) and Infosys (-30.9%) look like losers. After adjusting for the 1:1 bonus "
            "issues both are winners (TCS +52.4%, Infosys +38.2%). The course deck's Infosys figure of -3% does not "
            "match the data.")

elif page == "The data trap":
    st.title("The data trap (Task 12)")
    st.dataframe(Q(dict((n, s) for n, _, s in load_tasks())[12]), hide_index=True, use_container_width=True)
    st.warning("Infosys 2015-06-15 (-49.9%) and TCS 2018-05-31 (-50.4%) are not crashes. Each company issued a 1:1 bonus "
               "share, so the share count doubled and the price halved overnight. Nobody lost value.")
    stock = st.radio("Look at", list(EVENTS), horizontal=True)
    df = Q("SELECT date, close_price AS raw_close, adj_close AS adjusted_close FROM adjusted_prices WHERE stock = ? ORDER BY date", (stock,))
    fig = line_fig(df, "date", ["raw_close", "adjusted_close"], ytitle="Price (₹)")
    fig.add_vline(x=EVENTS[stock], line_dash="dash")
    st.plotly_chart(fig, use_container_width=True)

    st.subheader("Signals created or hidden by the cliff")
    st.dataframe(
        Q("""
        SELECT date, signal, 'Only on raw prices (created by the cliff)' AS status FROM signals_all r
        WHERE stock = ? AND signal <> 'Hold'
          AND NOT EXISTS (SELECT 1 FROM signals_adjusted a WHERE a.stock = r.stock AND a.date = r.date AND a.signal = r.signal)
        UNION ALL
        SELECT date, signal, 'Only on adjusted prices (hidden by the cliff)' FROM signals_adjusted a
        WHERE stock = ? AND signal <> 'Hold'
          AND NOT EXISTS (SELECT 1 FROM signals_all r WHERE a.stock = r.stock AND a.date = r.date AND a.signal = r.signal)
        ORDER BY date""", (stock, stock)), hide_index=True, use_container_width=True)
    st.caption("If this table is empty for a stock, its signals are identical on raw and adjusted prices.")

elif page == "SQL lab":
    st.title("SQL lab")
    st.write("Tables: " + ", ".join(f"`{t}`" for t, _ in db.STOCKS.values())
             + ", `bajaj1`, `bajaj2`, `master_table`, `prices_all`, `signals_all`, `adjusted_prices`, `signals_adjusted`.")
    tab_run, tab_files = st.tabs(["Run a query", "Project SQL files"])
    with tab_run:
        sql = st.text_area("Write a SELECT query", value="SELECT * FROM bajaj2 WHERE signal <> 'Hold' ORDER BY date;", height=160)
        if st.button("Run", type="primary"):
            if not sql.strip().lower().startswith(("select", "with")):
                st.error("Only SELECT / WITH queries are allowed here.")
            else:
                try:
                    res = Q(sql)
                    st.caption(f"{len(res)} rows")
                    st.dataframe(res, use_container_width=True)
                except Exception as e:
                    st.error(str(e))
    with tab_files:
        for f in ("tables.sql", "analysis.sql", "stock_analysis_mysql.sql"):
            st.subheader(f"sql/{f}")
            st.code((db.SQL_DIR / f).read_text(), language="sql")

elif page == "Insights":
    st.title("Insights")
    st.dataframe(Q("""
        WITH ends AS (SELECT stock, MIN(date) AS f, MAX(date) AS l FROM adjusted_prices GROUP BY stock)
        SELECT e.stock,
               ROUND(100.0 * (b.close_price - a.close_price) / a.close_price, 1) AS raw_pct,
               ROUND(100.0 * (b.adj_close - a.adj_close) / a.adj_close, 1) AS adjusted_pct
        FROM ends e
        JOIN adjusted_prices a ON a.stock = e.stock AND a.date = e.f
        JOIN adjusted_prices b ON b.stock = e.stock AND b.date = e.l
        ORDER BY adjusted_pct DESC"""), hide_index=True)
    st.subheader("Signals that flipped within 30 days of the previous signal")
    st.dataframe(Q("""
        WITH s AS (SELECT stock, date, LAG(date) OVER (PARTITION BY stock ORDER BY date) AS prev_date
                   FROM signals_all WHERE signal <> 'Hold')
        SELECT stock, SUM(julianday(date) - julianday(prev_date) <= 30) AS quick_flips
        FROM s GROUP BY stock ORDER BY quick_flips DESC"""), hide_index=True)
    st.markdown("""
**Claim 1: TCS and Infosys are not losers.** Evidence: raw -23.8% / -30.9%, adjusted +52.4% / +38.2% (Task 13). Caveat: assumes exactly 1:1 bonus issues and ignores dividends.

**Claim 2: Signals lag price.** A moving average only uses past prices, so a golden cross confirms a move that already happened. Caveat: a longer window is smoother but later.

**Claim 3: Frequent flips are costly.** Bajaj (11) and TCS (8) have many signals within 30 days of the previous one. Caveat: no brokerage, tax or slippage in this data.

**Claim 4: The course deck changes after Task 13.** Infosys is quoted as -3% (data: -30.9% raw, +38.2% adjusted), TCS and Infosys are not sell candidates on raw price alone, and their signal counts change once the cliff is removed.

**Missing from the data:** dividends, news, brokerage costs, and a market benchmark such as the Nifty.
""")
