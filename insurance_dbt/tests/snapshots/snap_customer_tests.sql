
-- Test 1: No duplicate customer versions
SELECT
    CUSTOMER_ID,
    DBT_SCD_ID,
    COUNT(*) AS RECORD_COUNT
FROM {{ source('insurance_curated', 'snap_customer') }}
GROUP BY CUSTOMER_ID, DBT_SCD_ID
HAVING COUNT(*) > 1;


-- Test 2: Every customer has exactly one current version
SELECT
    CUSTOMER_ID,
    COUNT_IF(DBT_VALID_TO IS NULL) AS CURRENT_RECORD_COUNT
FROM {{ source('insurance_curated', 'snap_customer') }}
GROUP BY CUSTOMER_ID
HAVING COUNT_IF(DBT_VALID_TO IS NULL) <> 1;


-- Test 3: Historical records must have a valid end timestamp
SELECT *
FROM {{ source('insurance_curated', 'snap_customer') }}
WHERE DBT_VALID_TO IS NOT NULL
  AND DBT_VALID_TO <= DBT_VALID_FROM;

