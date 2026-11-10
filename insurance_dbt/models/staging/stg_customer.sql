{{
    config(
        materialized='view'
    )
}}

SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    DATE_OF_BIRTH,
    EMAIL,
    PHONE,
    ADDRESS,
    CITY,
    STATE,
    CUSTOMER_TYPE,
    CREATED_AT,
    UPDATED_AT,
    SOURCE_FILE,
    FILE_ROW_NUMBER,
    LOAD_TIMESTAMP,
    LOAD_BATCH_ID,
    SOURCE_SYSTEM,
    RECORD_HASH,
    STAGING_STATUS,
    VALIDATION_REASON

FROM {{ source('insurance_staging', 'customer_staging') }}

WHERE UPPER(STAGING_STATUS) = 'VALID'
