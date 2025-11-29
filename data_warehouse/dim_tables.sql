CREATE SCHEMA IF NOT EXISTS dw; 

CREATE TABLE dw.dim_users (
	users_sk SERIAL PRIMARY KEY, 
	user_id INT NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	email VARCHAR(100), 
	phone VARCHAR(20), 
	signup_date DATE, 
	signup_year INT, 
	signup_month INT, 
	city VARCHAR(50),
	is_active BOOLEAN DEFAULT TRUE
); 

INSERT INTO dw.dim_users (
	user_id, 
	name, 
	email, 
	phone, 
	signup_date, 
	signup_year,
	signup_month,
	city 
)

SELECT 
	user_id,
	name, 
	email, 
	phone, 
	signup_timestamp::DATE AS signup_date, 
	EXTRACT(YEAR FROM signup_timestamp) AS signup_year, 
	EXTRACT(MONTH FROM signup_timestamp) AS signup_month, 
	city 
FROM stg.stg_users
WHERE user_id IS NOT NULL; 

CREATE TABLE dw.dim_riders(
	rider_sk SERIAL PRIMARY KEY, 
	rider_id INT NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	vehicle_type VARCHAR(50) NOT NULL, 
	hire_date DATE, 
	hire_year INT, 
	city VARCHAR(50), 
	is_active BOOLEAN DEFAULT TRUE
); 

INSERT INTO dw.dim_riders(
	rider_id, 
	name, 
	vehicle_type, 
	hire_date, 
	hire_year, 
	city 
)

SELECT 
	rider_id,
	name, 
	vehicle_type, 
	hire_date, 
	EXTRACT(YEAR FROM hire_date) AS hire_year,
	city 
FROM stg.stg_riders 
WHERE rider_id IS NOT NULL; 

CREATE TABLE dw.dim_products(
	product_sk SERIAL PRIMARY KEY, 
	product_id INT NOT NULL, 
	product_name VARCHAR(100) NOT NULL,
	category VARCHAR(50),
	category_normalized VARCHAR(50), 
	restaurant_id INT NOT NULL, 
	restaurant_name VARCHAR(100), 
	is_active BOOLEAN DEFAULT TRUE 
);

INSERT INTO dw.dim_products(
	product_id, 
	product_name, 
	category, 
	category_normalized, 
	restaurant_id, 
	restaurant_name
)

SELECT 
	product_id,
	product_name, 
	category, 
	LOWER(TRIM(p.category)) AS category_normalized, 
	restaurant_id,
	restaurant_name 
	FROM stg.stg_products 
	WHERE product_id IS NOT NULL;

CREATE TABLE dw.dim_restaurants(
	restaurant_sk SERIAL PRIMARY KEY, 
	restaurant_id INT NOT NULL, 
	restaurant_name VARCHAR(100) NOT NULL, 
	is_active BOOLEAN DEFAULT TRUE
); 

INSERT INTO dw.dim_restaurants(
	restaurant_id, 
	restaurant_name, 
	city
)

SELECT 
	restaurant_id, 
	restaurant_name, 
FROM stg.stg_products 
WHERE restaurant_id IS NOT NULL; 

CREATE TABLE dw.dim_date(
	date_id SERIAL PRIMARY KEY, 
	full_date DATE NOT NULL UNIQUE, 
	year INT, 
	month INT, 
	day INT, 
	day_of_week INT, 
	week_of_year INT 	
); 

INSERT INTO dw.dim_date (
	full_date, 
	year,
	month, 
	day, 
	day_of_week, 
	week_of_year 
)

SELECT DISTINCT 
	d AS full_date, 
	EXTRACT(YEAR FROM d), 
	EXTRACT(MONTH FROM d), 
	EXTRACT(DAY FROM d), 
	EXTRACT(DOW FROM d), 
	EXTRACT(WEEK FROM d)

FROM (

	SELECT order_datetime::date AS d 
	FROM stg.stg_orders 
	UNION 
	SELECT payment_datetime::date AS d FROM stg.stg_payments 
) AS all_dates 
WHERE d IS NOT NULL
ORDER BY d; 

CREATE TABLE dw.dim_payment_method (
	method_sk SERIAL PRIMARY KEY, 
	method_id INT NOT NULL, 
	method_name VARCHAR(50) NOT NULL
); 

INSERT INTO dw.dim_payment_method(
	method_id, 
	method_name
)

SELECT DISTINCT 
	ROW_NUMBER() OVER (ORDER BY payment_method) AS method_id, 
	LOWER(method) AS method_name 
FROM(
	SELECT DISTINCT method 
	FROM stg.stg_payments 
) AS m; 