USE DATABASE INSURANCE_DB;
USE SCHEMA STAGING;

CREATE TABLE IF NOT EXISTS PAYMENT_STAGING (
    -- Payment business attributes
    PAYMENT_ID          VARCHAR,
    CLAIM_ID            VARCHAR,
    POLICY_ID           VARCHAR,
    PAYMENT_AMOUNT      NUMBER(18,2),
    PAYMENT_DATE        DATE,
    PAYMENT_METHOD      VARCHAR,
    PAYMENT_STATUS      VARCHAR,

    -- Payment timestamps
    CREATED_AT          TIMESTAMP_NTZ,
    UPDATED_AT          TIMESTAMP_NTZ,

    -- Original JSON payload
    RAW_PAYLOAD         VARIANT,

    -- Source metadata
    SOURCE_FILE         VARCHAR,
    FILE_ROW_NUMBER     NUMBER(38,0),
    LOAD_TIMESTAMP      TIMESTAMP_NTZ,
    LOAD_BATCH_ID       VARCHAR,
    SOURCE_SYSTEM       VARCHAR,
    RECORD_HASH         VARCHAR,

    -- Staging validation
    STAGING_STATUS      VARCHAR,
    VALIDATION_REASON   VARCHAR
);
