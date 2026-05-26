-- ========================================================================
-- Exercise 2a: AI-Powered Enrichment Pipeline
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- Use Cortex AI functions to structure, enrich, protect, and de-noise
-- your data before it reaches the CLEAN schema.
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Extract structured address components with AI_EXTRACT
-- -----------------------------------------------------------------------
/*
Using AI_EXTRACT, extract the street/number, city, state, and zip_code from the
SHIPPING_ADDRESS column of HOL_DQ.RAW.ORDERS. Return the top 10
rows showing ORDER_ID, SHIPPING_ADDRESS, and the extracted fields.
Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 2: Redact PII from shipping addresses with AI_REDACT
-- -----------------------------------------------------------------------
/*
Use AI_REDACT to remove personally identifiable information from the
SHIPPING_ADDRESS column of HOL_DQ.RAW.ORDERS. Show ORDER_ID,
the original SHIPPING_ADDRESS, and the redacted version side by side
for 10 rows where SHIPPING_ADDRESS is not null. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- ========================================================================
-- COCO PROMPT 3: Combine all AI functions into one enrichment view
-- -----------------------------------------------------------------------
/*
Create a view called HOL_DQ.CLEAN.AI_ENRICHED_ORDERS that reads
from HOL_DQ.RAW.ORDERS and applies these transformations:
1. AI_EXTRACT to pull street/number, city, state, zip_code from SHIPPING_ADDRESS
2. AI_REDACT on SHIPPING_ADDRESS to produce a redacted_address column
3. Include ORDER_ID, CUSTOMER_ID, ORDER_TOTAL, ORDER_DATE, REGION,
   and all the AI-derived columns.
Execute the SQL.
*/
-- -----------------------------------------------------------------------
