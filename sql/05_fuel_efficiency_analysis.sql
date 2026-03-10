

-- Fuel Efficiency Analysis

-- Average MPG per Route
SELECT
	l.route_id,
	ROUND(AVG(t.average_mpg), 2) AS avg_mpg
FROM loads l
JOIN trips t ON t.load_id = l.load_id
GROUP BY l.route_id
ORDER BY avg_mpg DESC;


-- Fuel Cost per Mile per Route
SELECT
	l.route_id,
	ROUND(
		SUM(fp.total_cost) / NULLIF(SUM(t.actual_distance_miles), 0)
	, 2) AS fuel_cost_per_mile
FROM loads l
JOIN trips t ON t.load_id = l.load_id
JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
GROUP BY l.route_id
ORDER BY fuel_cost_per_mile DESC;


-- MPG Trend per Route by Month
SELECT
	l.route_id,
	DATE_TRUNC('month', t.dispatch_date)::DATE AS "month",
	ROUND(AVG(t.average_mpg), 2) AS monthly_avg_mpg
FROM loads l
JOIN trips t ON t.load_id = l.load_id
GROUP BY 
	l.route_id, 
	DATE_TRUNC('month', t.dispatch_date)
ORDER BY 
	l.route_id,
	"month";


-- Rank Routes by Fuel Efficiency
WITH fuel_efficiency AS (
	SELECT 
		l.route_id,
		ROUND(AVG(t.average_mpg), 2) AS avg_mpg
	FROM loads l
	JOIN trips t ON t.load_id = l.load_id
	GROUP BY l.route_id
)
SELECT 
	route_id,
	avg_mpg,
	DENSE_RANK() OVER(ORDER BY avg_mpg DESC) AS mpg_rnk
FROM fuel_efficiency;



-- Routes with MPG Below Fleet Median
WITH route_mpg AS (
	SELECT
		l.route_id,
		SUM(t.average_mpg) AS avg_mpg
	FROM loads l
	JOIN trips t ON t.load_id = l.load_id
	GROUP BY l.route_id
),
median_mpg AS (
	SELECT PERCENTILE_CONT(0.5)
			WITHIN GROUP (ORDER BY avg_mpg) AS fleet_median
	FROM route_mpg
)
SELECT
	r.route_id,
	r.avg_mpg
FROM route_mpg r
CROSS JOIN median_mpg m
WHERE r.avg_mpg < m.fleet_median;


-- Rolling Average MPG per Route
WITH route_monthly_mpg AS (
	SELECT 
		l.route_id,
		DATE_TRUNC('month', t.dispatch_date)::DATE AS "month", 
		ROUND(AVG(t.average_mpg), 2) AS avg_mpg
	FROM loads l
	JOIN trips t ON t.load_id = l.load_id
	GROUP BY l.route_id, DATE_TRUNC('month', t.dispatch_date)
)
SELECT
	*,
	ROUND(AVG(avg_mpg) OVER(
			PARTITION BY route_id
			ORDER BY "month"
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	), 2) AS rolling_mpg
FROM route_monthly_mpg
ORDER BY route_id, "month";


-- Further Analysis

-- Fuel Spending State (Expensive Fuel Regions)
SELECT 
	location_state,
	location_city,
	COUNT(fuel_purchase_id) AS purchase_count,
	SUM(gallons) AS total_gallons,
	SUM(total_cost) AS total_cost,
	ROUND(AVG(price_per_gallon), 2) AS avg_price
FROM fuel_purchases
GROUP BY location_state, location_city
ORDER BY avg_price DESC;


-- Time When Most fuel puchases happen
SELECT 
	purchase_time,
	COUNT(fuel_purchase_id) AS total_purchases
FROM fuel_purchases
GROUP BY purchase_time
ORDER BY total_purchases DESC;


-- Detect Unusual High Fuel Purchases per city
SELECT
    fuel_purchase_id,
    location_city,
    gallons,
    total_cost
FROM (
	SELECT
		fuel_purchase_id,
		location_city,
		gallons,
		total_cost,
		AVG(gallons) OVER(PARTITION BY location_city) AS city_avg_gallons
	FROM fuel_purchases
) t
WHERE gallons > city_Avg_gallons
ORDER BY location_city, gallons DESC;



-- Fuel Purchases with the Highest Price per Gallon in Each State
SELECT fuel_purchase_id,
       location_state,
       price_per_gallon,
       gallons,
       total_cost
FROM (
      SELECT *,
             MAX(price_per_gallon) OVER(PARTITION BY location_state) AS max_price
      FROM fuel_purchases
) t
WHERE price_per_gallon = max_price
ORDER BY price_per_gallon DESC;



-- Drivers whose fuel spending is above the overall average fuel spending
WITH driver_fuel_Cost AS (
	SELECT
		driver_id,
		SUM(total_cost) AS total_fuel_spent
	FROM fuel_purchases
	GROUP BY driver_id
)
SELECT *
FROM driver_fuel_cost
WHERE driver_id IS NOT NULL 
AND total_fuel_spent > (
		SELECT AVG(total_fuel_spent)
		FROM driver_fuel_cost
)
ORDER BY total_fuel_spent DESC;












