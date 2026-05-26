-- ========================================================================
-- Exercise 1: Fix Broken Quality Check Code
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- Paste the BROKEN QUERY below into your SQL worksheet.
-- It contains 3 errors. Fix them using Cortex Code's three methods.
-- ========================================================================

-- BROKEN QUERY (paste this into your worksheet):
-- -----------------------------------------------------------------------
SELECT
    region,
    COUNT(*)                                                      AS total_orders,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END)               AS null_customer_count,
    COUNT(CASE WHEN order_totl < 0 THEN 1 END)                    AS negative_total_count,
    COUNT(CASE WHEN shiping_address IS NULL THEN 1 END)           AS missing_address_count,
    ROUND(
        COUNT(CASE WHEN customer_id IS NULL THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0), 2
    )                                                             AS null_pct
FROM HOL_DQ.ORDR.ORDERS
GROUP BY region
ORDER BY total_orders DESC;

-- -----------------------------------------------------------------------
-- ERROR 1: order_totl  →  order_total   (column name typo)
--   Fix method: Select "order_totl" → click Add to Chat → type
--     "Fix this column name typo — the correct column is order_total"
--
-- ERROR 2: HOL_DQ.ORDR.ORDERS  →  HOL_DQ.RAW.ORDERS  (schema typo)
--   Fix method: Run the query → get runtime error → click the Fix button
--     CoCo corrects ORDR → RAW in a diff view → click Keep all in file
--
-- ERROR 3: shiping_address  →  shipping_address  (column name typo)
--   Fix method: Run the query → get invalid identifier error → click Fix
--     CoCo introspects the actual table schema and finds the correct column name
-- -----------------------------------------------------------------------
