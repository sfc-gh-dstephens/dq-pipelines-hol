-- ========================================================================
-- Exercise 6: Notifications & Expectations
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- Close the detection-to-response loop: define what "passing" looks like
-- with expectations, and get notified automatically when they're violated.
-- No manual alerts needed.
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Create a notification integration for email
-- -----------------------------------------------------------------------
/*
Create an email notification integration called HOL_DQ_EMAIL_INT
that is enabled and allows recipients 'dstephens@snowflake.com'.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 2: Enable DQ notifications on the database
-- -----------------------------------------------------------------------
/*
Configure DATA_QUALITY_MONITORING_SETTINGS on the HOL_DQ database
to enable notifications. Use the HOL_DQ_EMAIL_INT integration,
set cooldown_hours to 1, and include metadata. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 3: Add expectations to existing DMFs
-- -----------------------------------------------------------------------
/*
Add expectations to the DMFs already attached to HOL_DQ.RAW.ORDERS:

1. On NEGATIVE_TOTAL_COUNT (ORDER_TOTAL column): add an expectation
   called "few_negatives" that passes when VALUE < 50.

2. On SNOWFLAKE.CORE.DUPLICATE_COUNT (ORDER_ID column): add an
   expectation called "no_duplicates" that passes when VALUE = 0.

3. On SNOWFLAKE.CORE.NULL_COUNT (CUSTOMER_ID column): add an
   expectation called "low_nulls" that passes when VALUE < 200.

4. On SNOWFLAKE.CORE.FRESHNESS (ORDER_DATE column): add an
   expectation called "fresh_data" that passes when VALUE < 86400
   (less than 24 hours stale).

Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 4: Test expectations on demand
-- -----------------------------------------------------------------------
/*
Call SYSTEM$EVALUATE_DATA_QUALITY_EXPECTATIONS on HOL_DQ.RAW.ORDERS
to see which expectations are currently passing or violated.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 5: Check expectation violation history
-- -----------------------------------------------------------------------
/*
Query SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_EXPECTATION_STATUS
for HOL_DQ.RAW.ORDERS. Show the metric name, expectation name,
expectation expression, whether it passed or was violated, the metric
value, and measurement time. Order by measurement time descending,
limit 20. Execute the SQL.
*/
-- -----------------------------------------------------------------------
