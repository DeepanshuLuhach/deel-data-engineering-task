-- Creating analytics schema
CREATE SCHEMA IF NOT EXISTS analytics;

-- Creating relevant dimension tables
-- Customer dimension: SCD - 2
CREATE TABLE IF NOT EXISTS analytics.dim_customer (
    customer_id BIGINT PRIMARY KEY,                   -- Primary Key from operations.customers
    customer_name VARCHAR(500),
    customer_address VARCHAR(500),
    is_active_source BOOLEAN,                         -- The is_active status from operations.customers
    effective_start_date TIMESTAMP NOT NULL,          -- Timestamp when this version became active
    effective_end_date TIMESTAMP,                     -- Timestamp when this version was last active (NULL for current)
    is_current BOOLEAN NOT NULL DEFAULT FALSE         -- Flag indicating if this is the current active record
);

-- Product dimension: SCD - 1
CREATE TABLE IF NOT EXISTS analytics.dim_product (
    product_id BIGINT PRIMARY KEY,                -- Primary Key from operations.products
    product_name VARCHAR(500) NOT NULL,
    barcode VARCHAR(26) NOT NULL,
    unit_price DECIMAL,                   -- Current unit price from source (for reference)
    is_active_source BOOLEAN,                      -- The is_active status from the source
    created_at TIMESTAMP
);


-- Date dimension (Not created right now, future improvement. It will be one time insert)
-- CREATE TABLE analytics.dim_date (
--     date_id       DATE PRIMARY KEY,
--     year           INT,
--     quarter        INT,
--     month          INT,
--     day            INT,
--     day_of_week    INT,
--     is_weekend     BOOLEAN
-- );


-- Orders fact
-- We will keep changes to delivery_date and status in different rows to maintain history
CREATE TABLE IF NOT EXISTS analytics.fact_orders (
    order_sk  SERIAL PRIMARY KEY,                  -- Auto incremental sk
    order_id BIGINT NOT NULL UNIQUE,                  -- Primary Key from operations.orders
    customer_id BIGINT,                               -- Foreign Key to dim_customer
    order_date DATE,                               
    delivery_date DATE,                             
    status VARCHAR(50),                               -- Current status of the order
    order_created_at_timestamp TIMESTAMP,             -- From operations.orders.created_at
    order_updated_at_timestamp TIMESTAMP,             -- From operations.orders.updated_at

    FOREIGN KEY (customer_id) REFERENCES analytics.dim_customer (customer_id)
);

-- Order Items fact
CREATE TABLE IF NOT EXISTS analytics.fact_order_items (
    order_item_id BIGINT PRIMARY KEY,                 -- Primary Key from operations.order_items
    order_id BIGINT NOT NULL,                         -- Foreign Key to fact_order
    product_id BIGINT,                                -- Foreign Key to dim_product
    order_date DATE,                                 
    quantity INT,
    unit_price DECIMAL,                              
    total_amount DECIMAL,                             -- quantity * unit_price
    item_created TIMESTAMP,              
    item_updated TIMESTAMP,              

    FOREIGN KEY (order_id) REFERENCES analytics.fact_orders (order_id),
    FOREIGN KEY (product_id) REFERENCES analytics.dim_product (product_id)
);