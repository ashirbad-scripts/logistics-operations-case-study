-- Fleet Utilization Monitoring

-- Total Miles Driven per Truck
SELECT
	truck_id,
	SUM(actual_distance_miles) AS total_distance_driven
FROM trips 
WHERE truck_id IS NOT NULL
GROUP BY truck_id
ORDER BY total_distance_driven DESC;


-- Total Revenue Generated per Truck
SELECT
    t.truck_id,
    SUM(l.revenue) AS total_revenue
FROM trips t
JOIN loads l
    ON t.load_id = l.load_id
GROUP BY t.truck_id
ORDER BY total_revenue DESC;


-- Monthly Revenue per Truck
SELECT
	t.truck_id,
	DATE_TRUNC('month', t.dispatch_date)::DATE AS "month",
	SUM(l.revenue) AS monthly_revenue
FROM trips t
JOIN loads l ON l.load_id = t.load_id
GROUP BY
	t.truck_id,
	DATE_TRUNC('month', t.dispatch_date)
ORDER BY t.truck_id, month;


-- Rolling 3-Month Utilization per Truck
WITH monthly_miles AS (
    SELECT
        truck_id,
        DATE_TRUNC('month', dispatch_date)::DATE AS "month",
        SUM(actual_distance_miles) AS miles
    FROM trips
    GROUP BY truck_id, DATE_TRUNC('month', dispatch_date)
)
SELECT
	*,
	ROUND(AVG(miles) OVER(
			PARTITION BY truck_id 
			ORDER BY "month" 
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
			), 2) AS rolling_3_month_miles
FROM monthly_miles
ORDER BY truck_id, "month";



-- Revenue Rank per Truck Within Each Month
WITH monthly_revenue AS (
    SELECT
        t.truck_id,
        DATE_TRUNC('month', t.dispatch_date)::DATE AS "month",
        SUM(l.revenue) AS revenue
    FROM trips t
    JOIN loads l ON t.load_id = l.load_id
    GROUP BY t.truck_id, DATE_TRUNC('month', t.dispatch_date)
)
SELECT
	*,
	DENSE_RANK() OVER(PARTITION BY "month" ORDER BY revenue DESC) AS rev_rnk
FROM monthly_revenue;



-- Trucks Operating Below Fleet Average Mileage
WITH truck_miles AS (
	SELECT
		truck_id,
		SUM(actual_distance_miles) AS truck_total_miles
	FROM trips
	GROUP BY truck_id
),
fleet_avg AS (
	SELECT 
		ROUND(AVG(truck_total_miles), 2) AS avg_fleet_miles 
	FROM truck_miles
)
SELECT 
	tm.truck_id,
	tm.truck_total_miles,
	fa.avg_fleet_miles
FROM truck_miles tm
CROSS JOIN fleet_avg fa
WHERE tm.truck_total_miles < fa.avg_fleet_miles 
ORDER BY tm.truck_total_miles;



-- Monthly Utilization Growth Rate per Truck
WITH monthly_miles AS (
    SELECT
        truck_id,
        DATE_TRUNC('month', dispatch_date)::DATE AS "month",
        SUM(actual_distance_miles) AS miles
    FROM trips
    GROUP BY truck_id, DATE_TRUNC('month', dispatch_date)
)
SELECT *
FROM (
    SELECT
        *,
        miles - LAG(miles) OVER(
            PARTITION BY truck_id 
            ORDER BY "month"
        ) AS growth_miles
    FROM monthly_miles
) t
WHERE growth_miles IS NOT NULL
ORDER BY truck_id, "month";



























