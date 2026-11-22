SELECT
    CUSTOMER_ID,
    DBT_SCD_ID,
    COUNT(*) AS RECORD_COUNT
FROM {{ source('insurance_curated', 'snap_customer') }}
GROUP BY CUSTOMER_ID, DBT_SCD_ID
HAVING COUNT(*) > 1
