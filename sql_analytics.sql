-- ============================================
-- SQL Analytics & Business Reporting
-- Analyst: Asolat Xolboyeva
-- Tools: PostgreSQL / MySQL
-- ============================================


-- ============================================
-- 1. BASIC AGGREGATION
-- ============================================

-- Total revenue by product category
SELECT 
    product_category,
    COUNT(*) AS total_orders,
    SUM(revenue) AS total_revenue,
    ROUND(AVG(revenue), 2) AS avg_revenue
FROM sales
GROUP BY product_category
ORDER BY total_revenue DESC;


-- Monthly revenue trend
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    SUM(revenue) AS monthly_revenue
FROM sales
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;


-- ============================================
-- 2. JOINS
-- ============================================

-- Customer orders with product details
SELECT 
    c.customer_name,
    c.region,
    o.order_date,
    p.product_name,
    p.category,
    o.quantity,
    o.revenue
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN products p ON o.product_id = p.product_id
ORDER BY o.order_date DESC;


-- Customers with no orders (LEFT JOIN)
SELECT 
    c.customer_id,
    c.customer_name,
    c.region
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


-- ============================================
-- 3. SUBQUERIES
-- ============================================

-- Products with above-average revenue
SELECT 
    product_name,
    category,
    revenue
FROM products
WHERE revenue > (
    SELECT AVG(revenue) FROM products
)
ORDER BY revenue DESC;


-- Top customer per region
SELECT 
    region,
    customer_name,
    total_revenue
FROM (
    SELECT 
        c.region,
        c.customer_name,
        SUM(o.revenue) AS total_revenue,
        RANK() OVER (PARTITION BY c.region ORDER BY SUM(o.revenue) DESC) AS rnk
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.region, c.customer_name
) ranked
WHERE rnk = 1;


-- ============================================
-- 4. WINDOW FUNCTIONS
-- ============================================

-- Month-over-month revenue growth
SELECT 
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month)) * 100.0 /
        LAG(monthly_revenue) OVER (ORDER BY month), 2
    ) AS growth_pct
FROM (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        SUM(revenue) AS monthly_revenue
    FROM sales
    GROUP BY DATE_TRUNC('month', order_date)
) monthly_data
ORDER BY month;


-- Customer ranking by revenue
SELECT 
    customer_name,
    region,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS overall_rank,
    RANK() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS region_rank
FROM (
    SELECT 
        c.customer_name,
        c.region,
        SUM(o.revenue) AS total_revenue
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_name, c.region
) customer_totals;


-- Running total revenue
SELECT 
    order_date,
    revenue,
    SUM(revenue) OVER (ORDER BY order_date) AS running_total
FROM sales
ORDER BY order_date;


-- ============================================
-- 5. CTEs (Common Table Expressions)
-- ============================================

-- Quarterly performance summary
WITH quarterly_revenue AS (
    SELECT 
        EXTRACT(QUARTER FROM order_date) AS quarter,
        EXTRACT(YEAR FROM order_date) AS year,
        SUM(revenue) AS total_revenue,
        COUNT(*) AS total_orders
    FROM sales
    GROUP BY EXTRACT(QUARTER FROM order_date), EXTRACT(YEAR FROM order_date)
),
quarterly_avg AS (
    SELECT AVG(total_revenue) AS avg_quarterly_revenue
    FROM quarterly_revenue
)
SELECT 
    q.year,
    q.quarter,
    q.total_revenue,
    q.total_orders,
    ROUND(q.total_revenue - qa.avg_quarterly_revenue, 2) AS vs_average
FROM quarterly_revenue q
CROSS JOIN quarterly_avg qa
ORDER BY q.year, q.quarter;


-- ============================================
-- 6. INDEX OPTIMIZATION
-- ============================================

-- Create indexes for better query performance
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_sales_product_category ON sales(product_category);

-- Check query performance (PostgreSQL)
EXPLAIN ANALYZE
SELECT 
    product_category,
    SUM(revenue) AS total_revenue
FROM sales
WHERE order_date >= '2023-01-01'
GROUP BY product_category
ORDER BY total_revenue DESC;
