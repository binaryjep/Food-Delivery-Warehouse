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