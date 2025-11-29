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