# Logistics Operations Analytics

## Project Overview

This project presents an end-to-end operational analytics assessment of a third-party logistics (3PL) transportation network using structured SQL analysis. The objective of the project is to transform raw operational data from a Transportation Management System (TMS) into actionable business intelligence that supports decision-making across operations, finance, fleet management, safety compliance, sales, and strategic planning functions.

The analysis evaluates multiple dimensions of logistics performance, including driver reliability, route-level profitability, fleet utilization efficiency, maintenance impact on operational capacity, fuel consumption patterns, customer revenue contribution, safety risk exposure, and seasonal demand variability.

All analytical work was conducted using PostgreSQL queries applied to a relational logistics dataset representing shipments, trips, drivers, trucks, routes, customers, and operational events.

---

## Objectives

The primary objectives of the project were:

* Evaluate driver performance using delivery reliability, fuel efficiency, and revenue productivity metrics.
* Identify profitable and cost-intensive transportation routes.
* Assess fleet utilization to detect underutilized or over-deployed equipment.
* Quantify the financial and operational impact of maintenance events.
* Analyze fuel efficiency patterns across routes and trips.
* Identify high-value customers and evaluate revenue distribution across the customer base.
* Assess operational safety risk using incident data.
* Detect seasonal demand patterns in shipment volumes.

---

## Database Architecture

The dataset models a simplified Transportation Management System (TMS) used by logistics organizations. The relational schema includes operational, transactional, and master data entities such as:

* Drivers
* Trucks
* Trailers
* Customers
* Facilities
* Routes
* Loads
* Trips
* Fuel Purchases
* Maintenance Records
* Delivery Events
* Safety Incidents

These tables capture the complete operational lifecycle of freight movement, from customer shipment booking to trip execution, fuel consumption, delivery performance, maintenance activity, and safety events.

---

## Analytical Framework

The project applies several SQL analytical techniques commonly used in operational analytics environments:

* Window Functions for ranking and benchmarking performance metrics
* Common Table Expressions (CTEs) to modularize complex analytical logic
* Time-series analysis using LAG for trend detection
* Multi-table joins to derive cross-domain operational metrics
* Aggregation and benchmarking against fleet or company averages

The analytical workflow was organized into eight operational modules aligned with key stakeholder groups within a logistics organization.

---

## Analytical Modules

1. Driver Performance Analysis
2. Route Profitability Assessment
3. Fleet Utilization Monitoring
4. Maintenance Cost Impact Analysis
5. Fuel Efficiency Analysis
6. Customer Revenue Analysis
7. Safety Risk Assessment
8. Seasonal Demand Pattern Analysis

Each module investigates a distinct operational question and produces actionable findings for relevant business stakeholders.

---

## Key Findings

The analysis revealed several significant operational insights across the logistics network:

* The fleet-wide on-time delivery rate was measured at 55.67 percent, indicating that a substantial portion of deliveries fail to meet scheduled windows.

* Route RTE00029 generated net profit significantly above the company average, while Route RTE00001 demonstrated a consistent upward trend in fuel costs, indicating potential margin pressure.

* Truck TRK00003 recorded both the highest maintenance expenditure and the highest downtime hours, highlighting a potential end-of-life asset requiring fleet management review.

* Truck TRK00040 operated significantly below fleet-average mileage, suggesting underutilization within the equipment pool.

* Route RTE00015 recorded the highest fuel cost per mile across the network, indicating potential inefficiencies in route conditions or vehicle assignments.

* Customer revenue contribution was widely distributed across the customer base, with no single customer representing a dominant share of total revenue.

* Safety analysis revealed an increase in recorded incidents in 2024 relative to the previous year, indicating potential emerging operational safety risks.

* Shipment demand remained relatively stable across the three-year observation window, though peak shipment months shifted between years, suggesting the need for dynamic capacity planning.

---

## Technologies Used

* PostgreSQL
* SQL (Window Functions, CTEs, Aggregations, Time-Series Analysis)
* pgAdmin for query development and database interaction
* Supabase (hosted PostgreSQL database environment)
* Relational Database Modeling

### Data Environment

The dataset used in this project was hosted on **Supabase**, a managed PostgreSQL platform. The analytical work was performed by connecting **pgAdmin to the Supabase database instance**.

Access to the database was granted through a **restricted analytical role rather than full administrative privileges**. As a result, the work was conducted under realistic enterprise constraints where analysts typically operate without master-level database control. All analysis therefore relied strictly on query-level access to existing tables and schema structures within the Supabase environment.

---

## Repository Structure

The repository includes the following components:

* SQL queries used to perform the operational analyses
* Dataset schema representing the logistics database
* Analytical report documenting the findings and operational insights

---

## Author

[Ashirbad Routray](https://www.linkedin.com/in/ashirbad-routray-7a872732a/)

Date: 10.03.2026
