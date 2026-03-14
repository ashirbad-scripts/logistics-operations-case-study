-- Seasonal Demand Pattern Analysis

-- Monthly Load Volume & Revenue Trend
SELECT
	TO_CHAR(DATE_TRUNC('month', load_date)::DATE, 'Mon-YYYY') AS "month",
	COUNT(load_id) AS total_loads,
	SUM(revenue) AS total_revenue
FROM loads
GROUP BY DATE_TRUNC('month', load_date)::DATE
ORDER BY DATE_TRUNC('month', load_date)::DATE;



-- Monthly Trip Volume
SELECT
    TO_CHAR(DATE_TRUNC('month', dispatch_date)::DATE, 'Mon-YYYY') AS month,
    COUNT(trip_id) AS total_trips
FROM trips
GROUP BY DATE_TRUNC('month', dispatch_date)::DATE
ORDER BY DATE_TRUNC('month', dispatch_date)::DATE;



-- Quarter-wise Shipment Trend
SELECT
	TO_CHAR(DATE_TRUNC('quarter', load_date)::DATE, 'Mon-YYYY') AS quarter,
	COUNT(load_id) AS total_loads
FROM loads
GROUP BY DATE_TRUNC('quarter', load_date)::DATE
ORDER BY DATE_TRUNC('quarter', load_date)::DATE;



-- Month-over-Month Load Growth
WITH monthly_loads AS (
	SELECT
		DATE_TRUNC('month', load_date)::DATE AS "month",
		COUNT(load_id) AS total_loads
	FROM loads
	GROUP BY DATE_TRUNC('month', load_date)
)
SELECT
	TO_CHAR("month", 'Mon-YYYY') AS "Month",
	total_loads,
	total_loads - LAG(total_loads) OVER(ORDER BY "month") AS growth
FROM monthly_loads
ORDER BY "month";



-- Peak Shipment Month Identification
SELECT
	TO_CHAR("month", 'Mon-YYYY') AS "Months",
	total_loads,
	DENSE_RANK() OVER(ORDER BY total_loads DESC) AS rnk
FROM (
	SELECT 
		DATE_TRUNC('month', load_date)::DATE AS "month",
		COUNT(load_id) AS total_loads
	FROM loads
	GROUP BY DATE_TRUNC('month', load_date)::DATE
);



-- Revenue Contribution by Season
WITH seasonal_revenue AS (
	SELECT
		CASE
			WHEN EXTRACT(MONTH FROM load_date) IN (11,12,1,2) THEN 'Autumn/Winter'
			WHEN EXTRACT(MONTH FROM load_date) IN (3,4,5,6) THEN 'Spring/Summer'
			WHEN EXTRACT(MONTH FROM load_date) IN (7,8,9,10) THEN 'Monsoon/Rain'
			ELSE 'Unknown'
		END AS season,
		SUM(revenue) AS seasonal_revenue
	FROM loads
	GROUP BY season
),
total_revenue AS (
	SELECT SUM(revenue) AS total_revenue FROM loads
)
SELECT
	s.season,
	s.seasonal_revenue,
	ROUND(
		100.0* s.seasonal_revenue / t.total_revenue
	, 2) AS revenue_share_pct
FROM seasonal_revenue s
CROSS JOIN total_revenue t
ORDER BY revenue_share_pct DESC;



-- Which month had the highest load volume?
SELECT
	TO_CHAR(DATE_TRUNC('month', load_date)::DATE, 'Mon-YYYY') AS "month",
	COUNT(load_id) AS load_volume
FROM loads
GROUP BY DATE_TRUNC('month', load_date)::DATE
ORDER BY load_volume DESC 
LIMIT 1;


