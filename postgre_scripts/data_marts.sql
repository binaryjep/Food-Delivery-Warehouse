CREATE SCHEMA IF NOT EXISTS dm; 

CREATE TABLE dm.dm_orders_summary AS 
SELECT 
	d.full_date, 
	d.year, 
	d.month, 
	d.day, 
	f.delivery_type,
	COUNT(*) AS total_orders, 

	SUM(CASE WHEN f.order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders, 
	SUM(CASE WHEN f.order_status = 'failed' THEN 1 ELSE 0 END) AS failed_orders, 

	ROUND(AVG(f.delivery_time_minutes),2) AS avg_delivery_time_mintues,

	SUM(f.order_amount) AS total_revenue 

FROM dw.fact_orders f 
JOIN dw.dim_date d 
ON d.date_id = f.order_date_sk 
GROUP BY d.full_date, d.year, d.month, d.day, f.delivery_type 
ORDER BY d.full_date, f.delivery_type;

CREATE TABLE dm.dm_rider_performance AS 
SELECT 
	r.rider_sk, 
	r.rider_id, 
	r.name AS rider_name, 
	r.vehicle_type, 

	d.full_date, 

	COUNT(*) AS total_deliveries,

	ROUND(AVG(f.delivery_time_minutes),2) AS avg_delivery_time_minutes,

	SUM(CASE WHEN f.order_status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders, 

	SUM(f.order_amount) AS revenue_generated 
FROM dw.fact_orders f 
JOIN dw.dim_riders r 
ON r.rider_sk = f.rider_sk 
JOIN dw.dim_date d 
ON f.order_date_sk = d.date_id 
WHERE f.order_status = 'delivered'
GROUP BY r.rider_sk, r.rider_id, r.name, r.vehicle_type, d.full_date 
ORDER BY d.full_date, r.rider_sk 
