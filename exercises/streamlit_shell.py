"""
BrightCart — Data Quality Dashboard
Streamlit in Snowflake | Fallback app for presenter use

Deploy via: Projects → Streamlit → + Streamlit App
  Name:     Data Quality Dashboard
  Location: BRIGHTCART_DQ.CLEAN
Paste this file into the editor and click Run.
"""

import streamlit as st
import pandas as pd
import altair as alt
from snowflake.snowpark.context import get_active_session

session = get_active_session()

# ── Page config ──────────────────────────────────────────────────────────────
st.set_page_config(page_title="BrightCart DQ Dashboard", layout="wide")

st.title("BrightCart — Data Quality Dashboard")
st.caption("Live pipeline  •  Powered by Cortex Code")
st.markdown("---")


# ── Load data ─────────────────────────────────────────────────────────────────
@st.cache_data(ttl=60)
def load_orders():
    return session.sql(
        "SELECT * FROM BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS"
    ).to_pandas()

df = load_orders()

# ── Summary metrics ──────────────────────────────────────────────────────────
total    = len(df)
clean    = int((df["QUALITY_STATUS"] == "CLEAN").sum())
review   = int((df["QUALITY_STATUS"] == "REVIEW_NEEDED").sum())
rejected = int((df["QUALITY_STATUS"] == "REJECTED").sum())

col1, col2, col3, col4 = st.columns(4)

col1.metric("Total Orders", f"{total:,}")
col2.metric(
    "Clean",
    f"{clean:,}",
    f"{clean / total * 100:.1f}%" if total else "0%",
)
col3.metric(
    "Review Needed",
    f"{review:,}",
    f"{review / total * 100:.1f}%" if total else "0%",
)
col4.metric(
    "Rejected",
    f"{rejected:,}",
    f"-{rejected / total * 100:.1f}%" if total else "0%",
    delta_color="inverse",
)

# Color-coded status summary
st.markdown(
    f"""
    <div style='display:flex; gap:16px; margin-top:8px; margin-bottom:16px;'>
      <span style='background:#d4edda; color:#155724; padding:6px 12px;
                   border-radius:6px; font-weight:600;'>
        ✅ CLEAN: {clean:,} ({clean/total*100:.1f}%)
      </span>
      <span style='background:#fff3cd; color:#856404; padding:6px 12px;
                   border-radius:6px; font-weight:600;'>
        ⚠️ REVIEW NEEDED: {review:,} ({review/total*100:.1f}%)
      </span>
      <span style='background:#f8d7da; color:#721c24; padding:6px 12px;
                   border-radius:6px; font-weight:600;'>
        ❌ REJECTED: {rejected:,} ({rejected/total*100:.1f}%)
      </span>
    </div>
    """,
    unsafe_allow_html=True,
)

st.markdown("---")

# ── Bar chart: Orders by region grouped by quality status ────────────────────
st.subheader("Order Quality by Region")

region_counts = (
    df.groupby(["REGION", "QUALITY_STATUS"])
    .size()
    .reset_index(name="COUNT")
)

status_colors = {
    "CLEAN":          "#28a745",
    "REVIEW_NEEDED":  "#ffc107",
    "REJECTED":       "#dc3545",
}

chart = (
    alt.Chart(region_counts)
    .mark_bar()
    .encode(
        x=alt.X("REGION:N", title="Region"),
        y=alt.Y("COUNT:Q", title="Order Count"),
        color=alt.Color(
            "QUALITY_STATUS:N",
            scale=alt.Scale(
                domain=list(status_colors.keys()),
                range=list(status_colors.values()),
            ),
            legend=alt.Legend(title="Quality Status"),
        ),
        xOffset="QUALITY_STATUS:N",
        tooltip=["REGION", "QUALITY_STATUS", "COUNT"],
    )
    .properties(height=350)
)

st.altair_chart(chart, use_container_width=True)

st.markdown("---")

# ── Sidebar filter + drill-down table ────────────────────────────────────────
st.sidebar.header("Filters")
status_filter = st.sidebar.selectbox(
    "Quality Status",
    ["All", "CLEAN", "REVIEW_NEEDED", "REJECTED"],
)
region_filter = st.sidebar.selectbox(
    "Region",
    ["All"] + sorted(df["REGION"].unique().tolist()),
)

filtered = df.copy()
if status_filter != "All":
    filtered = filtered[filtered["QUALITY_STATUS"] == status_filter]
if region_filter != "All":
    filtered = filtered[filtered["REGION"] == region_filter]

st.subheader(f"Order Detail ({len(filtered):,} rows)")

display_cols = [
    "ORDER_ID", "CUSTOMER_ID", "REGION",
    "ORDER_TOTAL", "QUALITY_SCORE", "QUALITY_STATUS",
]
st.dataframe(
    filtered[display_cols].sort_values("QUALITY_SCORE").reset_index(drop=True),
    use_container_width=True,
    height=300,
)

st.markdown("---")

# ── Critical Issues expander ─────────────────────────────────────────────────
with st.expander("Critical Issues — Bottom 20 by Quality Score"):
    bottom_20 = (
        df.nsmallest(20, "QUALITY_SCORE")[display_cols]
        .reset_index(drop=True)
    )
    st.dataframe(bottom_20, use_container_width=True)

st.markdown("---")

# ── Daily Order Quality Trend ─────────────────────────────────────────────────
st.subheader("Daily Order Quality Trend (Last 30 Days)")

daily_df = session.sql(
    """
    SELECT ORDER_DATE, QUALITY_STATUS, COUNT(*) AS ORDER_COUNT
    FROM   BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
    WHERE  ORDER_DATE >= DATEADD('day', -30, CURRENT_DATE())
    GROUP  BY ORDER_DATE, QUALITY_STATUS
    ORDER  BY ORDER_DATE
    """
).to_pandas()

trend_chart = (
    alt.Chart(daily_df)
    .mark_line(point=True)
    .encode(
        x=alt.X("ORDER_DATE:T", title="Date"),
        y=alt.Y("ORDER_COUNT:Q", title="Orders"),
        color=alt.Color(
            "QUALITY_STATUS:N",
            scale=alt.Scale(
                domain=list(status_colors.keys()),
                range=list(status_colors.values()),
            ),
        ),
        tooltip=["ORDER_DATE", "QUALITY_STATUS", "ORDER_COUNT"],
    )
    .properties(height=300)
)

st.altair_chart(trend_chart, use_container_width=True)
