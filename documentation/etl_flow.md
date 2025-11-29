# ETL Flow Explained

## 1. Raw Layer
Stores unprocessed CSV-like tables representing source system extracts.

## 2. Staging Layer
- Remove duplicates  
- Standardize formats (lowercase, trim, date casting)
- Validate foreign key relationships
- Clean categorical values

## 3. Dimensional Warehouse
- Insert surrogate keys into dimensions
- Populate fact tables with lookups

## 4. Data Marts
- Orders summary mart  
- Rider performance mart  
- Payment summary mart  
