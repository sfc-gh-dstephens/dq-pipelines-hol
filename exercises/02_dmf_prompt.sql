-- ========================================================================
-- Exercise 2: Create Data Metric Functions
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Attach system DMFs to RAW.ORDERS
-- -----------------------------------------------------------------------
/*
Attach two system Data Metric Functions to @HOL_DQ.RAW.ORDERS:
1. SNOWFLAKE.CORE.NULL_COUNT on the CUSTOMER_ID column
2. SNOWFLAKE.CORE.DUPLICATE_COUNT on the ORDER_ID column

Set the schedule to TRIGGER_ON_CHANGES.
Then query INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES to confirm
both DMFs are attached. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 2: Create a custom DMF for negative order totals
-- -----------------------------------------------------------------------
/*
Create a custom Data Metric Function in HOL_DQ.RAW called
NEGATIVE_TOTAL_COUNT that counts rows where order_total is less than zero.
Then attach it to HOL_DQ.RAW.ORDERS on the ORDER_TOTAL column
with TRIGGER_ON_CHANGES schedule. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 3: AI-powered DMF using Cortex AI_FILTER
-- -----------------------------------------------------------------------
/*
Create an AI-powered Data Metric Function in HOL_DQ.RAW called
AI_SUSPICIOUS_ADDRESS_COUNT. It should take a TABLE argument with a
shipping_address column and return the count of rows where
SNOWFLAKE.CORTEX.AI_FILTER classifies the address as NOT a real US
shipping address. Attach it to HOL_DQ.RAW.ORDERS on the
SHIPPING_ADDRESS column with TRIGGER_ON_CHANGES schedule. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 4: Query quality results
-- -----------------------------------------------------------------------
/*
Show me the latest Data Metric Function results for
HOL_DQ.RAW.ORDERS from SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS.
Include the metric name, value, and measurement timestamp.
Order by measurement timestamp descending.
*/
-- -----------------------------------------------------------------------

-- NOTE: DMF results may take 1–2 minutes to appear after attachment.
