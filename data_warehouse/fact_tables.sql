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

