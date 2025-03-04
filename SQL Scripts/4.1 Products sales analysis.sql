USE mavenfuzzyfactory;

-- **********************************************************
-- PRODUCT LEVEL SALES ANALYSIS
-- **********************************************************
SELECT 
    YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(DISTINCT order_id) AS Sales,
    SUM(price_usd) AS Revenue,
    SUM(price_usd - cogs_usd) AS margin
FROM orders 
WHERE created_at < '2013-01-04'
GROUP BY 1,2;

-- INSIGHTS:
-- - Sales and revenue show an increasing trend from March to December 2012.
-- - A significant spike in sales is observed in October and November 2012.
-- - The highest margin was recorded in November 2012, indicating strong profitability.
-- - Sales dropped sharply in January 2013, possibly due to post-holiday season decline.

-- **********************************************************
-- PRODUCT LAUNCH ANALYSIS
-- **********************************************************
SELECT 
    YEAR(w.created_at) AS year,
    MONTH(w.created_at) AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT w.website_Session_id) AS sessions,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT w.website_Session_id) AS conversion,
    AVG(o.price_usd) AS Revenue_per_order,
    SUM(o.price_usd) / COUNT(DISTINCT w.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT CASE WHEN o.primary_product_id = 1 THEN o.order_id ELSE NULL END) AS product_one_orders,
    COUNT(DISTINCT CASE WHEN o.primary_product_id = 2 THEN o.order_id ELSE NULL END) AS product_two_orders
FROM website_sessions w
LEFT JOIN orders o
    ON w.website_session_id = o.website_session_id
WHERE w.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY 1,2;

-- INSIGHTS:
-- - Conversion rates remained steady from April to December 2012.
-- - The launch of the second product significantly increased the number of product_two_orders.
-- - Revenue per session saw an upward trend in early 2013.
-- - January 2013 saw a major shift where product two gained traction, impacting conversion rates.

-- **********************************************************
-- PRODUCT PATHING ANALYSIS
-- **********************************************************
WITH CTE2 AS (
    SELECT 
        w.*, 
        LEAD(w.pageview_url) OVER (PARTITION BY w.website_session_id ORDER BY w.created_at) AS next_page
    FROM website_pageviews w
    WHERE w.created_at BETWEEN '2012-10-06' AND '2013-01-06'
) 
SELECT 
    'A. Pre_product2' AS time_period,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN website_session_id ELSE NULL END) AS sessions,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_page,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page IS NOT NULL THEN website_session_id ELSE NULL END) / 
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN website_session_id ELSE NULL END) AS pct_W_next_page,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mr_fuzzy,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) / 
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN website_session_id ELSE NULL END) AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) / 
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN website_session_id ELSE NULL END) AS pct_to_lovebear
FROM CTE2

UNION

(WITH CTE1 AS (
    SELECT 
        w.*, 
        LEAD(w.pageview_url) OVER (PARTITION BY w.website_session_id ORDER BY w.created_at) AS next_page
    FROM website_pageviews w
    WHERE w.created_at BETWEEN '2013-01-06' AND '2013-04-06'
) 
SELECT 
    'B. Post_product2' AS time_period,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN website_session_id ELSE NULL END) AS sessions,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_page,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page IS NOT NULL THEN website_session_id ELSE NULL END) / 
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN website_session_id ELSE NULL END) AS pct_W_next_page,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mr_fuzzy,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) / 
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN website_session_id ELSE NULL END) AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' AND next_page = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) / 
    COUNT(DISTINCT CASE WHEN pageview_url = '/products' THEN website_session_id ELSE NULL END) AS pct_to_lovebear
FROM CTE1
);

-- INSIGHTS:
-- - After launching product two, a significant portion of traffic shifted from "Mr. Fuzzy" to "Forever Love Bear."
-- - The proportion of users navigating to "Forever Love Bear" increased post-launch.
-- - Overall engagement with product pages increased.

-- **********************************************************
-- PRODUCT CONVERSION FUNNELS
-- **********************************************************
-- DROP TEMPORARY TABLE IF EXISTS Temp_product_websession_mapping;
CREATE TEMPORARY TABLE Temp_product_websession_mapping 
SELECT   
    website_session_id, 
    pageview_url AS product_page 
FROM website_pageviews 
WHERE created_at BETWEEN '2013-01-06' AND '2013-04-10'
AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear');

-- DROP TEMPORARY TABLE IF EXISTS Temp_two_products_funnel;
CREATE TEMPORARY TABLE Temp_two_products_funnel
WITH CTE AS (
    SELECT 
        w.website_session_id, 
        w.pageview_url, 
        t.product_page
    FROM website_pageviews w
    LEFT JOIN Temp_product_websession_mapping t
        ON w.website_session_id = t.website_session_id
    WHERE created_at BETWEEN '2013-01-06' AND '2013-04-10'
)
SELECT 
    product_page, 
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN pageview_url = '/cart' THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN pageview_url = '/shipping' THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN pageview_url = '/billing-2' THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN pageview_url = '/thank-you-for-your-order' THEN website_session_id ELSE NULL END) AS to_thank_you
FROM CTE
GROUP BY product_page;

SELECT 
    product_page, 
    to_cart / sessions AS cart_clickthrough,
    to_shipping / to_cart AS shipping_click,
    to_billing / to_shipping AS billing_click,
    to_thank_you / to_billing AS thank_you_click
FROM Temp_two_products_funnel;

-- INSIGHTS:
-- - "Forever Love Bear" has a higher cart clickthrough rate compared to "Mr. Fuzzy."
-- - Billing and checkout completion rates are relatively stable across both products.
-- - More users abandon the process between cart and shipping stage.

