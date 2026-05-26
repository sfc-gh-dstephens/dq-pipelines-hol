USE ROLE ACCOUNTADMIN;

-- ========================================================================
-- INFRASTRUCTURE
-- ========================================================================

CREATE WAREHOUSE IF NOT EXISTS HOL_DQ_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND  = 300
    AUTO_RESUME   = TRUE;

USE WAREHOUSE HOL_DQ_WH;

CREATE OR REPLACE DATABASE HOL_DQ;
USE DATABASE HOL_DQ;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CLEAN;
CREATE SCHEMA IF NOT EXISTS SEMANTIC;

-- ========================================================================
-- TABLES
-- ========================================================================

CREATE TABLE IF NOT EXISTS RAW.ORDERS (
    order_id          VARCHAR(20),
    customer_id       VARCHAR(20),    -- known issue: ~8% NULL
    product_id        VARCHAR(20),
    quantity          INTEGER,
    unit_price        FLOAT,
    order_total       FLOAT,          -- known issue: ~2% negative values
    order_date        DATE,
    status            VARCHAR(20),    -- PENDING, PROCESSING, SHIPPED, DELIVERED
    shipping_address  VARCHAR(200),
    region            VARCHAR(20),
    customer_notes    VARCHAR(500)    -- free-text feedback; ~30% populated
);

CREATE TABLE IF NOT EXISTS RAW.CUSTOMERS (
    customer_id  VARCHAR(20),         -- known issue: ~2% duplicates
    email        VARCHAR(100),        -- known issue: ~5% malformed
    first_name   VARCHAR(50),
    last_name    VARCHAR(50),
    phone        VARCHAR(20),
    signup_date  DATE,
    region       VARCHAR(20),
    tier         VARCHAR(20)          -- BRONZE, SILVER, GOLD, PLATINUM
);

CREATE TABLE IF NOT EXISTS RAW.PRODUCTS (
    product_id    VARCHAR(20),
    product_name  VARCHAR(100),
    category      VARCHAR(50),        -- known issue: ~5% invalid category codes
    unit_price    FLOAT,              -- known issue: ~3% extreme outliers ($0 or $99999)
    is_active     BOOLEAN
);

CREATE TABLE IF NOT EXISTS RAW.INVENTORY (
    inventory_id      VARCHAR(20),
    product_id        VARCHAR(20),    -- known issue: ~3% orphaned (not in PRODUCTS)
    warehouse_location VARCHAR(20),
    quantity_on_hand  INTEGER,        -- known issue: ~5% negative
    last_updated      TIMESTAMP,
    reorder_point     INTEGER
);

CREATE TABLE IF NOT EXISTS RAW.SHIPMENTS (
    shipment_id        VARCHAR(20),
    order_id           VARCHAR(20),
    carrier            VARCHAR(50),
    tracking_number    VARCHAR(50),   -- known issue: ~5% NULL where status='DELIVERED'
    ship_date          DATE,          -- known issue: ~4% future dates (wrong year)
    estimated_delivery DATE,
    actual_delivery    DATE,
    status             VARCHAR(20)    -- PENDING, IN_TRANSIT, DELIVERED, RETURNED
);

-- ========================================================================
-- DATA: RAW.ORDERS  (~5,000 rows + ~150 duplicate order_ids)
-- ========================================================================

TRUNCATE TABLE IF EXISTS RAW.ORDERS;

INSERT INTO RAW.ORDERS
SELECT
    'ORD-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 6, '0') AS order_id,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 8
         THEN NULL
         ELSE 'CUST-' || LPAD(UNIFORM(1, 2000, RANDOM())::VARCHAR, 5, '0')
    END AS customer_id,
    'PROD-' || LPAD(UNIFORM(1, 500, RANDOM())::VARCHAR, 4, '0') AS product_id,
    UNIFORM(1, 25, RANDOM())::INTEGER AS quantity,
    ROUND(UNIFORM(5, 299, RANDOM())::FLOAT + RANDOM(), 2) AS unit_price,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 2
         THEN ROUND(-UNIFORM(10, 500, RANDOM())::FLOAT, 2)   -- ~2% negative totals
         ELSE ROUND(UNIFORM(1, 25, RANDOM()) * (UNIFORM(5, 299, RANDOM())::FLOAT), 2)
    END AS order_total,
    DATEADD('day', -UNIFORM(0, 365, RANDOM()), CURRENT_DATE()) AS order_date,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'PENDING'
        WHEN 2 THEN 'PROCESSING'
        WHEN 3 THEN 'SHIPPED'
        ELSE 'DELIVERED'
    END AS status,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN UNIFORM(100, 9999, RANDOM())::VARCHAR || ' Oak St, Austin TX 78701'
        WHEN 2 THEN UNIFORM(100, 9999, RANDOM())::VARCHAR || ' Pine Ave, Seattle WA 98101'
        WHEN 3 THEN UNIFORM(100, 9999, RANDOM())::VARCHAR || ' Main Blvd, Chicago IL 60601'
        ELSE UNIFORM(100, 9999, RANDOM())::VARCHAR || ' Elm Dr, Miami FL 33101'
    END AS shipping_address,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'NORTH'
        WHEN 2 THEN 'SOUTH'
        WHEN 3 THEN 'EAST'
        ELSE 'WEST'
    END AS region,
    CASE
        WHEN UNIFORM(1, 100, RANDOM()) <= 10
            THEN CASE UNIFORM(1, 5, RANDOM())
                WHEN 1 THEN 'Excellent service, arrived ahead of schedule!'
                WHEN 2 THEN 'Love this product, will order again.'
                WHEN 3 THEN 'Great quality and fast shipping.'
                WHEN 4 THEN 'Perfect, exactly as described.'
                ELSE 'Very satisfied with my purchase.'
            END
        WHEN UNIFORM(1, 100, RANDOM()) <= 20
            THEN CASE UNIFORM(1, 5, RANDOM())
                WHEN 1 THEN 'Item arrived damaged, requesting replacement.'
                WHEN 2 THEN 'Wrong item shipped. Very disappointed.'
                WHEN 3 THEN 'Terrible experience. Product defective on arrival.'
                WHEN 4 THEN 'Waited 3 weeks and still no delivery. Unacceptable.'
                ELSE 'Package was open when it arrived. Not happy at all.'
            END
        WHEN UNIFORM(1, 100, RANDOM()) <= 30
            THEN CASE UNIFORM(1, 5, RANDOM())
                WHEN 1 THEN 'Decent product but shipping was slow.'
                WHEN 2 THEN 'Ok quality for the price. Nothing special.'
                WHEN 3 THEN 'Works fine but packaging could be better.'
                WHEN 4 THEN 'Average experience overall.'
                ELSE 'Product is fine, delivery took longer than expected.'
            END
        ELSE NULL
    END AS customer_notes
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- Inject ~150 duplicate order_ids (simulates upstream deduplication failures)
INSERT INTO RAW.ORDERS
SELECT order_id, customer_id, product_id, quantity, unit_price,
       order_total, order_date, status, shipping_address, region, customer_notes
FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn
    FROM RAW.ORDERS
)
WHERE rn <= 150;

-- ========================================================================
-- DATA: RAW.CUSTOMERS  (~2,000 rows + ~40 duplicate customer_ids)
-- ========================================================================

TRUNCATE TABLE IF EXISTS RAW.CUSTOMERS;

INSERT INTO RAW.CUSTOMERS
SELECT
    'CUST-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 5, '0') AS customer_id,
    CASE
        WHEN UNIFORM(1, 100, RANDOM()) <= 2
            THEN 'user' || SEQ4()::VARCHAR || 'nodomain.com'      -- missing @
        WHEN UNIFORM(1, 100, RANDOM()) <= 4
            THEN '@HOL.com'                                  -- missing local part
        WHEN UNIFORM(1, 100, RANDOM()) <= 5
            THEN 'user' || SEQ4()::VARCHAR || '@@HOL.com'   -- double @
        ELSE 'user' || SEQ4()::VARCHAR || '@HOL.com'
    END AS email,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'James'   WHEN 2 THEN 'Sarah'   WHEN 3 THEN 'Michael'
        WHEN 4 THEN 'Emily'   WHEN 5 THEN 'David'   WHEN 6 THEN 'Jessica'
        WHEN 7 THEN 'Robert'  WHEN 8 THEN 'Lisa'    WHEN 9 THEN 'William'
        ELSE 'Ashley'
    END AS first_name,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'Smith'    WHEN 2 THEN 'Johnson'  WHEN 3 THEN 'Williams'
        WHEN 4 THEN 'Brown'    WHEN 5 THEN 'Jones'    WHEN 6 THEN 'Garcia'
        WHEN 7 THEN 'Miller'   WHEN 8 THEN 'Davis'    WHEN 9 THEN 'Wilson'
        ELSE 'Taylor'
    END AS last_name,
    '555-' || LPAD(UNIFORM(100, 999, RANDOM())::VARCHAR, 3, '0') || '-' ||
              LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0') AS phone,
    DATEADD('day', -UNIFORM(0, 1095, RANDOM()), CURRENT_DATE()) AS signup_date,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'NORTH' WHEN 2 THEN 'SOUTH'
        WHEN 3 THEN 'EAST'  ELSE 'WEST'
    END AS region,
    CASE UNIFORM(1, 10, RANDOM())
        WHEN 1 THEN 'PLATINUM'  WHEN 2 THEN 'PLATINUM'
        WHEN 3 THEN 'GOLD'      WHEN 4 THEN 'GOLD'     WHEN 5 THEN 'GOLD'
        WHEN 6 THEN 'SILVER'    WHEN 7 THEN 'SILVER'
        ELSE 'BRONZE'
    END AS tier
FROM TABLE(GENERATOR(ROWCOUNT => 2000));

-- Inject ~40 duplicate customer_ids
INSERT INTO RAW.CUSTOMERS
SELECT customer_id, email, first_name, last_name, phone, signup_date, region, tier
FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn
    FROM RAW.CUSTOMERS
)
WHERE rn <= 40;

-- ========================================================================
-- DATA: RAW.PRODUCTS  (~500 rows)
-- ========================================================================

TRUNCATE TABLE IF EXISTS RAW.PRODUCTS;

INSERT INTO RAW.PRODUCTS
SELECT
    'PROD-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 4, '0') AS product_id,
    CASE UNIFORM(1, 8, RANDOM())
        WHEN 1 THEN 'Wireless Headphones'  WHEN 2 THEN 'USB-C Hub'
        WHEN 3 THEN 'Laptop Stand'         WHEN 4 THEN 'Mechanical Keyboard'
        WHEN 5 THEN 'HD Webcam'            WHEN 6 THEN 'Monitor Arm'
        WHEN 7 THEN 'Mouse Pad XL'         ELSE 'LED Desk Lamp'
    END || ' ' || SEQ4()::VARCHAR AS product_name,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 5
        THEN CASE UNIFORM(1, 3, RANDOM())
            WHEN 1 THEN 'ELECTRNICS'   -- typo
            WHEN 2 THEN 'ACCESORIES'   -- typo
            ELSE 'PRIPHERALS'          -- typo
        END
        ELSE CASE UNIFORM(1, 4, RANDOM())
            WHEN 1 THEN 'ELECTRONICS'
            WHEN 2 THEN 'ACCESSORIES'
            WHEN 3 THEN 'PERIPHERALS'
            ELSE 'OFFICE'
        END
    END AS category,
    CASE
        WHEN UNIFORM(1, 100, RANDOM()) <= 2 THEN 0.00            -- $0 price (data gap)
        WHEN UNIFORM(1, 100, RANDOM()) <= 3 THEN 99999.99        -- extreme outlier
        ELSE ROUND(UNIFORM(9, 799, RANDOM())::FLOAT + RANDOM(), 2)
    END AS unit_price,
    CASE WHEN UNIFORM(1, 10, RANDOM()) > 1 THEN TRUE ELSE FALSE END AS is_active
FROM TABLE(GENERATOR(ROWCOUNT => 500));

-- ========================================================================
-- DATA: RAW.INVENTORY  (~1,000 rows)
-- ========================================================================

TRUNCATE TABLE IF EXISTS RAW.INVENTORY;

INSERT INTO RAW.INVENTORY
SELECT
    'INV-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 5, '0') AS inventory_id,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 3
         THEN 'PROD-' || LPAD(UNIFORM(501, 600, RANDOM())::VARCHAR, 4, '0')  -- orphaned IDs
         ELSE 'PROD-' || LPAD(UNIFORM(1, 500, RANDOM())::VARCHAR, 4, '0')
    END AS product_id,
    CASE UNIFORM(1, 3, RANDOM())
        WHEN 1 THEN 'WH-EAST'
        WHEN 2 THEN 'WH-WEST'
        ELSE 'WH-CENTRAL'
    END AS warehouse_location,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 5
         THEN -UNIFORM(1, 200, RANDOM())::INTEGER   -- negative stock
         ELSE UNIFORM(0, 5000, RANDOM())::INTEGER
    END AS quantity_on_hand,
    DATEADD('hour', -UNIFORM(0, 720, RANDOM()), CURRENT_TIMESTAMP()) AS last_updated,
    UNIFORM(10, 200, RANDOM())::INTEGER AS reorder_point
FROM TABLE(GENERATOR(ROWCOUNT => 1000));

-- ========================================================================
-- DATA: RAW.SHIPMENTS  (~4,000 rows)
-- ========================================================================

TRUNCATE TABLE IF EXISTS RAW.SHIPMENTS;

INSERT INTO RAW.SHIPMENTS
SELECT
    'SHIP-' || LPAD(ROW_NUMBER() OVER (ORDER BY SEQ4())::VARCHAR, 6, '0') AS shipment_id,
    'ORD-' || LPAD(UNIFORM(1, 5000, RANDOM())::VARCHAR, 6, '0') AS order_id,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'FedEx' WHEN 2 THEN 'UPS'
        WHEN 3 THEN 'USPS'  ELSE 'DHL'
    END AS carrier,
    '1Z' || UPPER(LPAD(ABS(HASH(SEQ4()))::VARCHAR, 12, '0')) AS tracking_number,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 4
         THEN DATEADD('year', 1, DATEADD('day', -UNIFORM(0, 90, RANDOM()), CURRENT_DATE()))
         ELSE DATEADD('day', -UNIFORM(0, 180, RANDOM()), CURRENT_DATE())
    END AS ship_date,
    DATEADD('day', UNIFORM(1, 10, RANDOM()), CURRENT_DATE()) AS estimated_delivery,
    CASE WHEN UNIFORM(1, 4, RANDOM()) = 1
         THEN NULL
         ELSE DATEADD('day', -UNIFORM(0, 30, RANDOM()), CURRENT_DATE())
    END AS actual_delivery,
    CASE UNIFORM(1, 4, RANDOM())
        WHEN 1 THEN 'PENDING'
        WHEN 2 THEN 'IN_TRANSIT'
        WHEN 3 THEN 'DELIVERED',
        ELSE 'RETURNED'
    END AS status
FROM TABLE(GENERATOR(ROWCOUNT => 4000));

-- Inject NULL tracking_number on ~20% of DELIVERED shipments (~5% of total)
UPDATE HOL_DQ.RAW.SHIPMENTS
SET tracking_number = NULL
WHERE status = 'DELIVERED'
  AND UNIFORM(1, 5, RANDOM()) = 1;

-- ========================================================================
-- VERIFY: Paste this prompt into Cortex Code to confirm data loaded
-- ========================================================================
--
--   Show me row counts for all tables in HOL_DQ.RAW
--
-- Expected output:
--   ORDERS     ~5,150
--   CUSTOMERS  ~2,040
--   PRODUCTS      500
--   INVENTORY   1,000
--   SHIPMENTS   4,000
--
-- ========================================================================
SELECT 'RAW.ORDERS'    AS table_name, COUNT(*) AS row_count FROM HOL_DQ.RAW.ORDERS    UNION ALL
SELECT 'RAW.CUSTOMERS'               , COUNT(*)             FROM HOL_DQ.RAW.CUSTOMERS  UNION ALL
SELECT 'RAW.PRODUCTS'                , COUNT(*)             FROM HOL_DQ.RAW.PRODUCTS   UNION ALL
SELECT 'RAW.INVENTORY'               , COUNT(*)             FROM HOL_DQ.RAW.INVENTORY  UNION ALL
SELECT 'RAW.SHIPMENTS'               , COUNT(*)             FROM HOL_DQ.RAW.SHIPMENTS
ORDER BY table_name;
