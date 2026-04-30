-- ========================================================================
-- Exercise 2: Create Data Metric Functions
-- From Raw to Reliable: Build AI-Powered Data Quality Pipelines
-- ========================================================================


-- ========================================================================
-- COCO PROMPT 1: Attach system DMFs to RAW.ORDERS
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Attach two system Data Metric Functions to BRIGHTCART_DQ.RAW.ORDERS:
1. SNOWFLAKE.CORE.NULL_COUNT on the CUSTOMER_ID column
2. SNOWFLAKE.CORE.DUPLICATE_COUNT on the ORDER_ID column

Set the schedule to TRIGGER_ON_CHANGES.
Then query INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES to confirm
both DMFs are attached. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- FALLBACK (presenter use only):
ALTER TABLE BRIGHTCART_DQ.RAW.ORDERS
    ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT
        ON (CUSTOMER_ID)
    SCHEDULE = 'TRIGGER_ON_CHANGES';

ALTER TABLE BRIGHTCART_DQ.RAW.ORDERS
    ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.DUPLICATE_COUNT
        ON (ORDER_ID)
    SCHEDULE = 'TRIGGER_ON_CHANGES';

-- Confirm DMFs are attached
SELECT metric_name, ref_column_names, schedule, schedule_status
FROM TABLE(
    INFORMATION_SCHEMA.DATA_METRIC_FUNCTION_REFERENCES(
        REF_ENTITY_NAME => 'BRIGHTCART_DQ.RAW.ORDERS',
        REF_ENTITY_DOMAIN => 'TABLE'
    )
);


-- ========================================================================
-- COCO PROMPT 2: Create a custom DMF for negative order totals
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Create a custom Data Metric Function in BRIGHTCART_DQ.RAW called
NEGATIVE_TOTAL_COUNT that counts rows where order_total is less than zero.
Then attach it to BRIGHTCART_DQ.RAW.ORDERS on the ORDER_TOTAL column
with TRIGGER_ON_CHANGES schedule. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- FALLBACK (presenter use only):
CREATE OR REPLACE DATA METRIC FUNCTION BRIGHTCART_DQ.RAW.NEGATIVE_TOTAL_COUNT(
    arg_t TABLE(order_total FLOAT)
)
RETURNS NUMBER
AS $$
    SELECT COUNT(*)
    FROM arg_t
    WHERE order_total < 0
$$;

ALTER TABLE BRIGHTCART_DQ.RAW.ORDERS
    ADD DATA METRIC FUNCTION BRIGHTCART_DQ.RAW.NEGATIVE_TOTAL_COUNT
        ON (ORDER_TOTAL)
    SCHEDULE = 'TRIGGER_ON_CHANGES';


-- ========================================================================
-- COCO PROMPT 3: AI-powered DMF using Cortex AI_FILTER
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Create an AI-powered Data Metric Function in BRIGHTCART_DQ.RAW called
AI_SUSPICIOUS_ADDRESS_COUNT. It should take a TABLE argument with a
shipping_address column and return the count of rows where
SNOWFLAKE.CORTEX.AI_FILTER classifies the address as NOT a real US
shipping address. Attach it to BRIGHTCART_DQ.RAW.ORDERS on the
SHIPPING_ADDRESS column with TRIGGER_ON_CHANGES schedule. Execute the SQL.
*/
-- -----------------------------------------------------------------------


-- FALLBACK (presenter use only):
CREATE OR REPLACE DATA METRIC FUNCTION BRIGHTCART_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT(
    arg_t TABLE(shipping_address VARCHAR)
)
RETURNS NUMBER
AS $$
    SELECT COUNT(*)
    FROM arg_t
    WHERE shipping_address IS NOT NULL
      AND NOT SNOWFLAKE.CORTEX.AI_FILTER(
          ARRAY_CONSTRUCT(
              OBJECT_CONSTRUCT(
                  'role', 'user',
                  'content', 'Does this look like a real US shipping address? '
                             || 'Answer only yes or no: '
                             || COALESCE(shipping_address, 'NULL')
              )
          ),
          'yes'
      )
$$;

ALTER TABLE BRIGHTCART_DQ.RAW.ORDERS
    ADD DATA METRIC FUNCTION BRIGHTCART_DQ.RAW.AI_SUSPICIOUS_ADDRESS_COUNT
        ON (SHIPPING_ADDRESS)
    SCHEDULE = 'TRIGGER_ON_CHANGES';


-- ========================================================================
-- COCO PROMPT 4: Query quality results
-- -----------------------------------------------------------------------
-- Paste into the Cortex Code panel:
-- -----------------------------------------------------------------------
/*
Show me the latest Data Metric Function results for
BRIGHTCART_DQ.RAW.ORDERS from SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS.
Include the metric name, value, and measurement timestamp.
Order by measurement timestamp descending.
*/
-- -----------------------------------------------------------------------


-- FALLBACK (presenter use only):
SELECT
    metric_name,
    value,
    measurement_time
FROM SNOWFLAKE.LOCAL.DATA_QUALITY_MONITORING_RESULTS
WHERE table_name  = 'ORDERS'
  AND table_schema = 'RAW'
  AND table_database = 'BRIGHTCART_DQ'
ORDER BY measurement_time DESC
LIMIT 20;

-- NOTE: DMF results may take 1–2 minutes to appear after attachment.
-- If the result view is empty, run the following to trigger manually:
--
-- SELECT SYSTEM$TRIGGER_DATA_METRIC_FUNCTION_EVENTS(
--     'BRIGHTCART_DQ.RAW.ORDERS'
-- );
