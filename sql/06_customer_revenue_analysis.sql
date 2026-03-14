-- Customer Revenue Analysis

-- Total Revenue per Customer
SELECT
	c.customer_id,
	c.customer_name,
	SUM(l.revenue) AS total_revenue
FROM customers c
JOIN loads l 
	ON c.customer_id = l.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_revenue DESC;


-- Average Revenue per Load per Customer
SELECT
	c.customer_id, 
	c.customer_name,
	ROUND(AVG(l.revenue), 2) AS avg_revenue_per_load
FROM customers c
JOIN loads l 
	ON c.customer_id = l.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY avg_revenue_per_load DESC;


-- Monthly Revenue Trend per Customer
SELECT
	c.customer_name,
	TO_CHAR(DATE_TRUNC('month', l.load_date)::DATE, 'Mon-YYYY') AS "month",
	SUM(l.revenue) AS  monthly_revenue
FROM customers c
JOIN loads l 
	ON c.customer_id = l.customer_id
GROUP BY 
	c.customer_name,
	DATE_TRUNC('month', l.load_date)
ORDER BY DATE_TRUNC('month', l.load_date);



-- Top Customers by Quarterly Revenue
WITH quarterly_revenue AS (
	SELECT
		c.customer_id,
		DATE_TRUNC('month', l.load_date)::DATE AS quarter,
		SUM(l.revenue) AS revenue
	FROM customers c
	JOIN loads l
		ON c.customer_id = l.customer_id
	GROUP BY
		c.customer_id, DATE_TRUNC('month', l.load_date)	
)
SELECT *
FROM (
	SELECT *,
		DENSE_RANK() OVER(PARTITION BY quarter ORDER BY revenue DESC) AS rev_rnk
	FROM quarterly_revenue
) ranked
WHERE rev_rnk <= 5;


-- Customer Revenue Share vs Total Company Revenue
WITH customer_revenue AS (
	SELECT 
		c.customer_id,
		c.customer_name,
		SUM(l.revenue) AS customer_revenue
	FROM customers c
	JOIN loads l
		ON c.customer_id = l.customer_id
	GROUP BY c.customer_id, c.customer_name
),
total_company_revenue AS (
	SELECT SUM(revenue) AS total_revenue 
	FROM loads
)
SELECT
	c.customer_id,
	c.customer_name,
	c.customer_revenue,
	ROUND(100.0 * (c.customer_revenue / t.total_revenue), 2) AS revenue_share_percent
FROM customer_revenue c
CROSS JOIN total_company_revenue t
ORDER BY revenue_share_percent DESC;


-- Revenue Growth Rate per Customer (Month-over-Month)
WITH monthly_rev AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', load_date) AS "month",
        SUM(revenue) AS revenue
    FROM loads
    GROUP BY customer_id, DATE_TRUNC('month', load_date)
)
SELECT
	*,
	revenue - LAG(revenue) OVER(
		PARTITION BY customer_id
		ORDER BY "month"
	) AS revenue_growth
FROM monthly_rev
ORDER BY customer_id, "month"


-- Which customer contributed the most revenue this year?
-- If current date then use this formula `DATE_PART('year', CURRENT_DATE)`
WITH X AS (
	SELECT
	    customer_id,
	    SUM(revenue) AS total_revenue
	FROM loads
	WHERE DATE_PART('year', load_date) = 2024
	GROUP BY customer_id
	ORDER BY total_revenue ASC
	LIMIT 1
)
SELECT 
	x.customer_id,
	c.customer_name,
	x.total_revenue
FROM x
JOIN customers c ON c.customer_id = x.customer_id;
