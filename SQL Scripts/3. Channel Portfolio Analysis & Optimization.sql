USE mavenfuzzyfactory;

-- **********************************************************
-- WEEKLY SESSION TREND ANALYSIS FOR GSEARCH AND BSEARCH
-- **********************************************************
SELECT 
    WEEK(created_at) AS week, 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' 
        THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' 
        THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29' 
GROUP BY WEEK(created_at)
ORDER BY week;

-- INSIGHTS:
-- - Gsearch consistently has more sessions than Bsearch.
-- - There's a peak in Gsearch sessions in mid-November, showing an increase in traffic.
-- - Bsearch remains relatively stable but lower than Gsearch.
-- - Gsearch appears to be a more dominant source of paid search traffic.

-- **********************************************************
-- COMPARING MOBILE TRAFFIC ACROSS CHANNELS
-- **********************************************************
SELECT 
    *,
    mobile_session / total_sessions AS pct_mobile 
FROM (
    SELECT 
        utm_source, 
        COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
            THEN website_session_id ELSE NULL END) AS total_sessions,
        COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' 
            AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_session
    FROM website_sessions
    WHERE created_at BETWEEN '2012-08-22' AND '2012-11-30'
    GROUP BY utm_source
) AS t;

-- INSIGHTS:
-- - Mobile sessions contribute 24.52% of total traffic for Gsearch.
-- - Mobile sessions are only 8.62% of total traffic for Bsearch.
-- - Gsearch has a stronger mobile presence, indicating better reach in mobile advertising.
-- - Bsearch's mobile performance is relatively weak, suggesting a focus on desktop users.

-- **********************************************************
-- CROSS-CHANNEL BID OPTIMIZATION (CONVERSION RATE ANALYSIS)
-- **********************************************************
SELECT 
    *, 
    orders_mobile / sessions_mobile * 100 AS CVR_mobile, 
    orders_desktop / sessions_desktop * 100 AS CVR_desktop 
FROM (
    SELECT 
        utm_source, 
        COUNT(DISTINCT CASE WHEN device_type = 'mobile' 
            THEN w.website_session_id ELSE NULL END) AS sessions_mobile,
        COUNT(DISTINCT CASE WHEN device_type = 'desktop' 
            THEN w.website_session_id ELSE NULL END) AS sessions_desktop,
        COUNT(DISTINCT CASE WHEN device_type = 'mobile' 
            THEN o.order_id ELSE NULL END) AS orders_mobile,
        COUNT(DISTINCT CASE WHEN device_type = 'desktop' 
            THEN o.order_id ELSE NULL END) AS orders_desktop
    FROM website_sessions w
    LEFT JOIN orders o
        ON w.website_session_id = o.website_session_id
    WHERE w.created_at BETWEEN '2012-08-22' AND '2012-09-19'
        AND w.utm_campaign = 'nonbrand'
    GROUP BY w.utm_source
) AS t;

-- INSIGHTS:
-- - Desktop conversion rates are higher than mobile for both Gsearch and Bsearch.
-- - Gsearch has a better conversion rate overall (Mobile: 1.28%, Desktop: 4.52%).
-- - Bsearch’s mobile conversion rate is very low (0.76%), indicating a lack of mobile effectiveness.
-- - This suggests increasing the **desktop bid on Gsearch** while focusing on mobile optimizations.

-- **********************************************************
-- CHANNEL PORTFOLIO TREND ANALYSIS
-- **********************************************************
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' 
        THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' 
        THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' 
        THEN website_session_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' 
        THEN website_session_id ELSE NULL END) AS b_pct_of_g_dtop,

    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' 
        THEN website_session_id ELSE NULL END) AS g_mob_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' 
        THEN website_session_id ELSE NULL END) AS b_mob_sessions,

    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' 
        THEN website_session_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' 
        THEN website_session_id ELSE NULL END) AS b_pct_of_g_mob

FROM website_sessions
WHERE 
    created_at > '2012-11-04' -- specified in the request
    AND created_at < '2012-12-22' -- dictated by the time of the request
    AND utm_campaign = 'nonbrand' -- limiting to nonbrand paid search
GROUP BY YEARWEEK(created_at);

-- INSIGHTS:
-- - Desktop sessions for **Bsearch are consistently about 40% of Gsearch sessions**.
-- - Mobile sessions for **Bsearch are only 8-12% of Gsearch mobile sessions**.
-- - Gsearch dominates both **desktop and mobile** sessions, making it the **stronger paid search platform**.
-- - Given the high performance of Gsearch, it may be beneficial to **increase ad spend on Gsearch** rather than focusing on Bsearch.

