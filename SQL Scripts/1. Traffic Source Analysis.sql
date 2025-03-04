-- 1. TRAFFIC ANALYSIS AND OPTIMIZATION
USE mavenfuzzyfactory;

-- TRAFFIC SOURCE TRENDING
SELECT 
    WEEK(created_at) AS weekid, 
    MIN(DATE(created_at)) AS week_start_date, 
    COUNT(website_session_id) AS sessions 
FROM website_sessions
WHERE 
    created_at < '2012-05-10' 
    AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);

/*
Insights Based on the Results

1. Traffic Source Trend Analysis:

The total number of sessions is gradually decreasing from March to early May.
The highest number of sessions was recorded on April 1, 2012 (1,152 sessions), after which there is a downward trend.
This suggests a potential seasonal decline or competition affecting traffic. 
*/

-- **********************************************************************************************************
-- TRAFFIC SOURCE BID OPTIMIZATION
-- BASED ON THE RESULT, THE CONVERSION RATE FOR MOBILE DEVICES IS <1%, WE HAVE TO BID MORE ON DESKTOP MARKETING TO RANK HIGHER AND DRIVE MORE SESSIONS.
SELECT 
    w.device_type,
    COUNT(DISTINCT w.website_session_id) AS sessions, 
    COUNT(DISTINCT o.order_id) AS total_orders, 
    CONCAT(ROUND((COUNT(DISTINCT o.order_id) / COUNT(DISTINCT w.website_session_id)) * 100, 4), ' %') AS session_to_orders_cvr
FROM website_sessions w
LEFT JOIN orders o
    ON w.website_session_id = o.website_session_id
WHERE 
    w.created_at < '2012-05-11' 
    AND w.utm_source = 'gsearch' 
    AND w.utm_campaign = 'nonbrand'
GROUP BY w.device_type;

/*
2. Traffic Source Bid Optimization:

Desktop: 3,911 sessions, Conversion Rate = 3.7331%
Mobile: 2,492 sessions, Conversion Rate = 0.9631%
Since the conversion rate for mobile is significantly lower than desktop, increasing bids for desktop campaigns can drive more efficient conversions.
*/

-- ***********************************************************************************************************************************************
-- TRAFFIC SOURCE SEGMENT TRENDING
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS dtop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mob_sessions
FROM website_sessions
WHERE 
    website_sessions.created_at < '2012-06-09'
    AND website_sessions.created_at > '2012-04-15'
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY YEARWEEK(website_sessions.created_at);

/*
3. Traffic Source Segment Trending:

Desktop traffic consistently surpasses mobile traffic.
The highest desktop sessions were recorded in the week of May 20, 2012 (661 sessions).
Mobile traffic peaked in the week of May 6, 2012 (282 sessions), but then started to decline.
This reinforces the strategy to focus more on desktop bids for better conversions.
*/