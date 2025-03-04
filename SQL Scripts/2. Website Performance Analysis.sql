-- WEBSITE MEASUREMENT & TESTING

-- FINDING TOP PAGES ON THE WEBSITE
CREATE TEMPORARY TABLE Website_Entry_Page AS
SELECT 
    website_pageview_id, 
    created_at, 
    website_session_id, 
    pageview_url 
FROM (
    SELECT *, 
           MIN(created_at) OVER (PARTITION BY website_session_id ORDER BY created_at) AS top_entry_datetime
    FROM website_pageviews
) AS T
WHERE created_at = top_entry_datetime;

SELECT 
    pageview_url, 
    COUNT(website_pageview_id) AS no_of_views 
FROM Website_Entry_Page
GROUP BY pageview_url
ORDER BY COUNT(website_pageview_id) DESC;

-- INSIGHTS:
-- - The home page has the highest number of views.
-- - The products page and specific product pages (like "The Original Mr. Fuzzy") are also popular.
-- - Understanding top pages helps in content optimization and marketing efforts.


-- IDENTIFYING TOP WEBSITE PAGES - MOST VIEWED PAGES
SELECT 
    pageview_url, 
    COUNT(DISTINCT website_pageview_id) AS no_of_pageview, 
    RANK() OVER (ORDER BY COUNT(DISTINCT website_pageview_id) DESC) AS Rank_
FROM website_pageviews 
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY COUNT(DISTINCT website_pageview_id) DESC;

-- INSIGHTS:
-- - The home page is the most frequently visited, making it a key entry point.
-- - The products page ranks second, showing strong user interest.
-- - The cart and thank-you pages have fewer views, suggesting a drop-off in checkout completion.
-- - Pages with lower ranks may require better navigation or marketing push.


-- IDENTIFYING TOP ENTRY PAGES
CREATE TEMPORARY TABLE top_entry_pages AS
WITH CTE_base_query AS (
    SELECT *, 
           MIN(created_at) OVER (PARTITION BY website_session_id ORDER BY created_at) AS First_session
    FROM website_pageviews
    WHERE created_at < '2012-06-12'
)
SELECT 
    website_pageview_id, 
    created_at, 
    website_session_id, 
    pageview_url 
FROM CTE_base_query
WHERE created_at = First_session;

SELECT 
    pageview_url, 
    COUNT(DISTINCT website_pageview_id) AS entry_page_sessions 
FROM top_entry_pages
GROUP BY pageview_url
ORDER BY entry_page_sessions DESC;

-- INSIGHTS:
-- - The home page is the top entry point, meaning most visitors start their journey here.
-- - Other entry points, like product pages, have significantly fewer entry sessions.
-- - Optimizing the homepage experience is critical for retaining traffic.
-- - A/B testing alternative entry pages might help in improving conversion rates.


-- LANDING PAGE VS EXIT PAGE CONVERSION RATE
CREATE TEMPORARY TABLE Landing_exit_page_CVR AS
WITH CTE_base_query AS (
    SELECT *, 
           FIRST_VALUE(pageview_url) OVER (PARTITION BY website_session_id ORDER BY created_at) AS Landing_page,
           FIRST_VALUE(pageview_url) OVER (PARTITION BY website_session_id ORDER BY created_at DESC) AS Exit_page
    FROM website_pageviews
    WHERE created_at BETWEEN '2014-01-01' AND '2014-02-01'
)
SELECT * FROM CTE_base_query;

-- INSIGHTS:
-- - This query helps analyze which pages users land on and where they exit.
-- - Identifying high-exit pages helps in reducing drop-offs.
-- - If users frequently exit from the cart page, checkout process optimization is needed.
-- - A high exit rate on landing pages suggests content or navigation issues.


-- CALCULATING CONVERSION RATE FROM LANDING PAGE TO EXIT PAGE
CREATE TEMPORARY TABLE Landing_exit_page_CVR2 AS
WITH CTE_Numberofsessions_from_Landing_to_exit_page AS (
    SELECT *, 
           SUM(sessions) OVER (PARTITION BY Landing_page) AS Total_sessions 
    FROM (
        SELECT 
            Landing_page,  
            Exit_page, 
            COUNT(DISTINCT website_session_id) AS sessions 
        FROM Landing_exit_page_CVR 
        GROUP BY Landing_page, Exit_page
        ORDER BY Landing_page, COUNT(DISTINCT website_session_id) DESC, Exit_page 
    ) AS t
)
SELECT *, 
       CONCAT(ROUND((sessions / Total_sessions) * 100, 2), ' %') AS Conversion_rate, 
       CASE 
           WHEN Landing_page = Exit_page THEN 'Bounced Session' 
           ELSE NULL 
       END AS 'Bounced?'
FROM CTE_Numberofsessions_from_Landing_to_exit_page;

SELECT * FROM Landing_exit_page_CVR2;

-- INSIGHTS:
-- - The bounce rate for the homepage is 38.48%, which is better than Lander-2 (43.9%) and Lander-3 (61.57%).
-- - The home page performs the best, retaining more visitors.
-- - Lander-3 has the worst performance, meaning it likely needs UX/UI improvements.
-- - Conversion rates for reaching the shipping page:
--   - Home Page: 3.298% (Best)
--   - Lander-2: 2.83%
--   - Lander-3: 2.00% (Needs improvement)
-- - The checkout funnel should be optimized to ensure smooth transitions from product pages to checkout.

-- FINAL CONCLUSIONS:
-- - The **home page** is the most effective landing page.
-- - **Lander-3 has a high bounce rate**, requiring urgent improvements.
-- - **Shipping page conversion rates are low**, suggesting potential checkout friction.
-- - Focusing on improving **landing page design, product page clarity, and checkout flow** could improve overall conversion rates.


-- **************************************************************************************************************************************
-- ****************************** BOUNCE RATE ANALYSIS ***********************************************************************************

-- CALCULATE BOUNCE RATE ON THE LANDING PAGE

WITH CTE AS (
    SELECT *, 
           COUNT(pageview_url) OVER (PARTITION BY website_session_id) AS no_of_pageviews
    FROM website_pageviews
    WHERE created_at < '2012-06-14' 
)

SELECT *, 
       bounced_session / total_session AS '%bounced_session' 
FROM (
    SELECT COUNT(DISTINCT website_session_id) AS total_session,
           (SELECT COUNT(DISTINCT website_session_id) AS bounced_sessions
            FROM CTE 
            WHERE no_of_pageviews = 1
            GROUP BY pageview_url) AS bounced_session
    FROM CTE 
) AS t;

-- INSIGHTS:
-- - The total number of sessions recorded is **11,048**.
-- - Out of these, **6,538 sessions bounced**, leading to an overall bounce rate of **59.18%**.
-- - A bounce rate above 50% suggests that improvements may be needed to retain users on landing pages.
-- - Further analysis on individual landing pages will help identify problem areas.

-- **************************************************************************************************************
-- CALCULATE FIRST DATE, LAST DATE, AND FIRST_PAGEVIEW_ID FOR THE '/lander-1' PAGE WHEN IT WAS FIRST INTRODUCED

SELECT 
    MIN(created_at) AS first_date, 
    MAX(created_at) AS last_date, 
    MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- INSIGHTS:
-- - The page **'/lander-1'** was first introduced on **June 19, 2012**.
-- - The last recorded page view occurred on **March 10, 2013**.
-- - The first recorded pageview ID for this page was **23,504**.
-- - This data helps in understanding the timeline of the page's performance and its impact over time.

-- ***********************************************************************************************************************
-- CALCULATE THE BOUNCE RATE FROM THE TWO LANDING PAGES '/home' AND '/lander-1'.
-- IDENTIFY WHICH ONE HAS A HIGHER BOUNCE RATE AND NEEDS IMPROVEMENT.

WITH CTE_Base_query AS (
    SELECT *, 
           CASE WHEN landing_page = exit_page THEN 1 ELSE NULL END AS bounced_on_landing_page 
    FROM (
        SELECT 
            p.website_pageview_id, 
            p.created_at, 
            p.website_session_id, 
            p.pageview_url, 
            FIRST_VALUE(p.pageview_url) OVER (PARTITION BY p.website_session_id ORDER BY p.created_at) AS landing_page,
            FIRST_VALUE(p.pageview_url) OVER (PARTITION BY p.website_session_id ORDER BY p.created_at DESC) AS exit_page
        FROM website_pageviews p
        INNER JOIN website_sessions s
        ON p.website_session_id = s.website_session_id
        WHERE p.created_at BETWEEN '2012-06-19' AND '2012-07-28'
        AND s.utm_source = 'gsearch' 
        AND s.utm_campaign = 'nonbrand'
    ) AS t
)

SELECT 
    landing_page, 
    COUNT(DISTINCT website_session_id) AS total_sessions, 
    COUNT(bounced_on_landing_page) AS bounced_sessions,
    COUNT(bounced_on_landing_page) / COUNT(DISTINCT website_session_id) * 100 AS bounce_rate
FROM CTE_Base_query
GROUP BY landing_page;

-- INSIGHTS:
-- - The **home page** recorded **2,261 total sessions**, out of which **1,319 bounced**, resulting in a **bounce rate of 58.34%**.
-- - The **'/lander-1' page** had **2,316 total sessions**, with **1,233 bounce sessions**, leading to a **bounce rate of 53.24%**.
-- - The bounce rate for both pages is quite high, but the **home page has a slightly worse bounce rate** than '/lander-1'.
-- - This suggests that the **home page needs more improvements** in design, navigation, or content to better retain visitors.
-- - A/B testing different layouts or adding engaging elements (like call-to-actions) could help reduce bounce rates.

-- *************************************************************************************************************************************

-- DROP TEMPORARY TABLE IF IT ALREADY EXISTS
DROP TEMPORARY TABLE IF EXISTS TEMP_Bounce_rate;

-- CREATE TEMPORARY TABLE TO STORE BOUNCE RATE DATA
CREATE TEMPORARY TABLE TEMP_Bounce_rate 
SELECT *, 
       CASE WHEN landing_page = '/home' AND landing_page = exit_page THEN 1 ELSE NULL END AS bounced_on_landing_page_HOME,
       CASE WHEN landing_page = '/lander-1' AND landing_page = exit_page THEN 1 ELSE NULL END AS bounced_on_landing_page_lander
FROM (
    SELECT 
        p.website_pageview_id, 
        p.created_at, 
        p.website_session_id, 
        p.pageview_url, 
        FIRST_VALUE(p.pageview_url) OVER (PARTITION BY p.website_session_id ORDER BY p.created_at) AS landing_page,
        FIRST_VALUE(p.pageview_url) OVER (PARTITION BY p.website_session_id ORDER BY p.created_at DESC) AS exit_page
    FROM website_pageviews p
    LEFT JOIN website_sessions s
        ON p.website_session_id = s.website_session_id
    WHERE p.created_at BETWEEN '2012-06-01' AND '2012-08-31'
    AND s.utm_source = 'gsearch' 
    AND s.utm_campaign = 'nonbrand'
) AS t;

-- INSIGHTS:
-- - This table captures users who landed and exited on the same page, marking them as bounced.
-- - It differentiates bounces for the home page ('/home') and a landing page ('/lander-1').
-- - This allows a detailed analysis of bounce rates over time.


-- CALCULATING WEEKLY BOUNCE RATE FOR '/HOME' AND '/LANDER-1'
SELECT 
    *, 
    home_landing / total_sessions AS h_bounce_rate, 
    lander_landing / total_sessions AS l_bounce_rate 
FROM (
    SELECT 
        WEEK(created_at) AS week_, 
        MIN(DATE(created_at)) AS week_start_date, 
        COUNT(DISTINCT CASE WHEN bounced_on_landing_page_HOME = 1 THEN website_session_id ELSE NULL END) AS home_landing,
        COUNT(DISTINCT CASE WHEN bounced_on_landing_page_lander = 1 THEN website_session_id ELSE NULL END) AS lander_landing,
        COUNT(DISTINCT website_session_id) AS total_sessions
    FROM TEMP_Bounce_rate
    GROUP BY 1
) AS t;

-- INSIGHTS:
-- - The bounce rate for the **home page ('/home')** starts high (above **60%** in early June) but trends downward.
-- - The bounce rate for **'/lander-1'** starts at **0%** in early weeks, but as traffic increases, it stabilizes around **25%-50%**.
-- - **Between July 29 - August 26**, there are **no home landings**, indicating a possible shift in marketing strategy or traffic allocation.
-- - **'/lander-1' sees an increase in bounce rate in August**, suggesting user engagement challenges or ineffective campaign targeting.
-- - **Key Recommendation:** Focus on **reducing bounce rates further** through A/B testing, improving landing page design, and analyzing session behavior.

-- *************************************************************************************************************************************
-- ******************************* Building Conversion Funnels ***********************************************************************

USE mavenfuzzyfactory;

-- DROP TEMPORARY TABLE IF IT ALREADY EXISTS
DROP TEMPORARY TABLE IF EXISTS Temp_conversion_funnel_BT;

-- CREATE TEMPORARY TABLE TO STORE CONVERSION FUNNEL DATA
CREATE TEMPORARY TABLE Temp_conversion_funnel_BT 
SELECT * FROM (
    SELECT 
        p.*, 
        FIRST_VALUE(pageview_url) OVER (PARTITION BY website_session_id ORDER BY created_at) AS home_page,
        FIRST_VALUE(pageview_url) OVER (PARTITION BY website_session_id ORDER BY created_at DESC) AS exit_page, 
        s.utm_source, 
        s.utm_campaign
    FROM website_pageviews p
    LEFT JOIN website_sessions s
        ON p.website_session_id = s.website_session_id
    WHERE 
        p.created_at BETWEEN '2012-06-19' AND '2012-07-28' 
        AND s.utm_source = 'gsearch' 
        AND s.utm_campaign = 'nonbrand'
) AS T;

-- INSIGHTS:
-- - This table helps analyze **the user journey** from their **first pageview to their exit page**.
-- - It allows us to measure **where users are dropping off** in the conversion funnel.
-- - Understanding these exit points helps identify **bottlenecks in the checkout process**.
-- - Helps in **optimizing landing pages and improving customer retention strategies**.

-------------------------------------------------------------------

-- CREATE CTE TO ANALYZE EXIT PAGE DISTRIBUTION FOR HOME AND LANDER-1
WITH CTE2 AS (
    WITH CTE1 AS (
        SELECT 
            created_at, 
            website_session_id, 
            pageview_url, 
            home_page, 
            exit_page 
        FROM Temp_conversion_funnel_BT
    )
    SELECT 
        COUNT(DISTINCT CASE WHEN home_page = '/home' AND exit_page = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS on_the_original_mr_fuzzy,
        COUNT(DISTINCT CASE WHEN home_page = '/home' AND exit_page = '/cart' THEN website_session_id ELSE NULL END) AS on_cart,
        COUNT(DISTINCT CASE WHEN home_page = '/home' AND exit_page = '/billing' THEN website_session_id ELSE NULL END) AS on_billing,
        COUNT(DISTINCT CASE WHEN home_page = '/home' AND exit_page = '/thank-you-for-your-order' THEN website_session_id ELSE NULL END) AS on_thankyou,
        COUNT(DISTINCT CASE WHEN home_page = '/lander-1' AND exit_page = '/lander-1' THEN website_session_id ELSE NULL END) AS on_lander_l,
        COUNT(DISTINCT CASE WHEN home_page = '/lander-1' AND exit_page = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS on_the_original_mr_fuzzy_l,
        COUNT(DISTINCT CASE WHEN home_page = '/lander-1' AND exit_page = '/cart' THEN website_session_id ELSE NULL END) AS on_cart_l,
        COUNT(DISTINCT CASE WHEN home_page = '/lander-1' AND exit_page = '/billing' THEN website_session_id ELSE NULL END) AS on_billing_l,
        COUNT(DISTINCT CASE WHEN home_page = '/lander-1' AND exit_page = '/thank-you-for-your-order' THEN website_session_id ELSE NULL END) AS on_thankyou_l
    FROM CTE1
)

-- CALCULATE CLICK-THROUGH RATES FOR DIFFERENT FUNNEL STAGES
SELECT 
    on_the_original_mr_fuzzy / on_home * 100 AS mr_fuzzy_clickthrough,
    on_cart / on_the_original_mr_fuzzy * 100 AS on_cart_clickthrough,
    on_billing / on_cart * 100 AS on_billing_clickthrough,
    on_thankyou / on_billing * 100 AS on_thankyou_clickthrough,
    on_the_original_mr_fuzzy_l / on_lander_l * 100 AS mr_fuzzy_clickthrough_L,
    on_cart_l / on_the_original_mr_fuzzy_l * 100 AS on_cart_clickthrough_L,
    on_billing_l / on_cart_l * 100 AS on_billing_clickthrough_L,
    on_thankyou_l / on_billing_l * 100 AS on_thankyou_clickthrough_Lander
FROM CTE2;

-- INSIGHTS:
-- - The **clickthrough rate from home to "The Original Mr. Fuzzy" product page** is **29.42%**, showing strong interest in this product.
-- - **Cart clickthrough rate from "The Original Mr. Fuzzy" page is 24.74%**, indicating **a quarter of visitors proceed to checkout**.
-- - **Billing page clickthrough rate is 100%**, suggesting **once users reach billing, they proceed further**.
-- - **Thank You page clickthrough rate is 75%**, meaning **a quarter of users drop off at the final stage of checkout**.
-- - **Lander-1 clickthrough to the product page is 34.38%**, which is slightly better than the home page.
-- - **Checkout completion rate from Lander-1 is higher**, with **91.26% making it to the Thank You page**.

-- KEY TAKEAWAYS:
-- - **Improving the Cart Page Experience**: Since **only 24.74% of users proceed from the product page to the cart**, optimizing **the cart layout, trust signals, and checkout incentives** could increase conversions.
-- - **Enhancing the Final Checkout Step**: **75% conversion from billing to purchase** means **some users abandon at the payment stage**. Adding **multiple payment options or reducing form fields** could help.
-- - **Lander-1 Performs Better in Product Engagement**: With a **higher clickthrough rate to the product page**, it may be **more effective in targeted ad campaigns**.
-- - **Funnel Optimization Focus**: The **biggest drop-off is from cart to billing**. Offering **free shipping, promo codes, or a progress bar** could encourage users to complete their purchase.








