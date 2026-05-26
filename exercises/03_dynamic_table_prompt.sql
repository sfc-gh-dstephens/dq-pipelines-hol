-- ========================================================================
-- Exercise 3: Build a Validated Data Pipeline (Dynamic Table)
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================


-- ========================================================================
-- COCO PROMPT
-- -----------------------------------------------------------------------
/*
Create a Dynamic Table called HOL_DQ.CLEAN.VALIDATED_ORDERS
using warehouse HOL_DQ_WH with a target lag of 1 minute.

It should read from HOL_DQ.RAW.ORDERS and do the following:
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
-- VERIFY: After the table is created, run these prompts:
-- ========================================================================
--
--   "Show me order counts by quality_status with percentages
--    from HOL_DQ.CLEAN.VALIDATED_ORDERS"
--
--   "Show regional quality breakdown from VALIDATED_ORDERS"
--
--   "Check the refresh history for HOL_DQ.CLEAN.VALIDATED_ORDERS"
--
-- ========================================================================
