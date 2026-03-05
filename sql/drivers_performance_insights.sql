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


drivers.csv
driver_id,first_name,last_name,hire_date,termination_date,
license_number,license_state,date_of_birth,home_terminal,
employment_status,cdl_class,years_experience

maintenance_records,csv
maintenance_id,truck_id,maintenance_date,maintenance_type,odometer_reading,labor_hours,labor_cost,parts_cost,total_cost,facility_location,downtime_hours,service_description


safety_incidents.csv
incident_id,trip_id,truck_id,driver_id,incident_date,incident_time,incident_type,location_city,location_state,at_fault_flag,injury_flag,vehicle_damage_cost,cargo_damage_cost,claim_amount,preventable_flag,description


facilities.csv
facility_id,facility_name,facility_type,city,state,latitude,longitude,dock_doors,operating_hours

trips.csv
trip_id,load_id,driver_id,truck_id,trailer_id,dispatch_date,actual_distance_miles,actual_duration_hours,fuel_gallons_used,average_mpg,idle_time_hours,trip_status



driver_monthly_metrics.csv
driver_id,month,trips_completed,total_miles,total_revenue,average_mpg,total_fuel_gallons,on_time_delivery_rate,average_idle_hours


delivery_events.csv 
event_id,load_id,trip_id,event_type,facility_id,scheduled_datetime,actual_datetime,detention_minutes,on_time_flag,location_city,location_state



truck_utilization_metrics.csv
truck_id,month,trips_completed,total_miles,total_revenue,average_mpg,maintenance_events,maintenance_cost,downtime_hours,utilization_rate


fuel_purchase.csv
fuel_purchase_id,trip_id,truck_id,driver_id,purchase_date,purchase_time,location_city,location_state,gallons,price_per_gallon,total_cost,fuel_card_number



trailers.csv
trailer_id,trailer_number,trailer_type,length_feet,model_year,vin,acquisition_date,status,current_location

loads.csv
load_id,customer_id,route_id,load_date,load_type,weight_lbs,pieces,revenue,fuel_surcharge,accessorial_charges,load_status,booking_type

customers.csv
customer_id,customer_name,customer_type,credit_terms_days,primary_freight_type,account_status,contract_start_date,annual_revenue_potential

trucks.csv
truck_id,unit_number,make,model_year,vin,acquisition_date,acquisition_mileage,fuel_type,tank_capacity_gallons,status,home_terminal

routes.csv
route_id,origin_city,origin_state,destination_city,destination_state,typical_distance_miles,base_rate_per_mile,fuel_surcharge_rate,typical_transit_days


1. Drivers  PK: driver_id
2. Trucks	PK: truck_id
3. Trailers	PK: trailer_id
4. Customers	PK:customer_id
5. Facilities	PK: facility_id
6. Routes	PK: route_id

7. Loads	PK: load_id
			FK: customer_id , route_id

8. Trips	PK: trip_id
			FK: load_id , driver_id , truck_id , trailer_id

9. Fuel_Purchases
		PK: fuel_purchase_id
		FK: trip_id , truck_id , driver_id

10. Maintenance_Records
		PK: maintenance_id
		FK: truck_id

11. Delivery_Events
		PK: event_id
		FK: load_id , trip_id , facility_id

12. Safety_Incidents
		PK: incident_id
		FK: trip_id , truck_id , driver_id

13. Driver_Monthly_Metrics
Composite Key: driver_id , month

14. Truck_Utilization_Metrics
Composite Key: truck_id , month













































































































































































































































