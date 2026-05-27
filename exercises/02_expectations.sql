-- ========================================================================
-- Exercise 2: DMF Expectations
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- Add expectations to your DMFs so violations trigger notifications
-- and appear in the expectation status view.
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Add expectations to existing DMF associations
-- -----------------------------------------------------------------------
/*
Add expectations to the Data Metric Functions already attached to
HOL_DQ.RAW.ORDERS:
1. On NEGATIVE_TOTAL_COUNT (ORDER_TOTAL column): expect VALUE < 50,
   name it "few_negatives"
2. On SNOWFLAKE.CORE.DUPLICATE_COUNT (ORDER_ID column): expect VALUE = 0,
   name it "no_duplicates"
3. On SNOWFLAKE.CORE.NULL_COUNT (CUSTOMER_ID column): expect VALUE < 200,
   name it "low_nulls"
4. On SNOWFLAKE.CORE.FRESHNESS (ORDER_DATE column): expect VALUE < 86400,
   name it "fresh_data"

Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- NOTE: Expectations will be evaluated in Exercise 4 after data is loaded.
