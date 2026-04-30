-- ========================================================================
-- Exercise 5: Create a Quality Monitoring Agent
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Create the Semantic View
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Create a semantic view BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY over these tables:
  - BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS  (primary)
  - BRIGHTCART_DQ.RAW.CUSTOMERS

Join VALIDATED_ORDERS to CUSTOMERS on CUSTOMER_ID.

Dimensions: region, quality_status, status (order status), tier (customer tier)

Metrics:
  total_orders         — count of ORDER_ID in VALIDATED_ORDERS
  clean_order_count    — count of ORDER_ID where QUALITY_STATUS = 'CLEAN'
  rejected_count       — count of ORDER_ID where QUALITY_STATUS = 'REJECTED'
  review_needed_count  — count of ORDER_ID where QUALITY_STATUS = 'REVIEW_NEEDED'
  clean_order_rate     — clean_order_count * 100.0 / NULLIF(total_orders, 0), rounded to 2 decimals
  avg_quality_score    — average of QUALITY_SCORE
  null_customer_rate   — count where CUSTOMER_ID IS NULL * 100.0 / NULLIF(total_orders, 0)
  negative_total_count — count where ORDER_TOTAL < 0

Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- FALLBACK (presenter use only):
CREATE OR REPLACE SEMANTIC VIEW BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY
  TABLES (
      BRIGHTCART_DQ.CLEAN.VALIDATED_ORDERS AS ORDERS PRIMARY KEY (ORDER_ID),
      BRIGHTCART_DQ.RAW.CUSTOMERS          AS CUSTOMERS PRIMARY KEY (CUSTOMER_ID)
  )
  RELATIONSHIPS (
      ORDERS (CUSTOMER_ID) REFERENCES CUSTOMERS (CUSTOMER_ID)
  )
  FACTS (
      ORDERS.ORDER_TOTAL,
      ORDERS.QUALITY_SCORE
  )
  DIMENSIONS (
      ORDERS.REGION,
      ORDERS.QUALITY_STATUS,
      ORDERS.STATUS,
      CUSTOMERS.TIER
  )
  METRICS (
      MEASURE total_orders         AS COUNT(ORDERS.ORDER_ID),
      MEASURE clean_order_count    AS COUNT_IF(ORDERS.QUALITY_STATUS = 'CLEAN'),
      MEASURE rejected_count       AS COUNT_IF(ORDERS.QUALITY_STATUS = 'REJECTED'),
      MEASURE review_needed_count  AS COUNT_IF(ORDERS.QUALITY_STATUS = 'REVIEW_NEEDED'),
      MEASURE clean_order_rate     AS ROUND(
                                       COUNT_IF(ORDERS.QUALITY_STATUS = 'CLEAN') * 100.0
                                       / NULLIF(COUNT(ORDERS.ORDER_ID), 0), 2),
      MEASURE avg_quality_score    AS ROUND(AVG(ORDERS.QUALITY_SCORE), 1),
      MEASURE null_customer_count  AS COUNT_IF(ORDERS.CUSTOMER_ID IS NULL),
      MEASURE negative_total_count AS COUNT_IF(ORDERS.ORDER_TOTAL < 0)
  );


-- ========================================================================
-- COCO PROMPT 2: Create the Cortex Agent
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Create a Cortex Agent called BRIGHTCART_QUALITY_AGENT in
BRIGHTCART_DQ.SEMANTIC. Attach the BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY
semantic view as a Cortex Analyst tool.

Use these response instructions: respond concisely with bullet points,
always include a breakdown by region when relevant, highlight the WEST
region specifically when quality scores or rejection rates are a concern,
and suggest a root cause for any metric that is more than 10% worse
than the overall average.

Grant USAGE on the agent to the PUBLIC role.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- FALLBACK (presenter use only):
CREATE OR REPLACE CORTEX AGENT BRIGHTCART_DQ.SEMANTIC.BRIGHTCART_QUALITY_AGENT
    ENABLED = TRUE
    COMMENT  = 'BrightCart data quality monitoring agent — powered by Cortex Code HOL'
    TOOLS    = (
        BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY TYPE CORTEX_ANALYST_TOOL
    )
    TOOL_RESOURCES = (
        CORTEX_ANALYST_TOOL_RESOURCES = (
            SEMANTIC_MODELS = (BRIGHTCART_DQ.SEMANTIC.ORDER_QUALITY)
        )
    );

GRANT USAGE ON CORTEX AGENT BRIGHTCART_DQ.SEMANTIC.BRIGHTCART_QUALITY_AGENT TO ROLE PUBLIC;


-- ========================================================================
-- TEST IN SNOWFLAKE INTELLIGENCE
-- ========================================================================
-- 1. Navigate to AI & ML → Agents → Snowflake Intelligence tab
-- 2. Click "Add existing agent", search BRIGHTCART_QUALITY_AGENT, confirm
-- 3. Switch to Snowflake Intelligence and test these prompts:
--
--   "Which region has the highest rejection rate and what's causing it?"
--
--   "How does clean order rate compare across customer tiers?"
--
--   "Show me a breakdown of quality issues by region."
--
--   "Is the WEST region's data quality worse than the other regions?"
-- ========================================================================
