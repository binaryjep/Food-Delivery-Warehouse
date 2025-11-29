# Data Modelling Explanation

## Schema Model
We use a **Star Schema**, which provides:
- Fast aggregations
- Easy-to-understand structure
- Clear separation of dimensions and facts

### Dimensions
- dim_users
- dim_riders
- dim_products
- dim_restaurants
- dim_date
- dim_payment_method

### Facts
- fact_orders
- fact_payments

The grain of each fact is:
- **fact_orders** → one row per order
- **fact_payments** → one row per payment transaction
