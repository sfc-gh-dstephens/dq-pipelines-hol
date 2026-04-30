-- ========================================================================
-- Exercise 4: Deploy a Data Quality Dashboard (Streamlit)
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================


-- ========================================================================
-- COCO PROMPT
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Build a Streamlit in Snowflake app called "Data Quality Dashboard"
in BRIGHTCART_DQ.CLEAN.

The app should read from the BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
dynamic table and include:

1. A title: "BrightCart — Data Quality Dashboard"
   and a subtitle: "Live pipeline • Powered by Cortex Code"

2. Four summary metric cards showing:
   total orders, clean order count + percentage,
   review-needed count + percentage, and rejected count + percentage.
   Color the clean metric green, review-needed yellow, rejected red
   using st.markdown with inline HTML.

3. A bar chart showing order count by REGION, with bars stacked or
   grouped by QUALITY_STATUS (CLEAN, REVIEW_NEEDED, REJECTED).

4. A sidebar selectbox to filter by QUALITY_STATUS (All, CLEAN,
   REVIEW_NEEDED, REJECTED). Show a filtered data table below the chart
   with columns: ORDER_ID, CUSTOMER_ID, REGION, ORDER_TOTAL,
   QUALITY_SCORE, QUALITY_STATUS.

5. A "Critical Issues" expander at the bottom showing the 20 rows
   with the lowest QUALITY_SCORE, sorted ascending.

Use the Snowpark session (get_active_session) for all data access.
Deploy the app.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- ITERATE WITH COCO (run after the app is deployed)
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Add a new section to the Streamlit app below the critical issues expander.
Show a line chart of daily order volume for the past 30 days, split by
QUALITY_STATUS. Read ORDER_DATE from BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
and group by ORDER_DATE and QUALITY_STATUS. Title the section
"Daily Order Quality Trend".
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- FALLBACK: See streamlit_shell.py for the complete working app.
-- Deploy it via: Projects → Streamlit → + Streamlit App
-- Set name: "Data Quality Dashboard"
-- Set location: BRIGHTCART_DQ.CLEAN
-- Paste the contents of streamlit_shell.py into the editor and click Run.
-- ========================================================================
