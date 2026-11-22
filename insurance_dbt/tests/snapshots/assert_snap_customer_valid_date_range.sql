SELECT *
FROM {{ source('insurance_curated', 'snap_customer') }}
WHERE DBT_VALID_TO IS NOT NULL
  AND DBT_VALID_TO <= DBT_VALID_FROM
