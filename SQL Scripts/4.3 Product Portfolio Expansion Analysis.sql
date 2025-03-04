USE mavenfuzzyfactory;

SELECT 
    CASE 
        WHEN website_sessions.created_at < '2013-12-12' 
            THEN 'A. Pre_Birthday_Bear'
        WHEN website_sessions.created_at >= '2013-12-12' 
            THEN 'B. Post_Birthday_Bear'
        ELSE 'uh oh...check logic'
    END AS time_period,

    -- Counting unique website sessions to measure traffic in both periods
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,

    -- Counting unique orders placed to see purchasing activity
    COUNT(DISTINCT orders.order_id) AS orders,

    -- Conversion Rate: Orders divided by sessions to measure effectiveness
    COUNT(DISTINCT orders.order_id) * 1.0 / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,

    -- Total revenue generated in each period
    SUM(orders.price_usd) AS total_revenue,

    -- Total number of products sold
    SUM(orders.items_purchased) AS total_products_sold,

    -- Average Order Value (AOV): Revenue per order
    SUM(orders.price_usd) * 1.0 / COUNT(DISTINCT orders.order_id) AS average_order_value,

    -- Average number of products purchased per order
    SUM(orders.items_purchased) * 1.0 / COUNT(DISTINCT orders.order_id) AS products_per_order,

    -- Revenue Per Session (RPS): Revenue divided by total sessions
    SUM(orders.price_usd) * 1.0 / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session

FROM website_sessions
LEFT JOIN orders 
    ON orders.website_session_id = website_sessions.website_session_id

WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'

GROUP BY 1;

-- ===========================================================
-- INSIGHTS FROM THE RESULTS:
-- ===========================================================
-- 1. Sessions & Orders:
--    - Pre-Birthday Bear: 17,343 sessions, 1,055 orders.
--    - Post-Birthday Bear: 13,383 sessions, 940 orders.
--    - There was a noticeable drop in website sessions and orders after the event.

-- 2. Conversion Rate:
--    - Pre-Birthday Bear: 6.08%
--    - Post-Birthday Bear: 7.02%
--    - Despite fewer visitors, the post-event period had a higher conversion rate,
--      indicating that the traffic was more engaged.

-- 3. Total Revenue:
--    - Pre-Birthday Bear: $57,208.96
--    - Post-Birthday Bear: $53,515.44
--    - Even though traffic decreased, the total revenue remained fairly strong,
--      likely due to increased order values.

-- 4. Average Order Value (AOV):
--    - Pre-Birthday Bear: $54.23
--    - Post-Birthday Bear: $56.93
--    - Customers spent more per order post-event, which compensated for fewer orders.

-- 5. Products Per Order:
--    - Pre-Birthday Bear: 1.0464
--    - Post-Birthday Bear: 1.1234
--    - Shoppers bought more items per order after the event.

-- 6. Revenue Per Session (RPS):
--    - Pre-Birthday Bear: $3.30
--    - Post-Birthday Bear: $3.99
--    - Higher RPS post-event means that the website made more revenue per visitor,
--      even with reduced traffic.

-- ===========================================================
-- KEY TAKEAWAYS:
-- ===========================================================
-- - The event led to fewer sessions but higher engagement and spending per visitor.
-- - The increased conversion rate and AOV indicate improved targeting or product appeal.
-- - While fewer visitors might be concerning, the rise in revenue per session
--   suggests that the business attracted more valuable customers.
-- - Future strategies could focus on maintaining traffic while keeping the higher conversion
--   and spending trends intact.

