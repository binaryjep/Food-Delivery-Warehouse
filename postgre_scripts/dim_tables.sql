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
	city VARCHAR(50),
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
	city 
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
	d AS full_Date, 
	EXTRACT(YEAR FROM d), 
	EXTRACT(MONTH FROM d), 
	EXTRACT(DAY FROM d), 
	EXTRACT(DOW FROM d), 
	EXTRACT(WEEK FROM d)

FROM (

	SELECT order_datetime::date AS d FROM stg.stg_orders 
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

CREATE TABLE dw.fact_orders (
	
	order_sk SERIAL PRIMARY KEY,
	
	-- Foreign keys to dimensions 
	user_sk INT NOT NULL, 
	rider_sk INT NOT NULL,
	restaurant_sk INT NOT NULL,
	order_date_sk INT NOT NULL, 
	pickup_date_sk INT, 
	dropoff_date_sk INT, 

	payment_method_sk INT, 

	-- Order attributes 
	delivery_type VARCHAR(20), 
	order_status VARCHAR(20),

	-- Measures / Metrics 
	delivery_time_minutes NUMERIC(10,2), 
	order_amount NUMERIC(10,2),

	order_count INT DEFAULT 1,

	-- Constraints FKs 
	CONSTRAINT fk_user_sk FOREIGN KEY (user_sk) REFERENCES dw.dim_users(users_sk),
	CONSTRAINT fk_rider_sk FOREIGN KEY (rider_sk) REFERENCES dw.dim_riders(rider_sk),  
	CONSTRAINT fk_restaurant_sk FOREIGN KEY (restaurant_sk) REFERENCES dw.dim_restaurants(restaurant_sk), 
	CONSTRAINT fk_order_date_sk FOREIGN KEY (order_date_sk) REFERENCES dw.dim_date(date_id),
	CONSTRAINT fk_pickup_date_sk FOREIGN KEY (pickup_date_sk) REFERENCES dw.dim_date(date_id), 
	CONSTRAINT fk_dropoff_date_sk FOREIGN KEY (dropoff_date_sk) REFERENCES dw.dim_date(date_id),
	CONSTRAINT fk_method_sk FOREIGN KEY (payment_method_sk) REFERENCES dw.dim_payment_method(method_sk)
); 

CREATE TABLE dw.fact_payments (

	payment_sk SERIAL PRIMARY KEY, 

	-- Business key 
	payment_id INT NOT NULL UNIQUE, 
	order_id INT NOT NULL, 

	-- Foreign keys 
	order_sk INT NOT NULL, 
	user_sk INT NOT NULL,
	payment_date_sk INT NOT NULL, 
	method_sk INT NOT NULL,

	-- Metrics 
	amount NUMERIC(10,2) NOT NULL,
	payment_status VARCHAR(20), 
	payment_count INT DEFAULT 1,

	-- Constraints FKs
	CONSTRAINT fk_factpay_order_sk FOREIGN KEY (order_sk) REFERENCES dw.fact_orders(order_sk),
	CONSTRAINT fk_factpay_user_sk FOREIGN KEY (user_sk) REFERENCES dw.dim_users(users_sk), 
	CONSTRAINT fk_factpay_date_sk FOREIGN KEY (payment_date_sk) REFERENCES dw.dim_date(date_id), 
	CONSTRAINT fk_factpay_method_sk FOREIGN KEY (method_sk) REFERENCES dw.dim_payment_method(method_sk)
);

-- ===========================================================
-- FACT ORDERS: Load from staging + dimension lookups
-- ===========================================================

INSERT INTO dw.fact_orders (
    order_id,
    user_sk,
    rider_sk,
    order_date_sk,
    delivery_date_sk,
    restaurant_sk,
    order_status,
    delivery_type,
    order_amount,
    delivery_duration_minutes,
    order_count
)
SELECT
    o.order_id,

    -- DIM REFERENCES
    du.users_sk AS user_sk,
    dr.rider_sk AS rider_sk,
    d_order.date_id AS order_date_sk,
    d_delivery.date_id AS delivery_date_sk,
    rest.restaurant_sk AS restaurant_sk,

    -- ORDER ATTRIBUTES
    o.order_status,
    o.delivery_type,

    -- COMPUTED ORDER AMOUNT (SUM OF PAYMENTS)
    COALESCE(pay.total_amount, 0) AS order_amount,

    -- DELIVERY DURATION IN MINUTES
    EXTRACT(EPOCH FROM (o.dropoff_datetime - o.pickup_datetime)) / 60 AS delivery_duration_minutes,

    -- For grain: 1 row per order
    1 AS order_count

FROM stg.stg_orders o

-- USER DIM LOOKUP
JOIN dw.dim_users du
    ON du.user_id = o.user_id

-- RIDER DIM LOOKUP
JOIN dw.dim_riders dr
    ON dr.rider_id = o.rider_id

-- DATE DIM LOOKUPS
JOIN dw.dim_date d_order
    ON d_order.full_date = o.order_datetime::date

JOIN dw.dim_date d_delivery
    ON d_delivery.full_date = o.dropoff_datetime::date

-- RESTAURANT LOOKUP THROUGH PRODUCTS (if you have product → restaurant mapping)
LEFT JOIN dw.dim_restaurants rest
    ON rest.restaurant_id = (
        SELECT restaurant_id
        FROM stg.stg_products p
        WHERE p.product_id = p.product_id
        LIMIT 1
    )

-- PAYMENT TOTALS FOR THE ORDER
LEFT JOIN (
    SELECT 
        order_id,
        SUM(amount) AS total_amount
    FROM stg.stg_payments
    GROUP BY order_id
) AS pay
    ON pay.order_id = o.order_id;


INSERT INTO dw.fact_payments (
	payment_id,
	order_id, 
	order_sk, 
	user_sk, 
	payment_date_sk, 
	method_sk, 
	amount,
	payment_status, 
	payment_count
)

SELECT 
	p.payment_id, 
	p.order_id,
	fo.order_sk, 

	u.users_sk,
	d_pay.date_id AS payment_date_sk, 
	pm.method_sk, 

	p.amount, 
	p.payment_status,
	1 AS payment_count 

FROM stg.stg_payments p 
LEFT JOIN dw.fact_orders fo ON p.order_id = fo.order_id 
LEFT JOIN stg.stg_orders o ON p.order_id = o.order_id 
LEFT JOIN dw.dim_users u ON o.user_id = u.user_id 
LEFT JOIN dw.dim_date d_pay ON DATE(p.payment_datetime) = d_pay.full_date
LEFT JOIN dw.dim_payment_method pm ON LOWER(p.method) = LOWER(pm.method_name); 



