{{ config(materialized='view') }}
SELECT *
FROM {{ source('insurance_staging', 'payment_staging') }}
WHERE UPPER(STAGING_STATUS) = 'VALID'
