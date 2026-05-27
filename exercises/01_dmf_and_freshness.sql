-- ========================================================================
-- Exercise 1: Data Metric Functions & Freshness
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Attach system DMFs to RAW.ORDERS
-- -----------------------------------------------------------------------
/*
Attach two system Data Metric Functions to HOL_DQ.RAW.ORDERS:
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
-- COCO PROMPT 4: Attach FRESHNESS DMF to RAW.ORDERS
-- -----------------------------------------------------------------------
/*
Attach the system Data Metric Function SNOWFLAKE.CORE.FRESHNESS to
HOL_DQ.RAW.ORDERS on the ORDER_DATE column with a schedule of
TRIGGER_ON_CHANGES. Then query INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES
to confirm it's attached. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 5: Check freshness manually
-- -----------------------------------------------------------------------
/*
Call SNOWFLAKE.CORE.FRESHNESS directly on the ORDER_DATE column of
HOL_DQ.RAW.ORDERS. Convert the result from seconds to hours.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- NOTE: DMF results will be checked in Exercise 4 after data is loaded.
