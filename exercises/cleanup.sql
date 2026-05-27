-- ========================================================================
-- Cleanup Script
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HOL_DQ;

-- ========================================================================
-- SELECTIVE CLEANUP
-- Removes only the objects built during the lab.
-- Leaves the HOL_DQ database and raw data intact.
-- ========================================================================

-- Cortex Agent (Exercise 7)
DROP CORTEX AGENT IF EXISTS HOL_DQ.SEMANTIC.HOL_QUALITY_AGENT;

-- Semantic View (Exercise 7)
DROP SEMANTIC VIEW IF EXISTS HOL_DQ.SEMANTIC.ORDER_QUALITY;

-- Dynamic Table (Exercise 6)
DROP DYNAMIC TABLE IF EXISTS HOL_DQ.CLEAN.VALIDATED_ORDERS;

-- AI Enrichment View (Exercise 5)
DROP VIEW IF EXISTS HOL_DQ.CLEAN.AI_ENRICHED_ORDERS;

-- Notification Integration (Exercise 3)
DROP NOTIFICATION INTEGRATION IF EXISTS HOL_DQ_EMAIL_INT;

-- Reset DQ monitoring settings (Exercise 3)
ALTER DATABASE HOL_DQ UNSET DATA_QUALITY_MONITORING_SETTINGS;

-- Remove DMFs from ORDERS table (Exercise 1)
ALTER TABLE IF EXISTS HOL_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT ON (CUSTOMER_ID);
ALTER TABLE IF EXISTS HOL_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT ON (ORDER_ID);
ALTER TABLE IF EXISTS HOL_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION HOL_DQ.RAW.NEGATIVE_TOTAL_COUNT ON (ORDER_TOTAL);
ALTER TABLE IF EXISTS HOL_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION HOL_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT ON (SHIPPING_ADDRESS);
ALTER TABLE IF EXISTS HOL_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION SNOWFLAKE.CORE.FRESHNESS ON (ORDER_DATE);

-- Custom DMFs (Exercise 1)
DROP FUNCTION IF EXISTS HOL_DQ.RAW.NEGATIVE_TOTAL_COUNT(TABLE(FLOAT));
DROP FUNCTION IF EXISTS HOL_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT(TABLE(VARCHAR));


-- ========================================================================
-- FULL CLEANUP
-- Removes everything created by this lab including the database.
-- ========================================================================

-- Uncomment to run:
--
-- DROP DATABASE  IF EXISTS HOL_DQ;
-- DROP WAREHOUSE IF EXISTS HOL_DQ_WH;
