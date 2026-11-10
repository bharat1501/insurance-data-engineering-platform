{{ config(materialized='view') }}
SELECT *
FROM {{ source('insurance_staging', 'claim_staging') }}
WHERE UPPER(STAGING_STATUS) = 'VALID'
