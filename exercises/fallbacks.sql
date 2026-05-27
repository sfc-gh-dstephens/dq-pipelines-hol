-- ========================================================================
-- FALLBACKS — Presenter Use Only
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- This file consolidates all fallback SQL from every exercise.
-- Keep this file OFF-SCREEN during the lab. Pull in queries as needed.
-- ========================================================================


-- ########################################################################
-- STEP 1: Data Metric Functions & Freshness
-- ########################################################################

ALTER TABLE HOL_DQ.RAW.ORDERS
    SET DATA_METRIC_SCHEDULE = 'TRIGGER_ON_CHANGES';

-- Attach system DMFs
ALTER TABLE HOL_DQ.RAW.ORDERS
    ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
        ON (CUSTOMER_ID);

ALTER TABLE HOL_DQ.RAW.ORDERS
    ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT
        ON (ORDER_ID);

SELECT *
FROM TABLE(
    HOL_DQ.INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
        REF_ENTITY_NAME => 'HOL_DQ.RAW.ORDERS',
        REF_ENTITY_DOMAIN => 'TABLE'
    )
);

-- Custom DMF: negative totals
CREATE OR REPLACE DATA METRIC FUNCTION HOL_DQ.RAW.NEGATIVE_TOTAL_COUNT(
    arg_t TABLE(order_total FLOAT)
)
RETURNS NUMBER
AS $$
    SELECT COUNT(*)
    FROM arg_t
    WHERE order_total < 0
$$;

ALTER TABLE HOL_DQ.RAW.ORDERS ADD DATA METRIC FUNCTION HOL_DQ.RAW.NEGATIVE_TOTAL_COUNT ON (ORDER_TOTAL);

-- AI-powered DMF: suspicious addresses
CREATE OR REPLACE DATA METRIC FUNCTION HOL_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT(
    ARG_T TABLE(ARG_C VARCHAR(200))
)
RETURNS NUMBER
AS
$$
    SELECT COUNT(*)
    FROM ARG_T
    WHERE ARG_C IS NOT NULL
      AND SNOWFLAKE.CORTEX.AI_FILTER(PROMPT('This is a real US shipping address: {0}', ARG_C)) = FALSE
$$;

ALTER TABLE HOL_DQ.RAW.ORDERS ADD DATA METRIC FUNCTION HOL_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT ON (SHIPPING_ADDRESS);

-- Freshness DMF
ALTER TABLE HOL_DQ.RAW.ORDERS ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.FRESHNESS ON (ORDER_DATE);

SELECT
    SNOWFLAKE.CORE.FRESHNESS(SELECT ORDER_DATE FROM HOL_DQ.RAW.ORDERS) AS freshness_seconds,
    ROUND(SNOWFLAKE.CORE.FRESHNESS(SELECT ORDER_DATE FROM HOL_DQ.RAW.ORDERS) / 3600.0, 1) AS freshness_hours;




-- ########################################################################
-- STEP 2: Expectations
-- ########################################################################

ALTER TABLE HOL_DQ.RAW.ORDERS
  MODIFY DATA METRIC FUNCTION HOL_DQ.RAW.NEGATIVE_TOTAL_COUNT ON (ORDER_TOTAL)
    ADD EXPECTATION few_negatives (VALUE < 50);

ALTER TABLE HOL_DQ.RAW.ORDERS
  MODIFY DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT ON (ORDER_ID)
    ADD EXPECTATION no_duplicates (VALUE = 0);

ALTER TABLE HOL_DQ.RAW.ORDERS
  MODIFY DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT ON (CUSTOMER_ID)
    ADD EXPECTATION low_nulls (VALUE < 200);

ALTER TABLE HOL_DQ.RAW.ORDERS
  MODIFY DATA METRIC FUNCTION SNOWFLAKE.CORE.FRESHNESS ON (ORDER_DATE)
    ADD EXPECTATION fresh_data (VALUE < 86400);




-- ########################################################################
-- STEP 3: Notifications
-- ########################################################################

CREATE OR REPLACE NOTIFICATION INTEGRATION HOL_DQ_EMAIL_INT
    TYPE = EMAIL
    ENABLED = TRUE
    ALLOWED_RECIPIENTS = ('<email>');

ALTER DATABASE HOL_DQ SET DATA_QUALITY_MONITORING_SETTINGS =
  $$
  notification:
    enabled: TRUE
    integrations:
      - HOL_DQ_EMAIL_INT
    cooldown_hours: 1
    metadata_included: TRUE
  $$;


-- ########################################################################
-- STEP 4: Check Quality Results (run after data insertion)
-- ########################################################################

-- Query DMF results
SELECT
    metric_name,
    value,
    measurement_time
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE table_name  = 'ORDERS'
  AND table_schema = 'RAW'
  AND table_database = 'HOL_DQ'
ORDER BY measurement_time DESC
LIMIT 20;

-- Manual DMF calls (if results not yet available)
SELECT SNOWFLAKE.CORE.NULL_COUNT(SELECT CUSTOMER_ID FROM HOL_DQ.RAW.ORDERS);
SELECT SNOWFLAKE.CORE.DUPLICATE_COUNT(SELECT ORDER_ID FROM HOL_DQ.RAW.ORDERS);
SELECT HOL_DQ.RAW.NEGATIVE_TOTAL_COUNT(SELECT ORDER_TOTAL FROM HOL_DQ.RAW.ORDERS);

-- Evaluate expectations on demand
SELECT * FROM TABLE(SYSTEM$EVALUATE_DATA_QUALITY_EXPECTATIONS(
    REF_ENTITY_NAME => 'HOL_DQ.RAW.ORDERS'));

-- Check expectation violation history
SELECT *
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_EXPECTATION_STATUS
WHERE table_name = 'ORDERS'
  AND table_schema = 'RAW'
  AND table_database = 'HOL_DQ'
ORDER BY measurement_time DESC
LIMIT 20;


-- ########################################################################
-- STEP 5: AI-Powered Enrichment Pipeline
-- ########################################################################

-- AI_EXTRACT: structured address components
SELECT
    order_id,
    shipping_address,
    AI_EXTRACT(
        shipping_address,
        {'street': 'number and street', 'city': 'city name', 'state': 'US state abbreviation', 'zip_code': '5-digit zip code'}
    ) AS address_components
FROM HOL_DQ.RAW.ORDERS
WHERE shipping_address IS NOT NULL
LIMIT 10;

-- AI_REDACT: PII removal from addresses
SELECT
    order_id,
    shipping_address AS original_address,
    AI_REDACT(shipping_address) AS redacted_address
FROM HOL_DQ.RAW.ORDERS
WHERE shipping_address IS NOT NULL
LIMIT 10;

-- Combined AI enrichment view
CREATE OR REPLACE VIEW HOL_DQ.CLEAN.AI_ENRICHED_ORDERS AS
SELECT
    order_id,
    customer_id,
    order_total,
    order_date,
    region,
    shipping_address,
    AI_EXTRACT(
        shipping_address,
        {'street': 'number and street', 'city': 'city name', 'state': 'US state abbreviation', 'zip_code': '5-digit zip code'}
    ) AS address_components,
    AI_REDACT(shipping_address) AS  redacted_address
FROM HOL_DQ.RAW.ORDERS;

SELECT * FROM HOL_DQ.CLEAN.AI_ENRICHED_ORDERS LIMIT 5;


-- ########################################################################
-- STEP 6: Dynamic Table Pipeline
-- ########################################################################

CREATE OR REPLACE DYNAMIC TABLE HOL_DQ.CLEAN.VALIDATED_ORDERS
    TARGET_LAG    = '1 minute'
    WAREHOUSE     = HOL_DQ_WH
    REFRESH_MODE  = AUTO
    INITIALIZE    = ON_CREATE
AS
WITH
deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date ASC) AS rn
    FROM HOL_DQ.RAW.ORDERS
),
base AS (
    SELECT order_id, customer_id, product_id, quantity, unit_price,
           order_total, order_date, status, shipping_address, region
    FROM deduped
    WHERE rn = 1
),
scored AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        quantity,
        unit_price,
        order_total,
        order_date,
        status,
        shipping_address,
        region,
        customer_id IS NULL AS is_null_customer,
        order_total < 0     AS is_negative_total,
        100
            - CASE WHEN order_total = 0                                   THEN 20 ELSE 0 END
            - CASE WHEN shipping_address IS NULL                          THEN 15 ELSE 0 END
            - CASE WHEN ABS(order_total - (quantity * unit_price)) > 1.00 THEN 10 ELSE 0 END
        AS quality_score
    FROM base
)
SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    unit_price,
    order_total,
    order_date,
    status,
    shipping_address,
    region,
    CASE
        WHEN is_null_customer OR is_negative_total THEN 0
        ELSE quality_score
    END AS quality_score,
    CASE
        WHEN is_null_customer OR is_negative_total THEN 'REJECTED'
        WHEN quality_score >= 90                   THEN 'CLEAN'
        ELSE 'REVIEW_NEEDED'
    END AS quality_status
FROM scored;

-- Verify
SELECT quality_status, COUNT(*) AS order_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM HOL_DQ.CLEAN.VALIDATED_ORDERS
GROUP BY quality_status
ORDER BY quality_status;

SELECT region, quality_status, COUNT(*) AS cnt
FROM HOL_DQ.CLEAN.VALIDATED_ORDERS
GROUP BY region, quality_status
ORDER BY region, quality_status;

SELECT name, state, state_message, refresh_start_time, refresh_end_time
FROM TABLE(HOL_DQ.INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    NAME => 'HOL_DQ.CLEAN.VALIDATED_ORDERS'
))
ORDER BY refresh_start_time DESC
LIMIT 5;


-- ########################################################################
-- STEP 7: Semantic View & Cortex Agent
-- ########################################################################

CREATE OR REPLACE SEMANTIC VIEW HOL_DQ.SEMANTIC.ORDER_QUALITY
  TABLES (
      ORDERS AS HOL_DQ.CLEAN.VALIDATED_ORDERS PRIMARY KEY (ORDER_ID),
      CUSTOMERS AS HOL_DQ.RAW.CUSTOMERS PRIMARY KEY (CUSTOMER_ID)
  )
  RELATIONSHIPS (
      orders_to_customers AS ORDERS (CUSTOMER_ID) REFERENCES CUSTOMERS (CUSTOMER_ID)
  )
  FACTS (
      ORDERS.ORDER_TOTAL AS ORDER_TOTAL,
      ORDERS.QUALITY_SCORE AS QUALITY_SCORE
  )
  DIMENSIONS (
      ORDERS.REGION AS REGION,
      ORDERS.QUALITY_STATUS AS QUALITY_STATUS,
      ORDERS.STATUS AS STATUS,
      CUSTOMERS.TIER AS TIER
  )
  METRICS (
      ORDERS.total_orders AS COUNT(ORDER_ID),
      ORDERS.clean_order_count AS COUNT_IF(QUALITY_STATUS = 'CLEAN'),
      ORDERS.rejected_count AS COUNT_IF(QUALITY_STATUS = 'REJECTED'),
      ORDERS.review_needed_count AS COUNT_IF(QUALITY_STATUS = 'REVIEW_NEEDED'),
      ORDERS.clean_order_rate AS ROUND(COUNT_IF(QUALITY_STATUS = 'CLEAN') * 100.0 / NULLIF(COUNT(ORDER_ID), 0), 2),
      ORDERS.avg_quality_score AS ROUND(AVG(QUALITY_SCORE), 1),
      ORDERS.null_customer_count AS COUNT_IF(CUSTOMER_ID IS NULL),
      ORDERS.negative_total_count AS COUNT_IF(ORDER_TOTAL < 0)
  );

CREATE OR REPLACE AGENT HOL_DQ.SEMANTIC.HOL_QUALITY_AGENT
  COMMENT = 'HOL data quality monitoring agent'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: "Respond concisely with bullet points. Always include a breakdown by region when relevant. Highlight the WEST region specifically when quality scores or rejection rates are a concern. Suggest a root cause for any metric that is more than 10% worse than the overall average."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "OrderQualityAnalyst"
        description: "Analyzes order quality metrics including rejection rates, quality scores, and data quality status across regions and customer tiers from the validated orders pipeline."

  tool_resources:
    OrderQualityAnalyst:
      semantic_view: "HOL_DQ.SEMANTIC.ORDER_QUALITY"
  $$;

GRANT USAGE ON AGENT HOL_DQ.SEMANTIC.HOL_QUALITY_AGENT TO ROLE PUBLIC;
