-- ========================================================================
-- Exercise 3: Build a Validated Data Pipeline (Dynamic Table)
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================


-- ========================================================================
-- COCO PROMPT
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Create a Dynamic Table called BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
using warehouse BRIGHTCART_DQ_WH with a target lag of 1 minute.

It should read from BRIGHTCART_DQ.RAW.ORDERS and do the following:
- Deduplicate on ORDER_ID, keeping the row with the earliest ORDER_DATE
- Reject rows where CUSTOMER_ID is NULL or ORDER_TOTAL is negative —
  these are hard quality failures
- For remaining rows, compute a QUALITY_SCORE from 0–100:
  start at 100 and subtract 20 if ORDER_TOTAL is zero, subtract 15
  if SHIPPING_ADDRESS is NULL, subtract 10 if the absolute difference
  between ORDER_TOTAL and (QUANTITY * UNIT_PRICE) exceeds 1.00
- Add a QUALITY_STATUS column: 'REJECTED' for hard failures, 'CLEAN'
  for scores 90 and above, and 'REVIEW_NEEDED' for everything in between
- Include all original columns plus QUALITY_SCORE and QUALITY_STATUS

Use a CTE to pre-aggregate (deduplicate) before applying quality rules —
do not apply DISTINCT or scoring logic directly on the raw table, as
this can cause incorrect results with duplicates.

Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- FALLBACK (presenter use only — paste if CoCo stalls or produces bad output)
-- ========================================================================
CREATE OR REPLACE DYNAMIC TABLE BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
    TARGET_LAG    = '1 minute'
    WAREHOUSE     = BRIGHTCART_DQ_WH
    REFRESH_MODE  = AUTO
    INITIALIZE    = ON_CREATE
AS
WITH
-- Step 1: Deduplicate — keep earliest row per order_id
deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date ASC) AS rn
    FROM BRIGHTCART_DQ.RAW.ORDERS
),
base AS (
    SELECT order_id, customer_id, product_id, quantity, unit_price,
           order_total, order_date, status, shipping_address, region
    FROM deduped
    WHERE rn = 1
),
-- Step 2: Apply hard-fail flags and soft-issue scoring
scored AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        quantity,
        unit_price,
        order_total,
        order_date,
        status,
        shipping_address,
        region,
        -- Hard failures
        customer_id IS NULL                           AS is_null_customer,
        order_total < 0                               AS is_negative_total,
        -- Soft quality deductions (start at 100)
        100
            - CASE WHEN order_total = 0                                            THEN 20 ELSE 0 END
            - CASE WHEN shipping_address IS NULL                                   THEN 15 ELSE 0 END
            - CASE WHEN ABS(order_total - (quantity * unit_price)) > 1.00          THEN 10 ELSE 0 END
        AS quality_score
    FROM base
)
-- Step 3: Assign final quality status
SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    unit_price,
    order_total,
    order_date,
    status,
    shipping_address,
    region,
    CASE
        WHEN is_null_customer OR is_negative_total THEN 0
        ELSE quality_score
    END                                               AS quality_score,
    CASE
        WHEN is_null_customer OR is_negative_total THEN 'REJECTED'
        WHEN quality_score >= 90                   THEN 'CLEAN'
        ELSE 'REVIEW_NEEDED'
    END                                               AS quality_status
FROM scored;


-- ========================================================================
-- VERIFY: After the table is created, run these queries
-- ========================================================================

-- Row count by quality status (run after ~60 seconds for first refresh)
SELECT quality_status, COUNT(*) AS order_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
GROUP BY quality_status
ORDER BY quality_status;

-- Expected approximate distribution:
--   CLEAN          ~4,000   (~79%)
--   REVIEW_NEEDED  ~  600   (~12%)
--   REJECTED       ~  450   (~ 9%)

-- Regional quality breakdown
SELECT region, quality_status, COUNT(*) AS cnt
FROM BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS
GROUP BY region, quality_status
ORDER BY region, quality_status;

-- Check refresh history
SELECT name, state, state_message, refresh_start_time, refresh_end_time
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    NAME => 'BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS'
))
ORDER BY refresh_start_time DESC
LIMIT 5;
