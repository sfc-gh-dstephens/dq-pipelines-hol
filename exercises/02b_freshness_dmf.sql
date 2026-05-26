-- ========================================================================
-- Exercise 2b: Freshness Data Metric Function
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- Monitor how stale your data is using the system FRESHNESS DMF.
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Attach FRESHNESS DMF to RAW.ORDERS
-- -----------------------------------------------------------------------
/*
Attach the system Data Metric Function SNOWFLAKE.CORE.FRESHNESS to
HOL_DQ.RAW.ORDERS on the ORDER_DATE column with a schedule of
TRIGGER_ON_CHANGES. Then query INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES
to confirm it's attached. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 2: Check freshness manually
-- -----------------------------------------------------------------------
/*
Call SNOWFLAKE.CORE.FRESHNESS directly on the ORDER_DATE column of
HOL_DQ.RAW.ORDERS. Convert the result from seconds to hours.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 3: Query freshness results from monitoring view
-- -----------------------------------------------------------------------
/*
Query SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS for the FRESHNESS
metric on HOL_DQ.RAW.ORDERS. Show the metric name, value in
seconds, value converted to hours, and measurement timestamp. Order by
measurement time descending, limit 10. Execute the SQL.
*/
-- -----------------------------------------------------------------------
