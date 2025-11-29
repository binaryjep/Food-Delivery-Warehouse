CREATE TABLE raw.raw_users(
    user_id SERIAL PRIMARY KEY, 
    name VARCHAR(100), 
    email VARCHAR(100), 
    phone VARCHAR(20), 
    signup_ts TIMESTAMP,
    city VARCHAR(50)
);

CREATE TABLE raw.raw_riders(
    rider_id SERIAL PRIMARY KEY, 
    name VARCHAR(100), 
    vehicle_type VARCHAR(50), 
    hire_date DATE,
    city VARCHAR(50)
);

CREATE TABLE raw.raw_orders (
    order_id SERIAL PRIMARY KEY, 
    user_id INTEGER REFERENCES raw.raw_users(user_id),
    rider_id INTEGER REFERENCES raw.raw_riders(rider_id),
    order_datetime TIMESTAMP,
    pickup_datetime TIMESTAMP, 
    dropoff_datetime TIMESTAMP,
    pickup_address VARCHAR(100), 
    dropoff_address VARCHAR(100), 
    status VARCHAR(20),
    delivery_type VARCHAR(20)
);

CREATE TABLE raw.raw_products (
    product_id SERIAL PRIMARY KEY, 
    product_name VARCHAR(100), 
    category VARCHAR(20), 
    restaurant_id INTEGER, 
    restaurant_name VARCHAR(100)
);

CREATE TABLE raw.raw_payments(
    payment_id SERIAL PRIMARY KEY, 
    order_id INTEGER REFERENCES raw.raw_orders(order_id),
    payment_datetime TIMESTAMP,
    amount NUMERIC(10,2), 
    method VARCHAR(20),
    status VARCHAR(20)
);

CREATE SCHEMA stg; 

CREATE TABLE stg.stg_users(
	user_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL, 
	email VARCHAR(100), 
	phone VARCHAR(20),
	signup_timestamp TIMESTAMP, 
	city VARCHAR(50)
);

CREATE TABLE stg.stg_riders(
	rider_id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL, 
	vehicle_type VARCHAR(50) NOT NULL, 
	hire_date DATE, 
	city VARCHAR(50)
	
);

CREATE TABLE stg.stg_orders(
	order_id SERIAL PRIMARY KEY, 
    user_id INTEGER REFERENCES stg.stg_users(user_id),
    rider_id INTEGER REFERENCES stg.stg_riders(rider_id),
    order_datetime TIMESTAMP,
    pickup_datetime TIMESTAMP, 
    dropoff_datetime TIMESTAMP,
    pickup_address VARCHAR(100), 
    dropoff_address VARCHAR(100), 
    order_status VARCHAR(20) NOT NULL,
	CONSTRAINT order_status_valid CHECK (LOWER(order_status) IN ('delivered', 'cancelled')),
	delivery_type VARCHAR(20) NOT NULL,
    CONSTRAINT delivery_type_valid CHECK (LOWER(delivery_type) IN ('express', 'standard'))
);

CREATE TABLE stg.stg_products(
	product_id SERIAL PRIMARY KEY, 
    product_name VARCHAR(100) NOT NULL, 
    category VARCHAR(20) NOT NULL, 
    restaurant_id INTEGER, 
    restaurant_name VARCHAR(100)
);

CREATE TABLE stg.stg_payments(
	payment_id SERIAL PRIMARY KEY, 
    order_id INTEGER REFERENCES stg.stg_orders(order_id),
    payment_datetime TIMESTAMP,
    amount NUMERIC(10,2), 
    method VARCHAR(20) NOT NULL,
	CONSTRAINT method_valid CHECK (LOWER(method) IN ('cash','card','e-wallet')),
    payment_status VARCHAR(20) NOT NULL,
	CONSTRAINT payment_status_valid CHECK (LOWER(payment_status) IN ('paid', 'failed'))
); 

INSERT INTO stg.stg_users(
	user_id, 
	name, 
	email, 
	phone, 
	signup_timestamp, 
	city
)

SELECT 
	user_id, 
	TRIM(name) AS name, 
	LOWER(TRIM(email)) AS email, 
	TRIM(REGEXP_REPLACE(phone, '[^0-9]', '', 'g')) AS phone,
	signup_ts::TIMESTAMP AS signup_timestamp, 
	INITCAP(TRIM(city))
FROM raw.raw_users 
WHERE name IS NOT NULL AND email IS NOT NULL;

INSERT INTO stg.stg_riders(
	rider_id, 
	name, 
	vehicle_type, 
	hire_date, 
	city 
)

SELECT 
	rider_id,
	TRIM(name), 
	INITCAP(TRIM(vehicle_type)),
	hire_date, 
	INITCAP(TRIM(city))
FROM raw.raw_riders 
WHERE name IS NOT NULL AND vehicle_type IS NOT NULL; 

INSERT INTO stg.stg_orders(
	order_id, 
	user_id, 
	rider_id, 
	order_datetime, 
	pickup_datetime,
	dropoff_datetime,
	pickup_address,
	dropoff_address,
	order_status, 
	delivery_type
)

SELECT 
	o.order_id, 
	o.user_id,
	o.rider_id, 
	o.order_datetime::TIMESTAMP, 
	o.pickup_datetime,
	o.dropoff_datetime,
	TRIM(o.pickup_address),
	TRIM(o.dropoff_address),
	LOWER(o.status) AS order_status, 
	LOWER(o.delivery_type) AS delivery_type
FROM raw.raw_orders o 
JOIN stg.stg_users u
ON o.user_id = u.user_id 
JOIN stg.stg_riders r 
ON o.rider_id = r.rider_id 
WHERE LOWER(o.order_status) IN ('delivered', 'cancelled')
AND LOWER(o.delivery_type) IN ('express', 'standard'); 

SELECT COUNT(*) AS raw_orders_count 
FROM raw.raw_orders; 

SELECT COUNT(*) AS stg_orders_count 
FROM stg.stg_orders;

SELECT * 
FROM raw.raw_orders o 
WHERE o.user_id NOT IN (
	SELECT user_id 
	FROM stg.stg_users )
	OR o.rider_id NOT IN (
	SELECT rider_id 
	FROM stg.stg_riders 
	);

INSERT INTO stg.stg_products(
	product_id, 
	product_name, 
	category, 
	restaurant_id, 
	restaurant_name 
)

SELECT 
	product_id, 
	TRIM(product_name) AS product_name,
	CASE 
        WHEN LOWER(TRIM(category)) IN ('fast food', 'fastfood', 'fast-food') THEN 'fast_food'
        WHEN LOWER(TRIM(category)) IN ('desserts', 'dessert') THEN 'desserts'
        WHEN LOWER(TRIM(category)) IN ('drinks', 'beverages') THEN 'drinks'
        ELSE 'other'
    END AS category,
	restaurant_id, 
	TRIM(restaurant_name) AS restaurant_name 
FROM raw.raw_products 
WHERE product_name IS NOT NULL AND category IS NOT NULL; 

INSERT INTO stg.stg_payments(
	payment_id, 
	order_id, 
	payment_datetime, 
	amount, 
	method, 
	payment_status 
)

SELECT 
	payment_id, 
	order_id, 
	payment_datetime, 
	amount, 
	LOWER(method), 
	LOWER(payment_status)
FROM raw.raw_payments p
JOIN stg.stg_orders o 
ON p.order_id = o.order_id 
WHERE amount >= 0 AND 
LOWER(method) IN ('cash', 'card', 'e-wallet') AND 
LOWER(payment_status) IN ('paid', 'failed');
	

	




