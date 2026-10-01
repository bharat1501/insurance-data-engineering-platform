-- ============================================================
-- Insurance Data Engineering Platform
-- RAW Claims Table
-- ============================================================

USE DATABASE INSURANCE_DB;
USE SCHEMA RAW;

CREATE TABLE IF NOT EXISTS CLAIM_RAW
(
    -- ========================================================
    -- Source Business Columns
    -- ========================================================

    CLAIM_ID            VARCHAR,
    POLICY_ID           VARCHAR,
    CUSTOMER_ID         VARCHAR,

    CLAIM_DATE          VARCHAR,
    INCIDENT_DATE       VARCHAR,

    CLAIM_TYPE          VARCHAR,
    CLAIM_STATUS        VARCHAR,

    CLAIM_AMOUNT        VARCHAR,
    APPROVED_AMOUNT     VARCHAR,

    SETTLEMENT_DATE     VARCHAR,

    CREATED_AT          VARCHAR,
    UPDATED_AT          VARCHAR,


    -- ========================================================
    -- Ingestion Metadata
    -- ========================================================

    SOURCE_FILE         VARCHAR,
    FILE_ROW_NUMBER     NUMBER,

    LOAD_TIMESTAMP      TIMESTAMP_NTZ,

    LOAD_BATCH_ID       VARCHAR,

    SOURCE_SYSTEM       VARCHAR,

    RECORD_HASH         VARCHAR
);
