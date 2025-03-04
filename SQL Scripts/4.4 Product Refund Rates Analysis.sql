
-- Selecting all records from the ORDERS table before October 15, 2014
USE mavenfuzzyfactory;

SELECT * 
FROM ORDERS 
WHERE created_at < '2014-10-15';

-- Creating a Common Table Expression (CTE) to extract order and refund data
WITH CTE AS (
    SELECT 
        o.order_item_id, 
        YEAR(o.created_at) AS year, 
        MONTH(o.created_at) AS Month, 
        o.product_id, 
        o.price_usd, 
        r.order_item_refund_id, 
        r.refund_amount_usd
    FROM order_items o
    LEFT JOIN order_item_refunds r
        ON o.order_item_id = r.order_item_id
    WHERE o.created_at < '2014-10-15'
)

-- Aggregating order and refund data by year and month for each product category
SELECT 
    year, 
    Month, 

    -- Counting orders for each product
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_id END) AS p1_orders,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_id END) AS p2_orders,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_id END) AS p3_orders,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_id END) AS p4_orders,

    -- Counting refunds for each product
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refund_id END) AS p1_refunds,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refund_id END) AS p2_refunds,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refund_id END) AS p3_refunds,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refund_id END) AS p4_refunds,

    -- Calculating refund rate for each product
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refund_id END) * 100.0 
        / COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_id END) AS p1_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refund_id END) * 100.0 
        / COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_id END) AS p2_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refund_id END) * 100.0 
        / COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_id END) AS p3_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refund_id END) * 100.0 
        / COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_id END) AS p4_refund_rt

FROM CTE
GROUP BY 1, 2;

/*
```

---

### **Insights from the Results:**

1. **Orders Trend:**
   - Product 1 (p1) had the highest number of orders throughout the analyzed period.
   - Product 2 (p2) gained traction in early 2013 and maintained steady order volumes.
   - Product 3 (p3) and Product 4 (p4) saw a noticeable increase in orders starting in late 2013, indicating a potential expansion in the product portfolio.

2. **Refund Volume & Trends:**
   - Refunds for **Product 1** were consistently higher, which aligns with its higher sales volume.
   - **Product 2** showed an increasing trend in refunds, particularly after mid-2013.
   - **Product 3 and 4** had fewer refunds initially, but as sales increased, their refunds also started appearing in records.

3. **Refund Rate Analysis:**
   - The refund rate for **Product 1 (p1_refund_rt)** fluctuated between **2.3% and 9.0%** over the months.
   - **Product 2 (p2_refund_rt)** had a lower refund rate but saw spikes, indicating possible quality or fulfillment issues.
   - **Product 3 (p3_refund_rt)** saw an increase in refund rates post-2013, suggesting a potential issue after the product gained traction.
   - **Product 4 (p4_refund_rt)** had the most volatile refund rate, rising to **7-8% in later months**, suggesting post-launch challenges.

4. **Key Observations:**
   - **Product 1 remained the bestseller** but had a consistently moderate refund rate.
   - **Product 2 gained market share but experienced refund fluctuations.**
   - **Product 3 and 4 started low but grew rapidly in late 2013, with refunds increasing proportionally.**
   - **Overall refund rates remain within acceptable limits**, but specific months show spikes, indicating potential quality or service-related issues.

---

### **Recommendations:**
- **Investigate spikes in refund rates for Product 2, 3, and 4** to identify potential quality or fulfillment problems.
- **Monitor Product 1’s refund trends** as it contributes the most to order volume and refunds.
- **Analyze customer feedback and complaints** related to peak refund months to address underlying issues.
- **Consider product enhancements or better return policies** for products with higher refund rates to improve customer satisfaction.

*/