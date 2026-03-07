-- Maintenance Cost Impact Analysis

-- Total Maintenance Cost per Truck
SELECT	
	truck_id,
	SUM(total_cost) AS total_maintenance_cost
FROM maintenance_records
GROUP BY truck_id
ORDER BY total_maintenance_cost DESC;


-- Total Downtime Hours per Truck
SELECT	
	truck_id,
	SUM(downtime_hours) AS total_downtime
FROM maintenance_records
GROUP BY truck_id
ORDER BY total_downtime DESC;



-- Maintenance Cost per Mile Driven Per Truck
WITH truck_miles AS (
	SELECT
		truck_id,
		SUM(actual_distance_miles) AS total_miles
	FROM trips
	GROUP BY truck_id
),
maintenance_cost AS (
	SELECT
		truck_id,
		SUM(total_cost) AS maintenance_cost
	FROM maintenance_records
	GROUP BY truck_id
)
SELECT
	tm.truck_id,
	tm.total_miles,
	mc.maintenance_cost,
	ROUND(mc.maintenance_cost / NULLIF(tm.total_miles, 0), 4) AS cost_per_mile
FROM truck_miles tm
JOIN maintenance_cost mc ON mc.truck_id = tm.truck_id
ORDER BY cost_per_mile DESC;



-- Maintenance Cost Trend Over Time
SELECT
	truck_id,
	DATE_TRUNC('month', maintenance_date)::DATE AS "month",
	SUM(total_cost) AS monthly_cost
FROM maintenance_records
GROUP BY 
	truck_id,
	DATE_TRUNC('month', maintenance_date)
ORDER BY
	truck_id,
	"month";


-- Top 5 Trucks With Highest Downtime in Last 6 Months 
-- Note :- (current_date = 01-08-2024)
SELECT *
FROM (
	SELECT 
		truck_id,
		SUM(downtime_hours) AS downtime,
		DENSE_RANK() OVER(ORDER BY SUM(downtime_hours) DESC) AS rnk
	FROM maintenance_records
	WHERE maintenance_date >= DATE '2024-08-01' - INTERVAL '6 months'
	GROUP BY truck_id
) AS ranked
WHERE rnk <= 5;



WITH downtime AS (
    SELECT
        truck_id,
        DATE_TRUNC('month', maintenance_date) AS month,
        SUM(downtime_hours) AS downtime
    FROM maintenance_records
    GROUP BY truck_id, DATE_TRUNC('month', maintenance_date)
),
trip_count AS (
    SELECT
        truck_id,
        DATE_TRUNC('month', dispatch_date) AS month,
        COUNT(trip_id) AS trips
    FROM trips
    GROUP BY truck_id, DATE_TRUNC('month', dispatch_date)
)
SELECT
    d.truck_id,
    d.month,
    d.downtime,
    t.trips
FROM downtime d
JOIN trip_count t
    ON d.truck_id = t.truck_id
    AND d.month = t.month
ORDER BY d.truck_id, d.month;



-- Downtime Impact on Monthly Trip Count
WITH monthly_downtime AS (
	SELECT
		truck_id,
		DATE_TRUNC('month', maintenance_date)::DATE AS downtime_month,
		SUM(downtime_hours) AS downtime
	FROM maintenance_records
	GROUP BY 
		truck_id, 
		DATE_TRUNC('month', maintenance_date)
),
monthly_trip_count AS (
	SELECT
		truck_id,
		DATE_TRUNC('month', dispatch_date)::DATE AS trip_month,
		COUNT(trip_id) AS total_trips
	FROM trips
	GROUP BY
		truck_id,
		DATE_TRUNC('month', dispatch_date)
)
SELECT
	d.truck_id,
	d.downtime_month,
	d.downtime,
	t.total_trips
FROM monthly_downtime d
JOIN monthly_trip_count t
	ON t.truck_id = d.truck_id
	AND d.downtime_month = t.trip_month
ORDER BY
	d.truck_id,
	d.downtime_month


-- Maintenance Cost vs Revenue Generated
WITH maintenance_cost AS (
	SELECT
		truck_id,
		SUM(total_cost) AS maintenance_cost
	FROM maintenance_records
	GROUP BY truck_id
),
truck_revenue AS (
	SELECT
		t.truck_id,
		SUM(l.revenue) AS total_revenue
	FROM trips t
	JOIN loads l ON l.load_id = t.load_id
	GROUP BY t.truck_id
)
SELECT
	tr.truck_id,
	tr.total_revenue,
	mc.maintenance_cost,
	tr.total_revenue - mc.maintenance_cost AS net_value
FROM maintenance_cost mc
JOIN truck_revenue tr ON tr.truck_id = mc.truck_id
ORDER BY net_value DESC;


-- Which truck had zero downtime last quarter?
SELECT truck_id
FROM trucks
WHERE truck_id NOT IN (
		SELECT truck_id
		FROM maintenance_records
		WHERE maintenance_date >= DATE_TRUNC('quarter', CURRENT_DATE) - INTERVAL '3 months'
			AND maintenance_date < DATE_TRUNC('quarter', CURRENT_DATE)
)