-- ========================================================================
-- Cleanup Script
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE BRIGHTCART_DQ;

-- ========================================================================
-- SELECTIVE CLEANUP
-- Removes only the objects built during the lab.
-- Leaves the BRIGHTCART_DQ database and raw data intact.
-- ========================================================================

-- Dynamic Table (Step 3)
DROP DYNAMIC TABLE IF EXISTS BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS;

-- Streamlit App (Step 4)
DROP STREAMLIT IF EXISTS BRIGHTCART_DQ.CLEAN."Data Quality Dashboard";

-- Semantic View (Step 5)
DROP SEMANTIC VIEW IF EXISTS BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY;

-- Cortex Agent (Step 5)
DROP CORTEX AGENT IF EXISTS BRIGHTCART_DQ.SEMANTIC.BRIGHTCART_QUALITY_AGENT;

-- Custom DMFs (Step 2)
DROP FUNCTION IF EXISTS BRIGHTCART_DQ.RAW.NEGATIVE_TOTAL_COUNT(TABLE(FLOAT));
DROP FUNCTION IF EXISTS BRIGHTCART_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT(TABLE(VARCHAR));

-- Remove system DMFs from ORDERS table (Step 2)
ALTER TABLE IF EXISTS BRIGHTCART_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT ON (CUSTOMER_ID);
ALTER TABLE IF EXISTS BRIGHTCART_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT ON (ORDER_ID);
ALTER TABLE IF EXISTS BRIGHTCART_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION BRIGHTCART_DQ.RAW.NEGATIVE_TOTAL_COUNT ON (ORDER_TOTAL);
ALTER TABLE IF EXISTS BRIGHTCART_DQ.RAW.ORDERS
    DROP DATA METRIC FUNCTION BRIGHTCART_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT ON (SHIPPING_ADDRESS);


-- ========================================================================
-- FULL CLEANUP
-- Removes everything created by this lab including the database.
-- ========================================================================

-- Uncomment to run:
--
-- DROP DATABASE  IF EXISTS BRIGHTCART_DQ;
-- DROP WAREHOUSE IF EXISTS BRIGHTCART_DQ_WH;
