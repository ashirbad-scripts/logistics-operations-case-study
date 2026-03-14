-- Driver Performance Insights

-- On-Time Delivery Rate per Driver
SELECT 
	t.driver_id,
	ROUND(
		(COUNT(CASE WHEN de.on_time_flag = TRUE THEN 1 END) * 100.0) / COUNT(de.event_id),
	  2) AS on_time_pct
FROM trips t
JOIN delivery_events de ON de.trip_id = t.trip_id
GROUP BY t.driver_id
ORDER BY on_time_pct DESC;



-- Average MPG per Driver
SELECT 
	driver_id,
	ROUND(AVG(average_mpg), 2) AS avg_mpg_per_driver
FROM trips
GROUP BY driver_id
ORDER BY avg_mpg_per_driver DESC;


-- Revenue per Mile per Driver
SELECT
	t.driver_id,
	ROUND(SUM(l.revenue) / NULLIF(SUM(t.actual_distance_miles), 0), 4) AS rev_per_mile
FROM trips t
JOIN loads l ON t.load_id = l.load_id
GROUP BY t.driver_id
ORDER BY rev_per_mile DESC;


-- Rank Drivers by Monthly On-Time Performance
WITH driver_month AS (
	SELECT
		t.driver_id,
		DATE_TRUNC('month', t.dispatch_date)::date AS "month",
		ROUND(SUM(CASE WHEN de.on_time_flag=TRUE THEN 1 ELSE 0 END)::numeric / COUNT(*), 2) AS on_time_rate
	FROM trips t
	JOIN delivery_events de ON de.trip_id =t.trip_id
	GROUP BY t.driver_id, DATE_TRUNC('month', t.dispatch_date)
)
SELECT *,
		DENSE_RANK() OVER(PARTITION BY "month" ORDER BY on_time_rate DESC) AS rnk
FROM driver_month;



-- Top 10% Drivers by Revenue per Mile
WITH rpm AS (
	SELECT 
		t.driver_id,
		ROUND(SUM(l.revenue) / NULLIF(SUM(t.actual_distance_miles), 0), 3) AS revenue_per_mile
	FROM trips t
	JOIN loads l ON l.load_id = t.load_id
	GROUP BY t.driver_id
)
SELECT * 
FROM (
	SELECT *,
			NTILE(10) OVER(ORDER BY revenue_per_mile) AS decile
	FROM rpm
) AS ranked
WHERE decile = 1;
	

-- Compare Driver MPG vs Fleet Average
WITH fleet_avg AS (
	SELECT AVG(average_mpg) AS fleet_mpg
	FROM trips
)
SELECT
	t.driver_id,
	ROUND(AVG(t.average_mpg), 2) AS driver_avg_mpg,
	ROUND(f.fleet_mpg, 2) AS fleet_avg_mpg,
	ROUND(AVG(t.average_mpg) - f.fleet_mpg, 2) AS difference
FROM trips t
CROSS JOIN fleet_avg f
GROUP BY t.driver_id, f.fleet_mpg;


-- Month-over-Month Revenue Trend per Driver
WITH monthly_rev AS (
	SELECT
		t.driver_id,
		DATE_TRUNC('month', t.dispatch_date)::DATE AS "Month",
		SUM(l.revenue) AS monthly_revenue
	FROM trips t
	JOIN loads l ON l.load_id = t.load_id
	GROUP BY t.driver_id, DATE_TRUNC('month', t.dispatch_date)
)
SELECT
	*,
	monthly_revenue - LAG(monthly_revenue) OVER(PARTITION BY driver_id ORDER BY "Month") AS revenue_change
FROM monthly_rev
ORDER BY driver_id, "Month";



-- Which driver had the highest MPG in the most recent month?
WITH latest_month AS (
	SELECT DATE_TRUNC('month', MAX(dispatch_date))::DATE AS max_month
	FROM trips
),
driver_monthly_mpg AS (
	SELECT
		driver_id,
		DATE_TRUNC('month', dispatch_date)::DATE AS "Month",
		ROUND(AVG(average_mpg), 2) AS avg_mpg
	FROM trips
	GROUP BY driver_id, DATE_TRUNC('month', dispatch_date)
)
SELECT *
FROM driver_monthly_mpg dmm
JOIN latest_month lm ON dmm."Month" = lm.max_month
ORDER BY avg_mpg DESC
LIMIT 1;
