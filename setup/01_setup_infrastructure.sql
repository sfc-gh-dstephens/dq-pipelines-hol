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
