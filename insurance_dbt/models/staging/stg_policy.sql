{{ config(materialized='view') }}
SELECT *
FROM {{ source('insurance_staging', 'policy_staging') }}
WHERE UPPER(STAGING_STATUS) = 'VALID'
