USE DATABASE INSURANCE_DB;
USE SCHEMA STAGING;

CREATE TABLE CUSTOMER_STAGING (
    -- Business attributes
    CUSTOMER_ID         VARCHAR,
    FIRST_NAME          VARCHAR,
    LAST_NAME           VARCHAR,
    DATE_OF_BIRTH       DATE,
    EMAIL               VARCHAR,
    PHONE               VARCHAR,
    ADDRESS             VARCHAR,
    CITY                VARCHAR,
    STATE               VARCHAR,
    CUSTOMER_TYPE       VARCHAR,

    -- Source timestamps
    CREATED_AT          TIMESTAMP_NTZ,
    UPDATED_AT          TIMESTAMP_NTZ,

    -- Source metadata
    SOURCE_FILE         VARCHAR,
    FILE_ROW_NUMBER     NUMBER(38,0),
    LOAD_TIMESTAMP      TIMESTAMP_NTZ,
    LOAD_BATCH_ID       VARCHAR,
    SOURCE_SYSTEM       VARCHAR,
    RECORD_HASH         VARCHAR,

    -- Staging validation fields
    STAGING_STATUS      VARCHAR,
    VALIDATION_REASON   VARCHAR
);
