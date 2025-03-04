USE mavenfuzzyfactory;

-- **********************************************************
-- DROP TEMPORARY TABLES IF THEY ALREADY EXIST
-- **********************************************************
DROP TEMPORARY TABLE IF EXISTS temp_cross_selling;
DROP TEMPORARY TABLE IF EXISTS temp_cross_selling2;

-- **********************************************************
-- CROSS-SELLING ANALYSIS - PRE CROSS-SELLING PERIOD
-- **********************************************************
CREATE TEMPORARY TABLE temp_cross_selling 
WITH CTE AS (
    SELECT 
        w.*, 
        LEAD(pageview_url) OVER (PARTITION BY w.website_session_id ORDER BY w.created_at) AS next_session,
        o.order_id, 
        o.items_purchased, 
        o.price_usd, 
        o.items_purchased / COUNT(o.order_id) OVER (PARTITION BY website_session_id) AS items_purchased_avg,
        o.price_usd / COUNT(o.order_id) OVER (PARTITION BY website_session_id) AS price_usd_avg
    FROM website_pageviews w
    LEFT JOIN orders o
        ON w.website_session_id = o.website_session_id
    WHERE w.created_at BETWEEN '2013-08-25' AND '2013-09-25'
)
SELECT 
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS cart_sessions,
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' AND next_session IS NOT NULL THEN website_session_id ELSE NULL END) AS cart_clickthrough,
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' AND next_session IS NOT NULL THEN website_session_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS cart_ctr,
    SUM(items_purchased_avg) / COUNT(DISTINCT order_id) AS products_per_order,
    SUM(price_usd_avg) / COUNT(DISTINCT order_id) AS aov,
    SUM(price_usd_avg) / COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS rev_per_cart_session
FROM CTE;

-- INSIGHTS:
-- - Cart clickthrough rate (CTR) before implementing cross-selling was **67.16%**.
-- - Customers purchased an average of **1.00 product per order** before cross-selling.
-- - The average order value (AOV) was **$51.42**.
-- - Revenue per cart session was **$18.31**.

-- **********************************************************
-- CROSS-SELLING ANALYSIS - POST CROSS-SELLING PERIOD
-- **********************************************************
CREATE TEMPORARY TABLE temp_cross_selling2 
WITH CTE AS (
    SELECT 
        w.*, 
        LEAD(pageview_url) OVER (PARTITION BY w.website_session_id ORDER BY w.created_at) AS next_session,
        o.order_id, 
        o.items_purchased, 
        o.price_usd, 
        o.items_purchased / COUNT(o.order_id) OVER (PARTITION BY website_session_id) AS items_purchased_avg,
        o.price_usd / COUNT(o.order_id) OVER (PARTITION BY website_session_id) AS price_usd_avg
    FROM website_pageviews w
    LEFT JOIN orders o
        ON w.website_session_id = o.website_session_id
    WHERE w.created_at BETWEEN '2013-09-25' AND '2013-10-25'
)
SELECT 
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS cart_sessions,
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' AND next_session IS NOT NULL THEN website_session_id ELSE NULL END) AS cart_clickthrough,
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' AND next_session IS NOT NULL THEN website_session_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS cart_ctr,
    SUM(items_purchased_avg) / COUNT(DISTINCT order_id) AS products_per_order,
    SUM(price_usd_avg) / COUNT(DISTINCT order_id) AS aov,
    SUM(price_usd_avg) / COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS rev_per_cart_session
FROM CTE;

-- INSIGHTS:
-- - Cart clickthrough rate (CTR) after implementing cross-selling **increased to 68.41%**.
-- - Customers purchased an average of **1.04 products per order**, showing a slight improvement.
-- - The average order value (AOV) increased to **$54.25** post cross-selling.
-- - Revenue per cart session also increased slightly to **$18.43**.

-- **********************************************************
-- COMPARING PRE AND POST CROSS-SELLING PERFORMANCE
-- **********************************************************
SELECT  
    *, 
    'A. Pre_cross_sell' AS time_period  
FROM temp_cross_selling
UNION
SELECT  
    *, 
    'B. Post_cross_sell'  
FROM temp_cross_selling2;

-- INSIGHTS:
-- - **Cross-selling strategy led to improved cart conversion rates**, increasing from **67.16% to 68.41%**.
-- - **Average order value (AOV) increased by nearly $3**, which indicates that cross-selling encouraged customers to buy more expensive products or additional items.
-- - **Products per order increased from 1.00 to 1.04**, meaning customers are purchasing **slightly more items per transaction**.
-- - **Revenue per cart session remained stable** with a minor increase, showing that cross-selling added value without disrupting the overall cart experience.
-- - **Final Recommendation:** Further refining the cross-selling approach could boost AOV and conversion rates even more. Testing different product recommendations might increase upselling effectiveness.
