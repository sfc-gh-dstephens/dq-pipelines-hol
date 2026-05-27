-- ========================================================================
-- Exercise 7: Create a Quality Monitoring Agent
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Create the Semantic View
-- -----------------------------------------------------------------------
/*
Create a semantic view HOL_DQ.SEMANTIC.ORDER_QUALITY over these tables:
  - HOL_DQ.CLEAN.VALIDATED_ORDERS  (primary)
  - HOL_DQ.RAW.CUSTOMERS

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


-- ========================================================================
-- COCO PROMPT 2: Create the Cortex Agent
-- -----------------------------------------------------------------------
/*
Create a Cortex Agent called HOL_QUALITY_AGENT in
HOL_DQ.SEMANTIC. Attach the HOL_DQ.SEMANTIC.ORDER_QUALITY
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


-- ========================================================================
-- TEST IN SNOWFLAKE INTELLIGENCE
-- ========================================================================
-- 1. Navigate to AI & ML → Agents → Snowflake Intelligence tab
-- 2. Click "Add existing agent", search HOL_QUALITY_AGENT, confirm
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
