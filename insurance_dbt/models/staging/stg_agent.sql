{{ config(materialized='view') }}
SELECT *
FROM {{ source('insurance_staging', 'agent_staging') }}
WHERE UPPER(STAGING_STATUS) = 'VALID'
