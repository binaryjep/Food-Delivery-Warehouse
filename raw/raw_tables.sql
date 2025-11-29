CREATE SCHEMA raw;

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