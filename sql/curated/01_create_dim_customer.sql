USE DATABASE INSURANCE_DB;
USE SCHEMA CURATED;

CREATE TABLE IF NOT EXISTS DIM_CUSTOMER (
    -- Surrogate and business keys
    CUSTOMER_SK         NUMBER(38,0) AUTOINCREMENT START 1 INCREMENT 1,
    CUSTOMER_ID         VARCHAR NOT NULL,

    -- Customer business attributes
    FIRST_NAME          VARCHAR,
    LAST_NAME           VARCHAR,
    DATE_OF_BIRTH       DATE,
    EMAIL               VARCHAR,
    PHONE               VARCHAR,
    ADDRESS             VARCHAR,
    CITY                VARCHAR,
    STATE               VARCHAR,
    CUSTOMER_TYPE       VARCHAR,

    -- SCD Type 2 attributes
    EFFECTIVE_FROM      TIMESTAMP_NTZ NOT NULL,
    EFFECTIVE_TO        TIMESTAMP_NTZ NOT NULL,
    IS_CURRENT          BOOLEAN NOT NULL,

    -- Change detection
    ATTRIBUTE_HASH      VARCHAR,
    RECORD_HASH         VARCHAR,

    -- Source lineage
    SOURCE_FILE         VARCHAR,
    FILE_ROW_NUMBER     NUMBER(38,0),
    LOAD_BATCH_ID       VARCHAR,
    SOURCE_SYSTEM       VARCHAR,

    -- Audit columns
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
