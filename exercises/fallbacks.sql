-- ========================================================================
-- FALLBACKS — Presenter Use Only
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================
-- This file consolidates all fallback SQL from every exercise.
-- Keep this file OFF-SCREEN during the lab. Pull in queries as needed.
-- ========================================================================


-- ########################################################################
-- STEP 1: Fix Broken Quality Check
-- ########################################################################

SELECT
    region,
    COUNT(*)                                                      AS total_orders,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END)               AS null_customer_count,
    COUNT(CASE WHEN order_total < 0 THEN 1 END)                   AS negative_total_count,
    COUNT(CASE WHEN shipping_address IS NULL THEN 1 END)          AS missing_address_count,
    ROUND(
        COUNT(CASE WHEN customer_id IS NULL THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0), 2
    )                                                             AS null_pct
FROM HOL_DQ.RAW.ORDERS
GROUP BY region
ORDER BY total_orders DESC;

-- Expected: 4 rows (NORTH, SOUTH, EAST, WEST)
-- null_pct should be ~7–9% for each region
-- negative_total_count should be ~25–30 total across all regions


-- ########################################################################
-- STEP 2a: AI-Powered Enrichment Pipeline
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
-- STEP 2b: Freshness DMF
-- ########################################################################

ALTER TABLE HOL_DQ.RAW.ORDERS ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.FRESHNESS ON (ORDER_DATE);

SELECT
    SNOWFLAKE.CORE.FRESHNESS(SELECT ORDER_DATE FROM HOL_DQ.RAW.ORDERS) AS freshness_seconds,
    ROUND(SNOWFLAKE.CORE.FRESHNESS(SELECT ORDER_DATE FROM HOL_DQ.RAW.ORDERS) / 3600.0, 1) AS freshness_hours;

SELECT
    metric_name,
    value AS freshness_seconds,
    ROUND(value / 3600.0, 1) AS freshness_hours,
    measurement_time
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE table_name = 'ORDERS'
  AND table_schema = 'RAW'
  AND table_database = 'HOL_DQ'
  AND metric_name = 'FRESHNESS'
ORDER BY measurement_time DESC
LIMIT 10;


-- ########################################################################
-- STEP 2: Data Metric Functions
-- ########################################################################

-- Attach system DMFs
ALTER TABLE HOL_DQ.RAW.ORDERS
    ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
        ON (CUSTOMER_ID)
    SCHEDULE = 'TRIGGER_ON_CHANGES';

ALTER TABLE HOL_DQ.RAW.ORDERS
    ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT
        ON (ORDER_ID)
    SCHEDULE = 'TRIGGER_ON_CHANGES';

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
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
$$

ALTER TABLE HOL_DQ.RAW.ORDERS ADD DATA METRIC FUNCTION HOL_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT ON (SHIPPING_ADDRESS);

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


-- ########################################################################
-- STEP 3: Dynamic Table Pipeline
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
-- STEP 4: Notifications & Expectations
-- ########################################################################

CREATE OR REPLACE NOTIFICATION INTEGRATION HOL_DQ_EMAIL_INT
    TYPE = EMAIL
    ENABLED = TRUE
    ALLOWED_RECIPIENTS = ('dexter.stephens@snowflake.com');

ALTER DATABASE HOL_DQ SET DATA_QUALITY_MONITORING_SETTINGS =
  $$
  notification:
    enabled: TRUE
    integrations:
      - HOL_DQ_EMAIL_INT
    cooldown_hours: 1
    metadata_included: TRUE
  $$;

-- Add expectations to existing DMF associations
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

-- Test expectations on demand
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
-- STEP 5: Semantic View & Cortex Agent
-- ########################################################################

CREATE OR REPLACE SEMANTIC VIEW HOL_DQ.SEMANTIC.ORDER_QUALITY
  TABLES (
      HOL_DQ.CLEAN.VALIDATED_ORDERS AS ORDERS PRIMARY KEY (ORDER_ID),
      HOL_DQ.RAW.CUSTOMERS          AS CUSTOMERS PRIMARY KEY (CUSTOMER_ID)
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

CREATE OR REPLACE CORTEX AGENT HOL_DQ.SEMANTIC.HOL_QUALITY_AGENT
    ENABLED = TRUE
    COMMENT  = 'HOL data quality monitoring agent — powered by Cortex Code HOL'
    TOOLS    = (
        HOL_DQ.SEMANTIC.ORDER_QUALITY TYPE CORTEX_ANALYST_TOOL
    )
    TOOL_RESOURCES = (
        CORTEX_ANALYST_TOOL_RESOURCES = (
            SEMANTIC_MODELS = (HOL_DQ.SEMANTIC.ORDER_QUALITY)
        )
    );

GRANT USAGE ON CORTEX AGENT HOL_DQ.SEMANTIC.HOL_QUALITY_AGENT TO ROLE PUBLIC;
