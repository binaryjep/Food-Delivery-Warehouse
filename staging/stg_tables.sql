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