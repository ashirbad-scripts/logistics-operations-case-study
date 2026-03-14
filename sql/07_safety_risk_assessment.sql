-- Safety Risk Assessment

-- Incident Count per Driver
SELECT
	driver_id,
	COUNT(driver_id) AS total_incidents
FROM safety_incidents
GROUP BY driver_id
ORDER BY total_incidents DESC;


-- Preventable Incident Rate per Driver
SELECT
	driver_id,
	SUM(CASE WHEN preventable_flag = TRUE THEN 1 ELSE 0 END) AS preventable_incidents,
	COUNT(*) AS total_incidents,
	ROUND(
		100.0 * SUM(CASE WHEN preventable_flag = TRUE THEN 1 ELSE 0 END) / COUNT(*),
	2) AS preventable_rate_pct
FROM safety_incidents
GROUP BY driver_id
ORDER BY preventable_rate_pct DESC;


-- Monthly Incident Trend
SELECT
	TO_CHAR("month", 'Mon-YYYY') AS "months",
	incidents
FROM (
	SELECT	
	DATE_TRUNC('month', incident_date)::DATE AS "month",
	COUNT(*) AS incidents
	FROM safety_incidents
	GROUP BY DATE_TRUNC('month', incident_date)
	ORDER BY "month"
)


-- Rank Drivers by Incident Frequency
SELECT 
	driver_id,
	COUNT(*) AS incident_count,
	DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS risk_rank
FROM safety_incidents
GROUP BY driver_id;


-- Preventable vs Non-Preventable Ratio
WITH incident_counts AS (
	SELECT
		SUM(CASE WHEN preventable_flag = TRUE THEN 1 ELSE 0 END) AS preventable,
		SUM(CASE WHEN preventable_flag = FALSE THEN 1 ELSE 0 END) AS non_preventable
	FROM safety_incidents
)
SELECT
	*,
	ROUND(
		preventable::numeric / NULLIF(non_preventable, 0)
	, 2) AS preventable_ratio
FROM incident_counts;


-- Incident Rate per 100 Trips
WITH trip_counts AS (
	SELECT
		driver_id,
		COUNT(*) AS trips
	FROM trips
	GROUP BY driver_id
),
incident_counts AS (
	SELECT 
		driver_id,
		COUNT(*) AS incidents
	FROM safety_incidents
	GROUP BY driver_id
)
SELECT
	t.driver_id,
	COALESCE(i.incidents, 0) AS total_incidents,
	t.trips,
	ROUND(100.0 * COALESCE(i.incidents, 0) / t.trips, 2) AS incidents_per_100_trips
FROM trip_counts t
LEFT JOIN incident_counts i 
	ON t.driver_id = i.driver_id
ORDER BY incidents_per_100_trips DESC;


-- Most accident prone time
SELECT 
	incident_time,
	COUNT(*) AS total_incidents
FROM safety_incidents
GROUP BY incident_time;


-- Incident Type Cost Analysis
SELECT
    incident_type,
    COUNT(*) AS total_incidents,
    SUM(vehicle_damage_cost) AS vehicle_damage,
    SUM(cargo_damage_cost) AS cargo_damage,
    SUM(claim_amount) AS total_claim
FROM safety_incidents
GROUP BY incident_type
ORDER BY total_claim DESC;


-- Drivers With Above-Average Claim Cost
SELECT
	driver_id,
	COUNT(*) AS incidents,
	SUM(claim_amount) AS total_cost
FROM safety_incidents
GROUP BY driver_id
HAVING SUM(claim_amount) > 
		(SELECT AVG(total_claim)
			FROM (
				SELECT SUM(claim_amount) AS total_claim 
				FROM safety_incidents 
				GROUP BY driver_id
		) s);



-- Drivers With Increasing Incident Frequency
WITH monthly_incidents AS (
    SELECT
        driver_id,
        DATE_TRUNC('month', incident_date) AS month,
        COUNT(*) AS incidents
    FROM safety_incidents
    GROUP BY driver_id, DATE_TRUNC('month', incident_date)
),
incident_lag AS (
    SELECT
        driver_id,
        month,
        incidents,
        LAG(incidents) OVER (
            PARTITION BY driver_id
            ORDER BY month
        ) AS prev_month_incidents
    FROM monthly_incidents
)
SELECT *
FROM incident_lag
WHERE prev_month_incidents IS NOT NULL
ORDER BY driver_id, month;



-- Cost discrepancy analysis
WITH summary AS (
	SELECT
		incident_id,
		driver_id,
		vehicle_damage_cost,
		cargo_damage_cost,
		claim_amount,
		(vehicle_damage_cost  + cargo_damage_cost) AS total_damage_cost,
		claim_amount - (vehicle_damage_cost  + cargo_damage_cost) AS claim_difference
	FROM safety_incidents
)
SELECT
	*,
	CASE 
		WHEN claim_amount > total_damage_cost THEN 'Claim higher than damage'
		WHEN claim_amount < total_damage_cost THEN 'Damage higher than claim'
		ELSE 'Claim matches damage'
	END AS claim_status
FROM summary
ORDER BY claim_difference DESC;


-- most common word appearing in the description column,
SELECT 
	word,
	COUNT(*) AS frequency
FROM (
	SELECT 
		LOWER(regexp_split_to_table(description, '\s+')) AS word
	FROM safety_incidents
) t
GROUP BY word
ORDER BY frequency DESC
LIMIT 10;


-- Severity Report From Descriptions
SELECT
	COALESCE(
		REGEXP_REPLACE(description, '.*(minor|moderate|severe|critical).*', '\1', 'i'),
		'Unknown'
	) AS severity,
	COUNT(*) AS total_incidents
FROM safety_incidents
GROUP BY severity
ORDER BY total_incidents DESC;



