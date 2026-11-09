# Database and table creation

CREATE DATABASE ecommerce_analytics;

USE ecommerce_analytics;

SELECT DATABASE();

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    signup_date DATETIME,
    acquisition_channel VARCHAR(50),
    city VARCHAR(100)
);

DESCRIBE customers;

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    list_price DECIMAL(12,2),
    unit_cost DECIMAL(12,2)
);

DESCRIBE products;

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATETIME,
    order_status VARCHAR(30),
    order_value DECIMAL(12,2),

    CONSTRAINT fk_orders_customers
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

DESCRIBE orders;

SHOW CREATE TABLE orders;

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(12,2),
    unit_cost DECIMAL(12,2),

    CONSTRAINT fk_items_orders
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id),

    CONSTRAINT fk_items_products
    FOREIGN KEY (product_id)
    REFERENCES products(product_id)
);


DESCRIBE order_items;

CREATE TABLE events (
    event_id INT PRIMARY KEY,
    session_id VARCHAR(50),
    customer_id INT,
    event_name VARCHAR(50),
    event_time DATETIME,

    CONSTRAINT fk_events_customers
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

DESCRIBE events;

CREATE TABLE marketing_spend (
    spend_id INT PRIMARY KEY,
    date DATE,
    channel VARCHAR(100),
    campaign VARCHAR(150),
    spend DECIMAL(14,2)
);

DESCRIBE marketing_spend;

CREATE TABLE refunds (
    refund_id INT PRIMARY KEY,
    order_id INT,
    refund_amount DECIMAL(12,2),
    refund_date DATETIME,
    refund_reason VARCHAR(100),

    CONSTRAINT fk_refunds_orders
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
);

DESCRIBE refunds;

SHOW TABLES;

SELECT DATABASE();

# Data Loading and Validation

# Check total records
SELECT COUNT(*) AS total_customers
FROM customers;

# Check first 10 records
SELECT *
FROM customers
LIMIT 10;

# Check date range
SELECT
    MIN(signup_date) AS first_signup,
    MAX(signup_date) AS last_signup
FROM customers;

SELECT count(*) as total_orders from orders;

select count(*) as total_order_items from order_items;

DELETE FROM order_items
WHERE order_item_id > 0;


SELECT COUNT(*) AS remaining_records
FROM order_items;

SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

SHOW VARIABLES LIKE 'local_infile';

LOAD DATA LOCAL INFILE 'C:/Users/HP/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(order_item_id, order_id, product_id, quantity, unit_price, unit_cost);

SHOW VARIABLES LIKE 'local_infile';

# Load order items
LOAD DATA LOCAL INFILE 'C:/Users/HP/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_item_id, order_id, product_id, quantity, unit_price, unit_cost);

select count(*) as total_order_items from order_items;

# Load events
LOAD DATA LOCAL INFILE 'C:/Users/HP/events.csv'
INTO TABLE events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(event_id, session_id, customer_id, event_name, event_time);

SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT event_id) AS unique_events
FROM events;

# Load refunds
LOAD DATA LOCAL INFILE 'C:/Users/HP/refunds.csv'
INTO TABLE refunds
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(refund_id, order_id, refund_amount, refund_date, refund_reason);

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT refund_id) AS unique_refund_ids
FROM refunds;

# Marketing spend
LOAD DATA LOCAL INFILE 'C:/Users/HP/marketing_spend.csv'
INTO TABLE marketing_spend
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(spend_id, date, channel, campaign, spend);

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT spend_id) AS unique_spend_ids
FROM marketing_spend;

USE ecommerce_analytics;

SELECT 'customers' AS table_name, COUNT(*) AS total_records FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'events', COUNT(*) FROM events
UNION ALL
SELECT 'refunds', COUNT(*) FROM refunds
UNION ALL
SELECT 'marketing_spend', COUNT(*) FROM marketing_spend;

SELECT DISTINCT order_status
FROM orders;

SELECT DISTINCT acquisition_channel
FROM customers;

SELECT DISTINCT channel
FROM marketing_spend;

SELECT DISTINCT event_name
FROM events;

SELECT DISTINCT refund_reason
FROM refunds;

# Date Validation

# Orders placed before customers signup
SELECT COUNT(*) AS invalid_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date < c.signup_date;

# Refunds issued before the original order
SELECT COUNT(*) AS invalid_refunds
FROM refunds r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.refund_date < o.order_date;

# Check the date ranges
SELECT
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order
FROM orders;

SELECT
    MIN(signup_date) AS first_signup,
    MAX(signup_date) AS last_signup
FROM customers;

# Business-rule validation

# Check1: Refunds against cancelled orders
SELECT COUNT(*) AS refunds_for_cancelled_orders
FROM refunds r
JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_status = 'Cancelled';

# Refunds against returned, delivered and cancelled orders
SELECT
    o.order_status,
    COUNT(DISTINCT r.refund_id) AS refund_count,
    ROUND(SUM(r.refund_amount), 2) AS total_refund
FROM orders o
LEFT JOIN refunds r
    ON o.order_id = r.order_id
GROUP BY o.order_status;

# Refund amount greater than original order value
SELECT COUNT(*) AS excessive_refunds
FROM (
    SELECT
        o.order_id,
        o.order_value,
        SUM(r.refund_amount) AS total_refund
    FROM orders o
    JOIN refunds r
        ON o.order_id = r.order_id
    GROUP BY o.order_id, o.order_value
    HAVING SUM(r.refund_amount) > o.order_value
) x;

SELECT
    o.order_id,
    o.order_status,
    o.order_value,
    SUM(r.refund_amount) AS total_refund,
    ROUND(SUM(r.refund_amount) - o.order_value, 2) AS excess_amount
FROM orders o
JOIN refunds r
    ON o.order_id = r.order_id
GROUP BY
    o.order_id,
    o.order_status,
    o.order_value
HAVING SUM(r.refund_amount) > o.order_value
ORDER BY excess_amount DESC
LIMIT 10;

SELECT
    o.order_id,
    o.order_value,
    COUNT(r.refund_id) AS refund_records,
    ROUND(SUM(r.refund_amount), 2) AS total_refund,
    ROUND(MAX(r.refund_amount), 2) AS largest_single_refund
FROM orders o
JOIN refunds r
    ON o.order_id = r.order_id
WHERE o.order_id IN (
    122772, 110382, 77513, 56973, 128693,
    84653, 120785, 111777, 83209, 68565
)
GROUP BY o.order_id, o.order_value;

SELECT
    MIN(order_value) AS min_order_value,
    MAX(order_value) AS max_order_value,
    ROUND(AVG(order_value), 2) AS avg_order_value,
    ROUND(STDDEV(order_value), 2) AS std_order_value
FROM orders;

SELECT order_id, order_value, order_status
FROM orders
ORDER BY order_value DESC
LIMIT 10;

SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity,
    ROUND(AVG(quantity), 2) AS avg_quantity,
    STDDEV(quantity) AS std_quantity
FROM order_items;

SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price
FROM order_items
ORDER BY quantity DESC
LIMIT 10;

SELECT
    MIN(refund_amount) AS min_refund,
    MAX(refund_amount) AS max_refund,
    ROUND(AVG(refund_amount), 2) AS avg_refund,
    STDDEV(refund_amount) AS std_refund
FROM refunds;

# Final data-quality check: Product prices and costs

SELECT
    COUNT(*) AS invalid_products
FROM products
WHERE list_price <= 0
   OR unit_cost < 0
   OR unit_cost > list_price;

SELECT
    COUNT(*) AS invalid_order_items
FROM order_items
WHERE unit_price <= 0
   OR unit_cost < 0
   OR quantity <= 0;

# SQL Business Analysis
# Business Logic- We are using delivered orders for revenue and AOV, rather than treating cancelled and returned orders as successful sales.
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(
        CASE
            WHEN order_status = 'Delivered'
            THEN order_value
            ELSE 0
        END
    ), 2) AS delivered_revenue,
    ROUND(AVG(
        CASE
            WHEN order_status = 'Delivered'
            THEN order_value
        END
    ), 2) AS average_order_value
FROM orders;

# Order-status analysis: number and percentage of orders in each status.
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders),
        2
    ) AS order_percentage,
    ROUND(SUM(order_value), 2) AS total_order_value
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

# Customer purchasing behaviour: calculate how many customers are repeat purchasers.
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    ) AS repeat_customer_percentage
FROM (
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
) customer_orders;

# Purchase frequency
SELECT
    CASE
        WHEN order_count = 1 THEN '1 Order'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 Orders'
        WHEN order_count BETWEEN 4 AND 5 THEN '4-5 Orders'
        ELSE 'More than 5 Orders'
    END AS purchase_frequency,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id)
         FROM orders
         WHERE order_status = 'Delivered'),
        2
    ) AS customer_percentage
FROM (
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
) x
GROUP BY purchase_frequency
ORDER BY MIN(order_count);

# Product and category performance
SELECT
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS product_revenue,
    ROUND(SUM(oi.quantity * oi.unit_cost), 2) AS product_cost,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost)), 2
    ) AS gross_profit
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY product_revenue DESC;

# Gross profit margin by category 
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
    ROUND(SUM(oi.quantity * oi.unit_cost), 2) AS cost,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost))
        / SUM(oi.quantity * oi.unit_price) * 100,
        2
    ) AS gross_profit_margin
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category
ORDER BY gross_profit_margin DESC;

# Top 10 products by revenue
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost)), 2
    ) AS gross_profit
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered'
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY revenue DESC
LIMIT 10;

# Calculate top products' revenue contribution
WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY p.product_id, p.product_name
),
ranked_products AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY revenue DESC) AS product_rank
    FROM product_revenue
)
SELECT
    ROUND(SUM(CASE WHEN product_rank <= 10 THEN revenue ELSE 0 END), 2)
        AS top_10_revenue,
    ROUND(SUM(revenue), 2) AS total_product_revenue,
    ROUND(
        SUM(CASE WHEN product_rank <= 10 THEN revenue ELSE 0 END)
        / SUM(revenue) * 100, 2
    ) AS top_10_revenue_contribution_percentage
FROM ranked_products;

# Marketing analytics

# Marketing spend by channel
SELECT
    channel,
    COUNT(*) AS campaign_records,
    ROUND(SUM(spend), 2) AS total_marketing_spend,
    ROUND(AVG(spend), 2) AS average_spend_per_record
FROM marketing_spend
GROUP BY channel
ORDER BY total_marketing_spend DESC;

# Customers acquired by channel
SELECT
    acquisition_channel,
    COUNT(*) AS total_customers
FROM customers
GROUP BY acquisition_channel
ORDER BY total_customers DESC;

# Calculate preliminary CAC
SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS acquired_customers,
    ROUND(SUM(ms.spend), 2) AS total_marketing_spend,
    ROUND(
        SUM(ms.spend) / COUNT(DISTINCT c.customer_id), 2
    ) AS preliminary_cac
FROM customers c
JOIN marketing_spend ms
    ON c.acquisition_channel = ms.channel
GROUP BY c.acquisition_channel
ORDER BY preliminary_cac;

SELECT
    channel,
    ROUND(SUM(spend), 2) AS total_spend
FROM marketing_spend
GROUP BY channel;

SELECT
    acquisition_channel,
    COUNT(*) AS acquired_customers
FROM customers
GROUP BY acquisition_channel;

WITH spend_by_channel AS (
    SELECT
        channel,
        SUM(spend) AS total_spend
    FROM marketing_spend
    GROUP BY channel
),
customers_by_channel AS (
    SELECT
        acquisition_channel,
        COUNT(*) AS acquired_customers
    FROM customers
    GROUP BY acquisition_channel
)
SELECT
    c.acquisition_channel,
    c.acquired_customers,
    ROUND(s.total_spend, 2) AS total_marketing_spend,
    ROUND(s.total_spend / c.acquired_customers, 2) AS preliminary_cac
FROM customers_by_channel c
JOIN spend_by_channel s
    ON c.acquisition_channel = s.channel
ORDER BY preliminary_cac;

# Customer Lifetime Value (CLV)
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    ROUND(SUM(order_value), 2) AS total_revenue,
    ROUND(AVG(order_value), 2) AS average_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
LIMIT 10;

# Calculate average customer revenue
SELECT
    COUNT(*) AS total_customers,
    ROUND(AVG(customer_revenue), 2) AS average_customer_revenue,
    ROUND(AVG(total_orders), 2) AS average_orders_per_customer
FROM (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(order_value) AS customer_revenue
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
) AS customer_summary;

# Calculate average purchase frequency
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        DATEDIFF(MAX(order_date), MIN(order_date)) AS customer_lifespan_days
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT
    ROUND(AVG(total_orders), 2) AS avg_purchase_frequency,
    ROUND(AVG(customer_lifespan_days), 2) AS avg_customer_lifespan_days
FROM customer_orders;

# Calculate average time between purchases
WITH customer_order_dates AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS previous_order_date
    FROM orders
    WHERE order_status = 'Delivered'
),
purchase_gaps AS (
    SELECT
        customer_id,
        DATEDIFF(order_date, previous_order_date) AS days_between_orders
    FROM customer_order_dates
    WHERE previous_order_date IS NOT NULL
)
SELECT
    ROUND(AVG(days_between_orders), 2) AS avg_days_between_purchases,
    MIN(days_between_orders) AS minimum_gap_days,
    MAX(days_between_orders) AS maximum_gap_days
FROM purchase_gaps;

# Estimate historical customer value using gross profit
SELECT
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_product_revenue,
    ROUND(SUM(oi.quantity * oi.unit_cost), 2) AS total_product_cost,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost)), 2
    ) AS total_gross_profit,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost))
        / SUM(oi.quantity * oi.unit_price) * 100, 2
    ) AS gross_profit_margin_percentage
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered';

# Calculate average gross profit per customer
SELECT
    COUNT(DISTINCT o.customer_id) AS total_customers,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost))
        / COUNT(DISTINCT o.customer_id), 2
    ) AS average_gross_profit_per_customer
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'Delivered';

# Calculate gross profit by acquisition channel
SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost)), 2
    ) AS total_gross_profit,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost))
        / COUNT(DISTINCT c.customer_id), 2
    ) AS gross_profit_per_customer
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY c.acquisition_channel
ORDER BY gross_profit_per_customer DESC;

# Compare CAC with gross profit per customer
WITH spend_by_channel AS (
    SELECT
        channel,
        SUM(spend) AS total_spend
    FROM marketing_spend
    GROUP BY channel
),
customer_profit AS (
    SELECT
        c.acquisition_channel,
        COUNT(DISTINCT c.customer_id) AS total_customers,
        SUM(oi.quantity * (oi.unit_price - oi.unit_cost)) AS total_gross_profit
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Delivered'
    GROUP BY c.acquisition_channel
)
SELECT
    cp.acquisition_channel,
    ROUND(sb.total_spend / cp.total_customers, 2) AS preliminary_cac,
    ROUND(cp.total_gross_profit / cp.total_customers, 2) AS gross_profit_per_customer,
    ROUND(
        (cp.total_gross_profit / cp.total_customers)
        / (sb.total_spend / cp.total_customers), 2
    ) AS gross_profit_to_cac_ratio
FROM customer_profit cp
JOIN spend_by_channel sb
    ON cp.acquisition_channel = sb.channel
ORDER BY gross_profit_to_cac_ratio DESC;

# Customer retention analysis
WITH monthly_customer_orders AS (
    SELECT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        COUNT(*) AS total_orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    order_month,
    COUNT(DISTINCT customer_id) AS active_customers,
    COUNT(DISTINCT CASE
        WHEN total_orders > 1 THEN customer_id
    END) AS repeat_customers,
    ROUND(
        COUNT(DISTINCT CASE
            WHEN total_orders > 1 THEN customer_id
        END) * 100.0 /
        COUNT(DISTINCT customer_id), 2
    ) AS monthly_repeat_customer_percentage
FROM monthly_customer_orders
GROUP BY order_month
ORDER BY order_month;

# Check monthly data coverage
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    MIN(DATE(order_date)) AS first_order_date,
    MAX(DATE(order_date)) AS last_order_date,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'Delivered'
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

# Monthly cohort retention analysis
 
# Identify each customer's first purchase month
SELECT
    customer_id,
    MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
LIMIT 20;

# Calculate customer activity by month
SELECT
    customer_id,
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'Delivered'
GROUP BY
    customer_id,
    DATE_FORMAT(order_date, '%Y-%m')
ORDER BY customer_id, order_month
LIMIT 20;

# Calculate cohort month number
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS activity_month
    FROM orders
    WHERE order_status = 'Delivered'
)
SELECT
    f.customer_id,
    f.cohort_month,
    a.activity_month,
    PERIOD_DIFF(
        REPLACE(a.activity_month, '-', ''),
        REPLACE(f.cohort_month, '-', '')
    ) AS cohort_index
FROM first_purchase f
JOIN monthly_activity a
    ON f.customer_id = a.customer_id
ORDER BY f.customer_id, a.activity_month
LIMIT 30;

# Build the cohort retention table
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS activity_month
    FROM orders
    WHERE order_status = 'Delivered'
),
cohort_activity AS (
    SELECT
        f.customer_id,
        f.cohort_month,
        PERIOD_DIFF(
            REPLACE(a.activity_month, '-', ''),
            REPLACE(f.cohort_month, '-', '')
        ) AS cohort_index
    FROM first_purchase f
    JOIN monthly_activity a
        ON f.customer_id = a.customer_id
)
SELECT
    cohort_month,
    cohort_index,
    COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_activity
GROUP BY cohort_month, cohort_index
ORDER BY cohort_month, cohort_index;

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS activity_month
    FROM orders
    WHERE order_status = 'Delivered'
),
cohort_activity AS (
    SELECT
        f.customer_id,
        f.cohort_month,
        PERIOD_DIFF(
            REPLACE(a.activity_month, '-', ''),
            REPLACE(f.cohort_month, '-', '')
        ) AS cohort_index
    FROM first_purchase f
    JOIN monthly_activity a
        ON f.customer_id = a.customer_id
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    cs.cohort_size,
    ca.cohort_index,
    COUNT(DISTINCT ca.customer_id) AS active_customers,
    ROUND(
        COUNT(DISTINCT ca.customer_id) * 100.0 / cs.cohort_size,
        2
    ) AS retention_percentage
FROM cohort_activity ca
JOIN cohort_sizes cs
    ON ca.cohort_month = cs.cohort_month
GROUP BY
    ca.cohort_month,
    cs.cohort_size,
    ca.cohort_index
ORDER BY ca.cohort_month, ca.cohort_index;

# Create the final retention matrix
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS activity_month
    FROM orders
    WHERE order_status = 'Delivered'
),
cohort_activity AS (
    SELECT
        f.customer_id,
        f.cohort_month,
        PERIOD_DIFF(
            REPLACE(a.activity_month, '-', ''),
            REPLACE(f.cohort_month, '-', '')
        ) AS cohort_index
    FROM first_purchase f
    JOIN monthly_activity a
        ON f.customer_id = a.customer_id
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
),
retention AS (
    SELECT
        ca.cohort_month,
        ca.cohort_index,
        ROUND(
            COUNT(DISTINCT ca.customer_id) * 100.0 /
            cs.cohort_size, 2
        ) AS retention_percentage
    FROM cohort_activity ca
    JOIN cohort_sizes cs
        ON ca.cohort_month = cs.cohort_month
    GROUP BY
        ca.cohort_month,
        ca.cohort_index,
        cs.cohort_size
)
SELECT
    cohort_month,
    MAX(CASE WHEN cohort_index = 0 THEN retention_percentage END) AS month_0,
    MAX(CASE WHEN cohort_index = 1 THEN retention_percentage END) AS month_1,
    MAX(CASE WHEN cohort_index = 2 THEN retention_percentage END) AS month_2,
    MAX(CASE WHEN cohort_index = 3 THEN retention_percentage END) AS month_3,
    MAX(CASE WHEN cohort_index = 4 THEN retention_percentage END) AS month_4,
    MAX(CASE WHEN cohort_index = 5 THEN retention_percentage END) AS month_5,
    MAX(CASE WHEN cohort_index = 6 THEN retention_percentage END) AS month_6,
    MAX(CASE WHEN cohort_index = 7 THEN retention_percentage END) AS month_7,
    MAX(CASE WHEN cohort_index = 8 THEN retention_percentage END) AS month_8,
    MAX(CASE WHEN cohort_index = 9 THEN retention_percentage END) AS month_9,
    MAX(CASE WHEN cohort_index = 10 THEN retention_percentage END) AS month_10,
    MAX(CASE WHEN cohort_index = 11 THEN retention_percentage END) AS month_11,
    MAX(CASE WHEN cohort_index = 12 THEN retention_percentage END) AS month_12,
    MAX(CASE WHEN cohort_index = 13 THEN retention_percentage END) AS month_13,
    MAX(CASE WHEN cohort_index = 14 THEN retention_percentage END) AS month_14,
    MAX(CASE WHEN cohort_index = 15 THEN retention_percentage END) AS month_15,
    MAX(CASE WHEN cohort_index = 16 THEN retention_percentage END) AS month_16,
    MAX(CASE WHEN cohort_index = 17 THEN retention_percentage END) AS month_17,
    MAX(CASE WHEN cohort_index = 18 THEN retention_percentage END) AS month_18,
    MAX(CASE WHEN cohort_index = 19 THEN retention_percentage END) AS month_19,
    MAX(CASE WHEN cohort_index = 20 THEN retention_percentage END) AS month_20,
    MAX(CASE WHEN cohort_index = 21 THEN retention_percentage END) AS month_21
FROM retention
GROUP BY cohort_month
ORDER BY cohort_month;

# Calculate average retention by cohort age
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS activity_month
    FROM orders
    WHERE order_status = 'Delivered'
),
cohort_activity AS (
    SELECT
        f.customer_id,
        f.cohort_month,
        PERIOD_DIFF(
            REPLACE(a.activity_month, '-', ''),
            REPLACE(f.cohort_month, '-', '')
        ) AS cohort_index
    FROM first_purchase f
    JOIN monthly_activity a
        ON f.customer_id = a.customer_id
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
),
retention AS (
    SELECT
        ca.cohort_month,
        ca.cohort_index,
        COUNT(DISTINCT ca.customer_id) * 100.0 /
        cs.cohort_size AS retention_percentage
    FROM cohort_activity ca
    JOIN cohort_sizes cs
        ON ca.cohort_month = cs.cohort_month
    GROUP BY
        ca.cohort_month,
        ca.cohort_index,
        cs.cohort_size
)
SELECT
    cohort_index,
    COUNT(*) AS number_of_cohorts,
    ROUND(AVG(retention_percentage), 2) AS average_retention_percentage
FROM retention
GROUP BY cohort_index
ORDER BY cohort_index;

# Calculate weighted cohort retention
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS activity_month
    FROM orders
    WHERE order_status = 'Delivered'
),
cohort_activity AS (
    SELECT
        f.customer_id,
        f.cohort_month,
        PERIOD_DIFF(
            REPLACE(a.activity_month, '-', ''),
            REPLACE(f.cohort_month, '-', '')
        ) AS cohort_index
    FROM first_purchase f
    JOIN monthly_activity a
        ON f.customer_id = a.customer_id
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
),
retention AS (
    SELECT
        ca.cohort_month,
        ca.cohort_index,
        cs.cohort_size,
        COUNT(DISTINCT ca.customer_id) AS active_customers,
        COUNT(DISTINCT ca.customer_id) * 100.0
            / cs.cohort_size AS retention_percentage
    FROM cohort_activity ca
    JOIN cohort_sizes cs
        ON ca.cohort_month = cs.cohort_month
    GROUP BY
        ca.cohort_month,
        ca.cohort_index,
        cs.cohort_size
)
SELECT
    cohort_index,
    COUNT(*) AS number_of_cohorts,
    SUM(active_customers) AS active_customers,
    SUM(cohort_size) AS cohort_customers,
    ROUND(
        SUM(active_customers) * 100.0 / SUM(cohort_size), 2
    ) AS weighted_retention_percentage
FROM retention
GROUP BY cohort_index
ORDER BY cohort_index;

# Purchase funnel
# Visit → Product View → Add to Cart → Checkout → Purchase.

# Count unique customers at each funnel stage
SELECT
    event_name,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) AS total_events
FROM events
GROUP BY event_name
ORDER BY
    CASE event_name
        WHEN 'visit' THEN 1
        WHEN 'product view' THEN 2
        WHEN 'add to cart' THEN 3
        WHEN 'checkout' THEN 4
        WHEN 'purchase' THEN 5
    END;

# Validate the funnel sequence
WITH session_events AS (
    SELECT
        session_id,
        customer_id,
        MIN(CASE WHEN event_name = 'visit'
            THEN event_time END) AS visit_time,
        MIN(CASE WHEN event_name = 'product_view'
            THEN event_time END) AS product_view_time,
        MIN(CASE WHEN event_name = 'add_to_cart'
            THEN event_time END) AS cart_time,
        MIN(CASE WHEN event_name = 'checkout'
            THEN event_time END) AS checkout_time,
        MIN(CASE WHEN event_name = 'purchase'
            THEN event_time END) AS purchase_time
    FROM events
    GROUP BY session_id, customer_id
)
SELECT
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN product_view_time IS NOT NULL THEN 1 ELSE 0 END)
        AS sessions_with_product_view,
    SUM(CASE WHEN cart_time IS NOT NULL THEN 1 ELSE 0 END)
        AS sessions_with_cart,
    SUM(CASE WHEN checkout_time IS NOT NULL THEN 1 ELSE 0 END)
        AS sessions_with_checkout,
    SUM(CASE WHEN purchase_time IS NOT NULL THEN 1 ELSE 0 END)
        AS sessions_with_purchase,
    SUM(CASE WHEN visit_time < product_view_time
        AND product_view_time < cart_time
        AND cart_time < checkout_time
        AND checkout_time < purchase_time
        THEN 1 ELSE 0 END) AS complete_ordered_funnel_sessions
FROM session_events;

# Check event-name values
SELECT
    event_name,
    LENGTH(event_name) AS name_length,
    COUNT(*) AS total_events
FROM events
GROUP BY event_name
ORDER BY total_events DESC;

# To calculate strictly sequential conversion rates, let's count sessions that reached each stage after completing all previous stages.
WITH session_events AS (
    SELECT
        session_id,
        customer_id,
        MIN(CASE WHEN event_name = 'visit'
            THEN event_time END) AS visit_time,
        MIN(CASE WHEN event_name = 'product_view'
            THEN event_time END) AS product_view_time,
        MIN(CASE WHEN event_name = 'add_to_cart'
            THEN event_time END) AS cart_time,
        MIN(CASE WHEN event_name = 'checkout'
            THEN event_time END) AS checkout_time,
        MIN(CASE WHEN event_name = 'purchase'
            THEN event_time END) AS purchase_time
    FROM events
    GROUP BY session_id, customer_id
),
funnel AS (
    SELECT
        COUNT(*) AS visits,
        SUM(CASE WHEN visit_time < product_view_time
            THEN 1 ELSE 0 END) AS product_views,
        SUM(CASE WHEN visit_time < product_view_time
            AND product_view_time < cart_time
            THEN 1 ELSE 0 END) AS carts,
        SUM(CASE WHEN visit_time < product_view_time
            AND product_view_time < cart_time
            AND cart_time < checkout_time
            THEN 1 ELSE 0 END) AS checkouts,
        SUM(CASE WHEN visit_time < product_view_time
            AND product_view_time < cart_time
            AND cart_time < checkout_time
            AND checkout_time < purchase_time
            THEN 1 ELSE 0 END) AS purchases
    FROM session_events
)
SELECT * FROM funnel;

# RFM Customer Segmentation.
# Calculate customer-level RFM metrics
SELECT
    customer_id,
    DATEDIFF(
        (SELECT MAX(order_date)
         FROM orders
         WHERE order_status = 'Delivered'),
        MAX(order_date)
    ) AS recency,
    COUNT(order_id) AS frequency,
    ROUND(SUM(order_value), 2) AS monetary
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
LIMIT 20;

# Calculate RFM scores
WITH rfm AS (
    SELECT
        customer_id,
        DATEDIFF(
            (SELECT MAX(order_date)
             FROM orders
             WHERE order_status = 'Delivered'),
            MAX(order_date)
        ) AS recency,
        COUNT(order_id) AS frequency,
        ROUND(SUM(order_value), 2) AS monetary
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        *,
        6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm
)
SELECT *
FROM rfm_scores
LIMIT 20;

# Create RFM customer segments
WITH rfm AS (
    SELECT
        customer_id,
        DATEDIFF(
            (SELECT MAX(order_date)
             FROM orders
             WHERE order_status = 'Delivered'),
            MAX(order_date)
        ) AS recency,
        COUNT(order_id) AS frequency,
        ROUND(SUM(order_value), 2) AS monetary
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        *,
        6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm
)
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_segment
FROM rfm_scores
LIMIT 20;

# RFM score distribution
WITH rfm AS (
    SELECT
        customer_id,
        DATEDIFF(
            (SELECT MAX(order_date)
             FROM orders
             WHERE order_status = 'Delivered'),
            MAX(order_date)
        ) AS recency,
        COUNT(order_id) AS frequency,
        SUM(order_value) AS monetary
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm
)
SELECT
    CONCAT(r_score, f_score, m_score) AS rfm_segment,
    COUNT(*) AS total_customers
FROM rfm_scores
GROUP BY rfm_segment
ORDER BY total_customers DESC;

# Create business customer segments
WITH rfm AS (
    SELECT
        customer_id,
        DATEDIFF(
            (SELECT MAX(order_date)
             FROM orders
             WHERE order_status = 'Delivered'),
            MAX(order_date)
        ) AS recency,
        COUNT(order_id) AS frequency,
        SUM(order_value) AS monetary
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm
),
customer_segments AS (
    SELECT
        customer_id,
        r_score,
        f_score,
        m_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN f_score >= 4 AND m_score >= 3
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'
            WHEN r_score >= 4 AND f_score = 1
                THEN 'Recent Customers'
            WHEN r_score <= 2 AND f_score >= 3
                THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2
                THEN 'Hibernating'
            ELSE 'Others'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_customers DESC;

# SQL Query Optimization & Indexing
# Identify a query that needs optimization
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE YEAR(order_date) = 2026
AND order_status = 'Delivered';

# Rewrite
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_date >= '2026-01-01'
  AND order_date < '2027-01-01'
  AND order_status = 'Delivered';
  
# Create a composite index
CREATE INDEX idx_orders_date_status
ON orders(order_date, order_status);  

SHOW INDEX FROM orders;

EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_date >= '2026-01-01'
  AND order_date < '2027-01-01'
  AND order_status = 'Delivered';

# Test an index-friendly query
EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE order_date >= '2026-01-01'
  AND order_date < '2026-02-01'
  AND order_status = 'Delivered';

# One controlled comparison
EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders IGNORE INDEX (idx_orders_date_status)
WHERE order_date >= '2026-01-01'
  AND order_date < '2026-02-01'
  AND order_status = 'Delivered';
  
# Composite index column order  
# Test the leftmost-prefix rule
EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_status
FROM orders
WHERE order_status = 'Delivered';

# leftmost-prefix rule
EXPLAIN ANALYZE
SELECT
    order_id,
    order_date
FROM orders
WHERE order_date >= '2026-01-01'
  AND order_date < '2026-02-01';
  
# Understand column order in composite indexes
SELECT order_id, order_date, order_status
FROM orders
WHERE order_status = 'Delivered'
AND order_date >= '2026-01-01'
AND order_date < '2026-02-01';

EXPLAIN ANALYZE
SELECT order_id, order_date, order_status
FROM orders
WHERE order_status = 'Delivered'
AND order_date >= '2026-01-01'
AND order_date < '2026-02-01';

# Compare reversed column order
CREATE INDEX idx_orders_status_date
ON orders(order_status, order_date);

EXPLAIN ANALYZE
SELECT order_id, order_date, order_status
FROM orders
WHERE order_status = 'Delivered'
AND order_date >= '2026-01-01'
AND order_date < '2026-02-01';

# Test the reversed index alone
EXPLAIN ANALYZE
SELECT order_id, order_status, order_date
FROM orders
WHERE order_status = 'Delivered';

# Force a table scan for comparison
EXPLAIN ANALYZE
SELECT order_id, order_status, order_date
FROM orders IGNORE INDEX (idx_orders_status_date)
WHERE order_status = 'Delivered';

SHOW INDEX FROM orders;

# Customer-level filtering
EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE customer_id = 1000;

SELECT
    c.customer_id,
    c.acquisition_channel,
    COUNT(o.order_id) AS total_orders,
    SUM(o.order_value) AS total_revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.acquisition_channel;

# Indexing joins
EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.order_value,
    oi.product_id,
    oi.quantity
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_id = 1000;

# Test a join without an index
EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.order_value,
    oi.product_id,
    oi.quantity
FROM orders o
JOIN order_items oi
    IGNORE INDEX (fk_items_orders)
    ON o.order_id = oi.order_id
WHERE o.order_id = 1000;

# Indexing order_items for product analysis
EXPLAIN ANALYZE
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price
FROM order_items
WHERE product_id = 100;

# A combined filter
EXPLAIN ANALYZE
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price
FROM order_items
WHERE product_id = 100
AND quantity >= 2;

CREATE INDEX idx_items_product_quantity
ON order_items(product_id, quantity);

EXPLAIN ANALYZE
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price
FROM order_items
WHERE product_id = 100
AND quantity >= 2;

# Covering composite indexes
EXPLAIN ANALYZE
SELECT
    order_item_id,
    product_id,
    quantity
FROM order_items
WHERE product_id = 100
AND quantity >= 2;

# Indexing for GROUP BY and ORDER BY
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
GROUP BY customer_id
ORDER BY total_revenue DESC;

# Create a covering index for aggregation
CREATE INDEX idx_orders_customer_value
ON orders(customer_id, order_value);

EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
GROUP BY customer_id
ORDER BY total_revenue DESC;

# GROUP BY without ORDER BY
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
GROUP BY customer_id;

# ORDER BY an indexed column
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
GROUP BY customer_id
ORDER BY customer_id;

# LIMIT optimization
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

# Compare LIMIT without an INDEX
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders IGNORE INDEX (idx_orders_customer_value)
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

# Filtering + grouping + sorting
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
AND order_date >= '2026-01-01'
AND order_date < '2026-02-01'
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

# Create a workload-specific composite index
CREATE INDEX idx_orders_status_date_customer_value
ON orders(order_status, order_date, customer_id, order_value);

EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
AND order_date >= '2026-01-01'
AND order_date < '2026-02-01'
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

# Test the index's leftmost-prefix behaviour
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

# Test the wider composite index
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

# Create an index specifically for this workload
CREATE INDEX idx_orders_status_customer_value
ON orders(order_status, customer_id, order_value);

EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;

# Test whether the index also helps without aggregation
EXPLAIN ANALYZE
SELECT
    customer_id,
    order_value
FROM orders
WHERE order_status = 'Delivered'
ORDER BY customer_id;

# Index selectivity
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_status = 'Delivered';

EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_status = 'Delivered';

# Force a table scan for comparison
EXPLAIN ANALYZE
SELECT *
FROM orders IGNORE INDEX (
    idx_orders_status_date,
    idx_orders_date_status,
    idx_orders_status_date_customer_value,
    idx_orders_status_customer_value
)
WHERE order_status = 'Delivered';

# High-selectivity versus low-selectivity filtering
# Rare status condition
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_status = 'Returned';

# Common status condition
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_status = 'Delivered';

# Composite index column order
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE order_status = 'Returned'
AND customer_id = 1000;

# Test the leftmost-prefix rule
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 1000;

# Let's isolate the leftmost-prefix rule by excluding the other indexes that start with customer_id.
EXPLAIN ANALYZE
SELECT *
FROM orders IGNORE INDEX (
    fk_orders_customers,
    idx_orders_customer_value
)
WHERE customer_id = 1000;

EXPLAIN ANALYZE
SELECT *
FROM orders IGNORE INDEX (idx_orders_customer_value)
WHERE customer_id = 1000;

EXPLAIN ANALYZE
SELECT *
FROM orders IGNORE INDEX (
    idx_orders_customer_value
)
WHERE customer_id = 1000;

# Test a three-column composite index
EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE order_status = 'Delivered'
AND customer_id = 1000
AND order_date >= '2026-01-01'
AND order_date < '2027-01-01';

# Create a targeted composite index
CREATE INDEX idx_orders_status_customer_date
ON orders(order_status, customer_id, order_date);

EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE order_status = 'Delivered'
AND customer_id = 1000
AND order_date >= '2026-01-01'
AND order_date < '2027-01-01';

# Reverse the index order
CREATE INDEX idx_orders_date_customer_status
ON orders(order_date, customer_id, order_status);

EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders
WHERE order_status = 'Delivered'
AND customer_id = 1000
AND order_date >= '2026-01-01'
AND order_date < '2027-01-01';

SHOW INDEX FROM orders;

EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders FORCE INDEX (idx_orders_date_customer_status)
WHERE order_status = 'Delivered'
AND customer_id = 1000
AND order_date >= '2026-01-01'
AND order_date < '2027-01-01';

# Test with a customer who has matching orders
SELECT customer_id
FROM orders
WHERE order_status = 'Delivered'
LIMIT 1;

# Check this customer's delivered orders
SELECT
    order_id,
    customer_id,
    order_date,
    order_status,
    order_value
FROM orders
WHERE customer_id = 19114
AND order_status = 'Delivered'
ORDER BY order_date;

# Test equality-first index
EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders FORCE INDEX (idx_orders_status_customer_date)
WHERE order_status = 'Delivered'
AND customer_id = 19114
AND order_date >= '2025-01-01'
AND order_date < '2025-02-01';

# Now test the reversed index
EXPLAIN ANALYZE
SELECT
    order_id,
    customer_id,
    order_date,
    order_value
FROM orders FORCE INDEX (idx_orders_date_customer_status)
WHERE order_status = 'Delivered'
AND customer_id = 19114
AND order_date >= '2025-01-01'
AND order_date < '2025-02-01';

# Index maintenance and optimization
SHOW INDEX from orders;

# Inspect index sizes
SELECT
    TABLE_NAME,
    INDEX_NAME,
    COUNT(*) AS index_columns
FROM information_schema.statistics
WHERE TABLE_SCHEMA = 'ecommerce_analytics'
AND TABLE_NAME = 'orders'
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY INDEX_NAME;

SHOW TABLE STATUS
FROM ecommerce_analytics
LIKE 'orders';

# Inspect actual index usage
SELECT
    OBJECT_NAME,
    INDEX_NAME,
    COUNT_READ,
    COUNT_WRITE
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_SCHEMA = 'ecommerce_analytics'
AND OBJECT_NAME = 'orders'
ORDER BY COUNT_READ DESC;

# Inspect index sizes individually
SELECT
    database_name,
    table_name,
    index_name,
    stat_value AS size_in_bytes
FROM mysql.innodb_index_stats
WHERE database_name = 'ecommerce_analytics'
AND table_name = 'orders'
AND stat_name = 'size'
ORDER BY stat_value DESC;

# Inspect index definitions and cardinality
SHOW INDEX from orders;

# Index selection in a business scenario
SELECT
    customer_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS total_revenue
FROM orders
WHERE order_status = 'Delivered'
AND customer_id = 19114
AND order_date >= '2025-01-01'
AND order_date < '2025-02-01'
GROUP BY customer_id;

# JOIN optimization
EXPLAIN ANALYZE
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category;

CREATE INDEX idx_items_order_product_qty_price
ON order_items(order_id, product_id, quantity, unit_price);

EXPLAIN ANALYZE
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category;

# Controlled comparison
EXPLAIN ANALYZE
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi IGNORE INDEX (idx_items_order_product_qty_price)
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category;

# Force the join order
EXPLAIN ANALYZE
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
STRAIGHT_JOIN order_items oi
    ON o.order_id = oi.order_id
STRAIGHT_JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'Delivered'
GROUP BY p.category;

# Test the impact of filtering before joining
EXPLAIN ANALYZE
WITH delivered_orders AS (
    SELECT order_id
    FROM orders
    WHERE order_status = 'Delivered'
)
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM delivered_orders d
JOIN order_items oi
    ON d.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category;

# Subquery optimization
# Business Problem: Find the total number of delivered orders for every customer.
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    (
        SELECT COUNT(*)
        FROM orders o
        WHERE o.customer_id = c.customer_id
        AND o.order_status = 'Delivered'
    ) AS delivered_orders
FROM customers c;

# Optimize using JOIN and GROUP BY
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    COUNT(o.order_id) AS delivered_orders
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.order_status = 'Delivered'
GROUP BY c.customer_id;

# Third approach: pre-aggregation
EXPLAIN ANALYZE
SELECT
    c.customer_id,
    COALESCE(o.delivered_orders, 0) AS delivered_orders
FROM customers c
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(*) AS delivered_orders
    FROM orders
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
) o
    ON c.customer_id = o.customer_id;

# Temporary tables
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id
HAVING COUNT(*) >= 3;

# Let's compare it against a query that explicitly selects only the required data through a derived table.
EXPLAIN ANALYZE
SELECT
    customer_id,
    COUNT(*) AS delivered_orders
FROM (
    SELECT customer_id
    FROM orders
    WHERE order_status = 'Delivered'
) AS delivered
GROUP BY customer_id
HAVING COUNT(*) >= 3;

# UNION vs UNION ALL
EXPLAIN ANALYZE
SELECT customer_id
FROM orders
WHERE order_status = 'Delivered'

UNION

SELECT customer_id
FROM orders
WHERE order_status = 'Returned';

# UNION ALL
EXPLAIN ANALYZE
SELECT customer_id
FROM orders
WHERE order_status = 'Delivered'

UNION ALL

SELECT customer_id
FROM orders
WHERE order_status = 'Returned';

# SQL Automation
# Daily Business KPIs
CREATE OR REPLACE VIEW vw_business_kpis AS 
SELECT COUNT(*) AS total_orders,
COUNT(DISTINCT customer_id) AS unique_customers,
SUM(CASE WHEN order_status = 'Delivered' THEN order_value ELSE 0 END) AS delivered_revenue,
COUNT(CASE WHEN order_status = 'Delivered' THEN order_id END) AS delivered_orders,
ROUND(AVG(CASE WHEN order_status = 'Delivered' THEN order_value END), 2) AS average_order_value
FROM orders,

SELECT * FROM vw_business_kpis;

# Monthly Revenue View
CREATE OR REPLACE VIEW vw_monthly_revenue AS 
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
COUNT(*) AS total_orders,
COUNT(CASE WHEN order_status = 'Delivered' THEN order_id END) AS delivered_orders,
ROUND(SUM(CASE WHEN order_status = 'Delivered' THEN order_value ELSE 0 END), 2) AS delivered_revenue
FROM orders 
GROUP BY DATE_FORMAT(order_date, '%Y-%m')

SELECT * FROM vw_monthly_revenue ORDER BY order_month;

# Customer Performance View
CREATE OR REPLACE VIEW vw_customer_performance AS 
SELECT customer_id, 
COUNT(order_id) AS total_delivered_orders,
ROUND(SUM(order_value), 2) AS total_revenue,
ROUND(AVG(order_value), 2) AS average_order_value
FROM orders
WHERE order_status = 'Delivered'
GROUP BY customer_id

SELECT * FROM vw_customer_performance LIMIT 10;

# Data Quality Monitoring View
CREATE OR REPLACE VIEW vw_order_quality_issues AS 
SELECT 
     order_id, 
     customer_id,
     order_date,
     order_status,
     order_value,
     CASE 
         WHEN customer_id IS NULL THEN 'Missing Customer ID'
         WHEN order_value IS NULL THEN 'Missing Order Value'
         WHEN order_value <= 0 THEN 'Invalid Order Value'
         WHEN order_status IS NULL THEN 'Missing Order Status'
	 ELSE 'Other Issue'
END AS issue_type
FROM orders 
WHERE 
customer_id IS NULL
OR order_value IS NULL
OR order_value <= 0
OR order_status IS NULL

SELECT *
FROM vw_order_quality_issues;

# MySQL event scheduler
SHOW VARIABLES LIKE 'event_scheduler'

# Daily data quality monitoring event
CREATE TABLE IF NOT EXISTS data_quality_log (
log_id INT AUTO_INCREMENT PRIMARY KEY,
check_date DATETIME,
issue_count INT
); 

# Monitoring procedure
DELIMITER //
CREATE PROCEDURE LogDataQualityCheck()
BEGIN
INSERT INTO data_quality_log (check_date, issue_count)
SELECT 
    NOW(),
    COUNT(*) 
FROM vw_order_quality_issues;
END //

DELIMITER;

CALL LogDataQualityCheck():

SELECT * 
FROM data_quality_log;

# Create MySQL event
CREATE EVENT IF NOT EXIST daily_data_quality_check
ON SCHEDULE EVERY 1 DAY
STARTS (CURRENT_DATE + INTERVAL 1 DAY)
DO 
CALL LogDataQualityCheck();

SHOW EVENTS FROM ecommerce_analytics; 
























 

# Create a store procedure
# Customer performance for a specefic customer
DELIMITER //

CREATE PROCEDURE GetCustomerPerformance(
IN p_customer_id INT
)
BEGIN
SELECT * FROM vw_customer_performance 
WHERE customer_id = p.customer_id 
END //

DELIMITER;

CALL GetCustomerPerformance(105);

# Create a Monthly Revenue Stored Procedure
DELIMITER //
CREATE PROCEDURE GetMonthlyRevenue(
IN p_year INT
)
BEGIN
SELECT * 
FROM vw_monthly_revenue
WHERE order_month LIKE CONCAT(p_year, '-%')
ORDER BY order_month;
END //

DELIMITER;

CALL GetMonthlyRevenue(2026);





 






 












