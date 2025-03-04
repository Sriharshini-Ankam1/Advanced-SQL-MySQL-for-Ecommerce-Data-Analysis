-- Identifying Repeat Customers
USE mavenfuzzyfactory;

SELECT 
    total_sessions, 
    COUNT(user_id) AS users 
FROM (
    SELECT DISTINCT 
        user_id,
        COUNT(website_session_id) OVER (PARTITION BY user_id) AS total_sessions
    FROM website_sessions
    WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
) AS t 
GROUP BY total_sessions;

-- ===================================================================================
-- INSIGHTS:
-- - The majority of users had only 1 session, while fewer users returned for multiple sessions.
-- - Users with only 1 session: 128,424, showing a high number of single-visit users.
-- - Users with 2+ sessions: Significantly lower, indicating room for improving retention.
-- ===================================================================================


-- Analyzing Repeat Customer Behavior
WITH CTE AS (
    SELECT 
        *, 
        LAG(is_repeat_session) OVER (PARTITION BY user_id ORDER BY created_at) AS previous_session,
        LAG(created_at) OVER (PARTITION BY user_id ORDER BY created_at) AS previous_created_at
    FROM website_sessions
    WHERE created_at BETWEEN '2014-01-01' AND '2014-11-01'
) 

SELECT 
    MIN(DATEDIFF(created_at, previous_created_at)) AS min_days_from_first_to_Second_order, 
    MAX(DATEDIFF(created_at, previous_created_at)) AS max_days_from_first_to_Second_order, 
    AVG(DATEDIFF(created_at, previous_created_at)) AS avg_days_from_first_to_Second_order
FROM CTE 
WHERE previous_session = 0;

-- ===================================================================================
-- INSIGHTS:
-- - The **minimum time** between a user's first and second session was **1 day**.
-- - The **maximum time** for a second session was **69 days**, showing a large variation in engagement.
-- - On **average, users returned after 33.25 days**, indicating a long gap before repeat visits.
-- - Encouraging **shorter revisit cycles** (e.g., via retargeting ads or email marketing) could improve retention.
-- ===================================================================================


-- New vs. Repeat Channel Patterns
SELECT 
    CASE 
        WHEN utm_source IS NULL 
             AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') 
             THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' 
             THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' 
             THEN 'paid_brand'
        WHEN utm_source IS NULL 
             AND http_referer IS NULL 
             THEN 'direct_type_in'
        WHEN utm_source = 'socialbook' 
             THEN 'paid_social'
    END AS channel_group,
    
    COUNT(CASE 
             WHEN is_repeat_session = 0 
             THEN website_session_id ELSE NULL END) AS new_sessions,
    COUNT(CASE 
             WHEN is_repeat_session = 1 
             THEN website_session_id ELSE NULL END) AS repeat_sessions

FROM website_sessions

WHERE created_at < '2014-11-05'  -- Date of the assignment
      AND created_at >= '2014-01-01'  -- Prescribed date range in the assignment

GROUP BY 1
ORDER BY 3 DESC;

-- ===================================================================================
-- INSIGHTS:
-- - **Paid Nonbrand** campaigns had the highest number of new sessions (119,950) but no repeat sessions.
-- - **Organic Search, Paid Brand, and Direct Type-In** had significant repeat sessions, indicating **loyal visitors**.
-- - **Paid Social** had some traction but no repeat sessions, suggesting engagement might need improvement.
-- - **Recommendation:** Increase efforts on organic search and direct-type-in visitors, as they have **higher retention potential**.
-- ===================================================================================


-- New vs. Repeat Customer Performance
SELECT 
    is_repeat_session,
    
    -- Counting distinct website sessions
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    
    -- Calculating conversion rate: orders divided by sessions
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    
    -- Calculating revenue per session
    SUM(price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS rev_per_session

FROM website_sessions

LEFT JOIN orders 
    ON website_sessions.website_session_id = orders.website_session_id

WHERE website_sessions.created_at < '2014-11-08'  -- The date of the assignment
      AND website_sessions.created_at >= '2014-01-01'  -- Prescribed date range in assignment

GROUP BY 1;

-- ===================================================================================
-- INSIGHTS:
-- - **New visitors (first-time sessions) had a lower conversion rate (6.8%)** compared to repeat visitors (8.11%).
-- - **Repeat visitors generated higher revenue per session ($5.16 vs. $4.34 for new users)**.
-- - This suggests that **returning customers are more valuable**, making retention strategies crucial.
-- - **Recommendation:** Focus on **customer re-engagement campaigns** to bring visitors back for repeat purchases.
-- ===================================================================================
