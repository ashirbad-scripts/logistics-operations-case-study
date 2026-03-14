-- Route Profitability Assessment

-- Total Revenue per Route
SELECT
	route_id,
	SUM(revenue) AS total_revenue
FROM loads
GROUP BY route_id
ORDER BY total_revenue DESC;


-- Total Fuel Cost per Route
SELECT
	l.route_id,
	SUM(fp.total_cost) AS total_fuel_cost
FROM loads l
JOIN trips t ON t.load_id = l.load_id
JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
GROUP BY l.route_id
ORDER BY total_fuel_cost DESC;


-- Net Route Profitability (Revenue − Fuel Cost)
WITH route_revenue AS (
	SELECT 
		route_id,
		SUM(revenue) AS total_route_revenue
	FROM loads
	GROUP BY route_id
),
route_fuel AS (
	SELECT
		l.route_id,
		SUM(fp.total_cost) AS fuel_cost
	FROM loads l
	JOIN trips t ON t.load_id = l.load_id
	JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
	GROUP BY l.route_id
)
SELECT
	r.route_id,
	r.total_route_revenue,
	f.fuel_cost,
	r.total_route_revenue - f.fuel_cost AS net_profit
FROM route_revenue r
JOIN route_fuel f  ON r.route_id = f.route_id
ORDER BY net_profit DESC;



-- Monthly Profit Trend per Route (Time Series)
SELECT
	l.route_id,
	DATE_TRUNC('month', t.dispatch_date)::DATE AS "month",
	SUM(l.revenue) - SUM(fp.total_cost) AS monthly_profit
FROM loads l
JOIN trips t ON t.load_id = l.load_id
JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
GROUP BY l.route_id, DATE_TRUNC('month', t.dispatch_date)
ORDER BY l.route_id, "month";


-- Top 5 Most Profitable Routes per Quarter
WITH route_profit AS (
	SELECT 
		l.route_id,
		DATE_TRUNC('quarter', t.dispatch_date)::DATE AS quarter,
		SUM(l.revenue) - SUM(fp.total_cost) AS profit
	FROM loads l
	JOIN trips t ON t.load_id = l.load_id
	JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
	GROUP BY 
		l.route_id,
		DATE_TRUNC('quarter', t.dispatch_date)	
)
SELECT * 
FROM (
	SELECT *,
		DENSE_RANK() OVER(PARTITION BY quarter ORDER BY profit DESC) AS rnk
	FROM route_profit
)
WHERE rnk <= 5;



-- Routes with Increasing Fuel Cost Trend (Last 3 Months)
WITH monthly_fuel AS (
	SELECT 
		l.route_id,
		DATE_TRUNC('month', t.dispatch_date)::DATE AS "month",
		SUM(fp.total_cost) AS fuel_cost
	FROM loads l
	JOIN trips t ON t.load_id = l.load_id
	JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
	GROUP BY 
		l.route_id,
		DATE_TRUNC('month', t.dispatch_date)	
),
fuel_growth AS (
	SELECT *,
		LAG(fuel_cost, 1) OVER(PARTITION BY route_id ORDER BY "month") AS prev1,
		LAG(fuel_cost, 2) OVER(PARTITION BY route_id ORDER BY "month") AS prev2
	FROM monthly_fuel
)
SELECT *
FROM fuel_growth
WHERE fuel_cost > prev1 
	AND prev1 > prev2;


-- Compare Route Profitability vs Company Average
WITH route_profit AS (
	SELECT
		l.route_id,
		SUM(l.revenue) - SUM(fp.total_cost) AS profit
	FROM loads l
	JOIN trips t ON t.load_id = l.load_id
	JOIN fuel_purchases fp ON fp.trip_id = t.trip_id
	GROUP BY l.route_id
),
avg_profit AS (
	SELECT ROUND(AVG(profit), 2) AS company_avg_profit
	FROM route_profit
)
SELECT 
	rp.route_id,
	rp.profit,
	a.company_avg_profit,
	rp.profit - a.company_avg_profit AS difference
FROM route_profit rp
CROSS JOIN avg_profit a
ORDER BY difference DESC;


-- Which route generated the highest revenue last month?
WITH last_month AS (
	SELECT
		DATE_TRUNC('month', MAX(load_date)) AS last_month
	FROM loads
)
SELECT
	route_id, 
	SUM(revenue) AS revenue
FROM loads
WHERE DATE_TRUNC('month', load_date) = (SELECT last_month FROM last_month)
GROUP BY route_id
ORDER BY revenue DESC
LIMIT 1;
