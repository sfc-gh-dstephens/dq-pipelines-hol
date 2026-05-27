-- ========================================================================
-- Exercise 4: Check Quality Results
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- Now that data has been loaded, check DMF results and evaluate
-- expectations to see quality violations.
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Query DMF results from monitoring view
-- -----------------------------------------------------------------------
/*
Show me the latest Data Metric Function results for
HOL_DQ.RAW.ORDERS from SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS.
Include the metric name, value, and measurement timestamp.
Order by measurement timestamp descending.
*/
-- -----------------------------------------------------------------------

-- NOTE: DMF results may take 1-2 minutes to appear after data insertion.


-- ========================================================================
-- COCO PROMPT 2: Evaluate expectations on demand
-- -----------------------------------------------------------------------
/*
Call SYSTEM$EVALUATE_DATA_QUALITY_EXPECTATIONS for HOL_DQ.RAW.ORDERS
to test all expectations immediately. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 3: Check expectation violation history
-- -----------------------------------------------------------------------
/*
Query SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_EXPECTATION_STATUS for
HOL_DQ.RAW.ORDERS. Show all columns, ordered by measurement_time
descending, limit 20. Execute the SQL.
*/
-- -----------------------------------------------------------------------
