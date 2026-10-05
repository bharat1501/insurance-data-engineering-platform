USE DATABASE INSURANCE_DB;
USE SCHEMA AUDIT;

CREATE OR REPLACE PROCEDURE SP_AUDIT_CLAIMS_LOAD(
    P_BATCH_ID VARCHAR,
    P_SOURCE_FILE VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    V_RUN_ID                  VARCHAR;
    V_AUDIT_ID                VARCHAR;

    V_EXPECTED_SOURCE_FILE    VARCHAR;

    V_SOURCE_COUNT            NUMBER DEFAULT 0;
    V_LOADED_COUNT            NUMBER DEFAULT 0;
    V_REJECTED_COUNT          NUMBER DEFAULT 0;
    V_DUPLICATE_COUNT         NUMBER DEFAULT 0;

    V_START_TIME              TIMESTAMP_NTZ;
    V_END_TIME                TIMESTAMP_NTZ;

    V_ERROR_MESSAGE           VARCHAR;
    V_ERROR_CODE              VARCHAR;
    V_ERROR_STATE             VARCHAR;

BEGIN

    ----------------------------------------------------------------
    -- 1. Generate execution identifiers
    ----------------------------------------------------------------

    V_RUN_ID :=
        'RUN_' ||
        TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISSFF3');

    V_AUDIT_ID :=
        'AUDIT_' ||
        TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYYMMDDHH24MISSFF3');

    V_START_TIME := CURRENT_TIMESTAMP();


    ----------------------------------------------------------------
    -- 2. Build expected source file path
    ----------------------------------------------------------------

    V_EXPECTED_SOURCE_FILE :=
        'claims/incoming/' || P_SOURCE_FILE;


    ----------------------------------------------------------------
    -- 3. Create initial pipeline audit record
    ----------------------------------------------------------------

    INSERT INTO PIPELINE_RUN
    (
        RUN_ID,
        PIPELINE_NAME,
        SOURCE_SYSTEM,
        SOURCE_ENTITY,
        SOURCE_FILE,
        LOAD_BATCH_ID,
        PIPELINE_START_TIME,
        STATUS
    )
    VALUES
    (
        :V_RUN_ID,
        'CLAIMS_S3_TO_RAW',
        'INSURANCE_CLAIMS_SOURCE',
        'CLAIM',
        :P_SOURCE_FILE,
        :P_BATCH_ID,
        :V_START_TIME,
        'RUNNING'
    );


    ----------------------------------------------------------------
    -- 4. Validate that the expected batch/file exists in RAW
    ----------------------------------------------------------------

    SELECT COUNT(*)
    INTO :V_LOADED_COUNT
    FROM INSURANCE_DB.RAW.CLAIM_RAW
    WHERE LOAD_BATCH_ID = :P_BATCH_ID
      AND SOURCE_FILE = :V_EXPECTED_SOURCE_FILE;


    ----------------------------------------------------------------
    -- 5. Prevent false SUCCESS when no records were found
    ----------------------------------------------------------------

    IF (V_LOADED_COUNT = 0) THEN

        V_END_TIME := CURRENT_TIMESTAMP();

        V_ERROR_MESSAGE :=
            'No records found for batch=' || P_BATCH_ID ||
            ' and source_file=' || V_EXPECTED_SOURCE_FILE;


        UPDATE PIPELINE_RUN
        SET
            PIPELINE_END_TIME = :V_END_TIME,
            SOURCE_RECORD_COUNT = 0,
            LOADED_RECORD_COUNT = 0,
            REJECTED_RECORD_COUNT = 0,
            STATUS = 'FAILED',
            ERROR_MESSAGE = :V_ERROR_MESSAGE
        WHERE RUN_ID = :V_RUN_ID;


        INSERT INTO DATA_LOAD_AUDIT
        (
            AUDIT_ID,
            RUN_ID,
            SOURCE_SYSTEM,
            SOURCE_ENTITY,
            SOURCE_FILE,
            SOURCE_FILE_PATH,
            LOAD_BATCH_ID,
            FILE_RECORD_COUNT,
            LOADED_RECORD_COUNT,
            REJECTED_RECORD_COUNT,
            DUPLICATE_RECORD_COUNT,
            LOAD_START_TIME,
            LOAD_END_TIME,
            LOAD_STATUS,
            ERROR_MESSAGE
        )
        VALUES
        (
            :V_AUDIT_ID,
            :V_RUN_ID,
            'INSURANCE_CLAIMS_SOURCE',
            'CLAIM',
            :P_SOURCE_FILE,
            's3://insurance-data-engineering-platform-467f70cf/'
                || :V_EXPECTED_SOURCE_FILE,
            :P_BATCH_ID,
            0,
            0,
            0,
            0,
            :V_START_TIME,
            :V_END_TIME,
            'FAILED',
            :V_ERROR_MESSAGE
        );


        RETURN
            'FAILED | FILE_NOT_FOUND_OR_NOT_LOADED | RUN_ID=' ||
            V_RUN_ID ||
            ' | ERROR=' ||
            V_ERROR_MESSAGE;

    END IF;


    ----------------------------------------------------------------
    -- 6. Source count
    --
    -- TEMPORARY:
    -- Until we capture the actual S3/COPY source count,
    -- the RAW batch count represents the loaded source records.
    ----------------------------------------------------------------

    V_SOURCE_COUNT := V_LOADED_COUNT;


    ----------------------------------------------------------------
    -- 7. Reconciliation
    ----------------------------------------------------------------

    IF (
        V_SOURCE_COUNT =
        V_LOADED_COUNT + V_REJECTED_COUNT
    ) THEN

        V_END_TIME := CURRENT_TIMESTAMP();


        ----------------------------------------------------------------
        -- 8. Update pipeline audit
        ----------------------------------------------------------------

        UPDATE PIPELINE_RUN
        SET
            PIPELINE_END_TIME = :V_END_TIME,
            SOURCE_RECORD_COUNT = :V_SOURCE_COUNT,
            LOADED_RECORD_COUNT = :V_LOADED_COUNT,
            REJECTED_RECORD_COUNT = :V_REJECTED_COUNT,
            STATUS = 'SUCCESS',
            ERROR_MESSAGE = NULL
        WHERE RUN_ID = :V_RUN_ID;


        ----------------------------------------------------------------
        -- 9. Insert detailed file audit
        ----------------------------------------------------------------

        INSERT INTO DATA_LOAD_AUDIT
        (
            AUDIT_ID,
            RUN_ID,
            SOURCE_SYSTEM,
            SOURCE_ENTITY,
            SOURCE_FILE,
            SOURCE_FILE_PATH,
            LOAD_BATCH_ID,
            FILE_RECORD_COUNT,
            LOADED_RECORD_COUNT,
            REJECTED_RECORD_COUNT,
            DUPLICATE_RECORD_COUNT,
            LOAD_START_TIME,
            LOAD_END_TIME,
            LOAD_STATUS,
            ERROR_MESSAGE
        )
        VALUES
        (
            :V_AUDIT_ID,
            :V_RUN_ID,
            'INSURANCE_CLAIMS_SOURCE',
            'CLAIM',
            :P_SOURCE_FILE,
            's3://insurance-data-engineering-platform-467f70cf/'
                || :V_EXPECTED_SOURCE_FILE,
            :P_BATCH_ID,
            :V_SOURCE_COUNT,
            :V_LOADED_COUNT,
            :V_REJECTED_COUNT,
            :V_DUPLICATE_COUNT,
            :V_START_TIME,
            :V_END_TIME,
            'SUCCESS',
            NULL
        );


        ----------------------------------------------------------------
        -- 10. Return success
        ----------------------------------------------------------------

        RETURN
            'SUCCESS | RUN_ID=' || V_RUN_ID ||
            ' | SOURCE_COUNT=' || V_SOURCE_COUNT ||
            ' | LOADED=' || V_LOADED_COUNT ||
            ' | REJECTED=' || V_REJECTED_COUNT;


    ELSE

        ----------------------------------------------------------------
        -- 11. Reconciliation failure
        ----------------------------------------------------------------

        V_END_TIME := CURRENT_TIMESTAMP();

        V_ERROR_MESSAGE :=
            'Source and loaded record counts do not reconcile';


        UPDATE PIPELINE_RUN
        SET
            PIPELINE_END_TIME = :V_END_TIME,
            SOURCE_RECORD_COUNT = :V_SOURCE_COUNT,
            LOADED_RECORD_COUNT = :V_LOADED_COUNT,
            REJECTED_RECORD_COUNT = :V_REJECTED_COUNT,
            STATUS = 'FAILED',
            ERROR_MESSAGE = :V_ERROR_MESSAGE
        WHERE RUN_ID = :V_RUN_ID;


        RETURN
            'FAILED | RECONCILIATION_MISMATCH | RUN_ID=' ||
            V_RUN_ID;

    END IF;


----------------------------------------------------------------
-- 12. Exception handling
----------------------------------------------------------------

EXCEPTION

    WHEN OTHER THEN

        V_END_TIME := CURRENT_TIMESTAMP();

        V_ERROR_CODE := SQLCODE;
        V_ERROR_MESSAGE := SQLERRM;
        V_ERROR_STATE := SQLSTATE;


        UPDATE PIPELINE_RUN
        SET
            PIPELINE_END_TIME = :V_END_TIME,
            STATUS = 'FAILED',
            ERROR_MESSAGE =
                :V_ERROR_CODE || ' | ' ||
                :V_ERROR_STATE || ' | ' ||
                :V_ERROR_MESSAGE
        WHERE RUN_ID = :V_RUN_ID;


        RETURN
            'FAILED | RUN_ID=' || V_RUN_ID ||
            ' | SQLCODE=' || V_ERROR_CODE ||
            ' | SQLSTATE=' || V_ERROR_STATE ||
            ' | ERROR=' || V_ERROR_MESSAGE;

END;
$$;
