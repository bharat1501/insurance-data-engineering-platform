USE DATABASE INSURANCE_DB;
USE SCHEMA RAW;

CREATE OR REPLACE PROCEDURE SP_LOAD_CLAIMS(
    P_BATCH_ID VARCHAR,
    P_SOURCE_FILE VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE

    ----------------------------------------------------------------
    -- Execution identifiers
    ----------------------------------------------------------------

    V_RUN_ID                    VARCHAR;
    V_AUDIT_ID                  VARCHAR;

    ----------------------------------------------------------------
    -- Source file
    ----------------------------------------------------------------

    V_SOURCE_FILE_PATH          VARCHAR;
    V_COPY_SQL                  VARCHAR;

    ----------------------------------------------------------------
    -- Idempotency
    ----------------------------------------------------------------

    V_EXISTING_SUCCESS_COUNT   NUMBER DEFAULT 0;

    ----------------------------------------------------------------
    -- COPY result
    ----------------------------------------------------------------

    V_COPY_QUERY_ID             VARCHAR;
    V_COPY_STATUS               VARCHAR;

    V_ROWS_PARSED               NUMBER DEFAULT 0;
    V_ROWS_LOADED               NUMBER DEFAULT 0;
    V_ERRORS_SEEN               NUMBER DEFAULT 0;
    V_REJECTED_COUNT            NUMBER DEFAULT 0;

    V_FIRST_ERROR               VARCHAR;

    ----------------------------------------------------------------
    -- Audit / timing
    ----------------------------------------------------------------

    V_START_TIME                TIMESTAMP_NTZ;
    V_END_TIME                  TIMESTAMP_NTZ;

    ----------------------------------------------------------------
    -- Error handling
    ----------------------------------------------------------------

    V_ERROR_CODE                VARCHAR;
    V_ERROR_STATE               VARCHAR;
    V_ERROR_MESSAGE             VARCHAR;

BEGIN

    ----------------------------------------------------------------
    -- 1. Generate execution identifiers
    ----------------------------------------------------------------

    V_RUN_ID :=
        'RUN_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDDHH24MISSFF3'
        );

    V_AUDIT_ID :=
        'AUDIT_' ||
        TO_VARCHAR(
            CURRENT_TIMESTAMP(),
            'YYYYMMDDHH24MISSFF3'
        );

    V_START_TIME := CURRENT_TIMESTAMP();


    ----------------------------------------------------------------
    -- 2. Build source file path
    ----------------------------------------------------------------

    V_SOURCE_FILE_PATH :=
        'claims/incoming/' || P_SOURCE_FILE;


    ----------------------------------------------------------------
    -- 3. Create initial pipeline audit record
    ----------------------------------------------------------------

    INSERT INTO INSURANCE_DB.AUDIT.PIPELINE_RUN
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
    -- 4. Application-level idempotency check
    --
    -- If the same batch + file has already completed successfully,
    -- do not execute COPY again.
    ----------------------------------------------------------------

    SELECT COUNT(*)
    INTO :V_EXISTING_SUCCESS_COUNT
    FROM INSURANCE_DB.AUDIT.PIPELINE_RUN
    WHERE LOAD_BATCH_ID = :P_BATCH_ID
      AND SOURCE_FILE = :P_SOURCE_FILE
      AND STATUS = 'SUCCESS';


    IF (V_EXISTING_SUCCESS_COUNT > 0) THEN

        V_END_TIME := CURRENT_TIMESTAMP();

        V_ERROR_MESSAGE :=
            'Batch/file already processed successfully';


        UPDATE INSURANCE_DB.AUDIT.PIPELINE_RUN
        SET
            PIPELINE_END_TIME = :V_END_TIME,
            STATUS = 'SKIPPED',
            ERROR_MESSAGE = :V_ERROR_MESSAGE
        WHERE RUN_ID = :V_RUN_ID;


        RETURN
            'SKIPPED | ALREADY_PROCESSED' ||
            ' | BATCH_ID=' || P_BATCH_ID ||
            ' | FILE=' || P_SOURCE_FILE;

    END IF;


    ----------------------------------------------------------------
    -- 5. Build dynamic COPY statement
    ----------------------------------------------------------------

    V_COPY_SQL :=
        'COPY INTO INSURANCE_DB.RAW.CLAIM_RAW ' ||

        'FROM (' ||

        'SELECT ' ||
            '$1, ' ||
            '$2, ' ||
            '$3, ' ||
            '$4, ' ||
            '$5, ' ||
            '$6, ' ||
            '$7, ' ||
            '$8, ' ||
            '$9, ' ||
            '$10, ' ||
            '$11, ' ||
            '$12, ' ||

            'METADATA$FILENAME, ' ||
            'METADATA$FILE_ROW_NUMBER, ' ||
            'CURRENT_TIMESTAMP(), ' ||

            '''' ||
            REPLACE(:P_BATCH_ID, '''', '''''') ||
            ''', ' ||

            '''INSURANCE_CLAIMS_SOURCE'', ' ||

            'NULL ' ||

        'FROM @INSURANCE_DB.RAW.CLAIMS_S3_STAGE ' ||

        ') ' ||

        'FILES = (''' ||
        REPLACE(:P_SOURCE_FILE, '''', '''''') ||
        ''') ' ||

        'FILE_FORMAT = (' ||
        'FORMAT_NAME = ''INSURANCE_DB.RAW.CLAIMS_CSV_FORMAT''' ||
        ') ' ||

        'ON_ERROR = ''CONTINUE''';


    ----------------------------------------------------------------
    -- 6. Execute COPY
    ----------------------------------------------------------------

    EXECUTE IMMEDIATE :V_COPY_SQL;


    ----------------------------------------------------------------
    -- 7. Capture COPY query ID
    ----------------------------------------------------------------

    V_COPY_QUERY_ID := SQLID;


    ----------------------------------------------------------------
    -- 8. Read COPY result
    --
    -- $1 = FILE
    -- $2 = STATUS
    -- $3 = ROWS_PARSED
    -- $4 = ROWS_LOADED
    -- $5 = ERROR_LIMIT
    -- $6 = ERRORS_SEEN
    -- $7 = FIRST_ERROR
    ----------------------------------------------------------------

    SELECT
        COALESCE(SUM($3), 0),
        COALESCE(SUM($4), 0),
        COALESCE(SUM($6), 0),
        MAX($2),
        MAX($7)
    INTO
        :V_ROWS_PARSED,
        :V_ROWS_LOADED,
        :V_ERRORS_SEEN,
        :V_COPY_STATUS,
        :V_FIRST_ERROR
    FROM TABLE(
        RESULT_SCAN(:V_COPY_QUERY_ID)
    );


    ----------------------------------------------------------------
    -- 9. Calculate rejected records
    ----------------------------------------------------------------

    V_REJECTED_COUNT :=
        GREATEST(
            V_ROWS_PARSED - V_ROWS_LOADED,
            0
        );


    ----------------------------------------------------------------
    -- 10. Handle Snowflake COPY-level idempotency
    --
    -- This is a secondary protection.
    -- Snowflake may return LOAD_SKIPPED when it recognizes that
    -- the file was previously loaded.
    ----------------------------------------------------------------

    IF (
        COALESCE(V_COPY_STATUS, '') = 'LOAD_SKIPPED'
    ) THEN

        V_END_TIME := CURRENT_TIMESTAMP();

        V_ERROR_MESSAGE :=
            'Snowflake skipped file because it was already loaded';


        UPDATE INSURANCE_DB.AUDIT.PIPELINE_RUN
        SET
            PIPELINE_END_TIME = :V_END_TIME,
            SOURCE_RECORD_COUNT = 0,
            LOADED_RECORD_COUNT = 0,
            REJECTED_RECORD_COUNT = 0,
            STATUS = 'SKIPPED',
            ERROR_MESSAGE = :V_ERROR_MESSAGE
        WHERE RUN_ID = :V_RUN_ID;


        RETURN
            'SKIPPED | SNOWFLAKE_FILE_ALREADY_LOADED' ||
            ' | BATCH_ID=' || P_BATCH_ID ||
            ' | FILE=' || P_SOURCE_FILE;

    END IF;


    ----------------------------------------------------------------
    -- 11. Populate RECORD_HASH
    ----------------------------------------------------------------

    UPDATE INSURANCE_DB.RAW.CLAIM_RAW
    SET RECORD_HASH =
        SHA2(
            CONCAT_WS(
                '|',
                COALESCE(CLAIM_ID, '<NULL>'),
                COALESCE(POLICY_ID, '<NULL>'),
                COALESCE(CUSTOMER_ID, '<NULL>'),
                COALESCE(CLAIM_DATE, '<NULL>'),
                COALESCE(INCIDENT_DATE, '<NULL>'),
                COALESCE(CLAIM_TYPE, '<NULL>'),
                COALESCE(CLAIM_STATUS, '<NULL>'),
                COALESCE(CLAIM_AMOUNT, '<NULL>'),
                COALESCE(APPROVED_AMOUNT, '<NULL>'),
                COALESCE(SETTLEMENT_DATE, '<NULL>'),
                COALESCE(CREATED_AT, '<NULL>'),
                COALESCE(UPDATED_AT, '<NULL>')
            ),
            256
        )
    WHERE LOAD_BATCH_ID = :P_BATCH_ID
      AND SOURCE_FILE = :V_SOURCE_FILE_PATH
      AND RECORD_HASH IS NULL;


    ----------------------------------------------------------------
    -- 12. Capture end time
    ----------------------------------------------------------------

    V_END_TIME := CURRENT_TIMESTAMP();


    ----------------------------------------------------------------
    -- 13. Determine final status
    --
    -- SUCCESS requires:
    --   - rows parsed > 0
    --   - all parsed rows loaded
    --   - zero COPY errors
    ----------------------------------------------------------------

    IF (
        V_ROWS_PARSED > 0
        AND V_ROWS_PARSED = V_ROWS_LOADED
        AND V_ERRORS_SEEN = 0
    ) THEN


        ----------------------------------------------------------------
        -- 14. Update pipeline audit
        ----------------------------------------------------------------

        UPDATE INSURANCE_DB.AUDIT.PIPELINE_RUN
        SET
            PIPELINE_END_TIME = :V_END_TIME,
            SOURCE_RECORD_COUNT = :V_ROWS_PARSED,
            LOADED_RECORD_COUNT = :V_ROWS_LOADED,
            REJECTED_RECORD_COUNT = :V_REJECTED_COUNT,
            STATUS = 'SUCCESS',
            ERROR_MESSAGE = NULL
        WHERE RUN_ID = :V_RUN_ID;


        ----------------------------------------------------------------
        -- 15. Insert file-level audit
        ----------------------------------------------------------------

        INSERT INTO INSURANCE_DB.AUDIT.DATA_LOAD_AUDIT
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
                || :V_SOURCE_FILE_PATH,
            :P_BATCH_ID,
            :V_ROWS_PARSED,
            :V_ROWS_LOADED,
            :V_REJECTED_COUNT,
            0,
            :V_START_TIME,
            :V_END_TIME,
            'SUCCESS',
            NULL
        );


        RETURN
            'SUCCESS | RUN_ID=' || V_RUN_ID ||
            ' | FILE=' || P_SOURCE_FILE ||
            ' | PARSED=' || V_ROWS_PARSED ||
            ' | LOADED=' || V_ROWS_LOADED ||
            ' | REJECTED=' || V_REJECTED_COUNT;


    ELSE


        ----------------------------------------------------------------
        -- 16. Failed / partial load
        ----------------------------------------------------------------

        V_ERROR_MESSAGE :=
            'COPY failed or reconciliation failed. ' ||
            'STATUS=' ||
            COALESCE(V_COPY_STATUS, 'UNKNOWN') ||
            ' | PARSED=' ||
            V_ROWS_PARSED ||
            ' | LOADED=' ||
            V_ROWS_LOADED ||
            ' | REJECTED=' ||
            V_REJECTED_COUNT ||
            ' | ERRORS_SEEN=' ||
            V_ERRORS_SEEN ||
            ' | FIRST_ERROR=' ||
            COALESCE(V_FIRST_ERROR, 'NONE');


        UPDATE INSURANCE_DB.AUDIT.PIPELINE_RUN
        SET
            PIPELINE_END_TIME = :V_END_TIME,
            SOURCE_RECORD_COUNT = :V_ROWS_PARSED,
            LOADED_RECORD_COUNT = :V_ROWS_LOADED,
            REJECTED_RECORD_COUNT = :V_REJECTED_COUNT,
            STATUS = 'FAILED',
            ERROR_MESSAGE = :V_ERROR_MESSAGE
        WHERE RUN_ID = :V_RUN_ID;


        INSERT INTO INSURANCE_DB.AUDIT.DATA_LOAD_AUDIT
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
                || :V_SOURCE_FILE_PATH,
            :P_BATCH_ID,
            :V_ROWS_PARSED,
            :V_ROWS_LOADED,
            :V_REJECTED_COUNT,
            0,
            :V_START_TIME,
            :V_END_TIME,
            'FAILED',
            :V_ERROR_MESSAGE
        );


        RETURN
            'FAILED | RUN_ID=' || V_RUN_ID ||
            ' | FILE=' || P_SOURCE_FILE ||
            ' | PARSED=' || V_ROWS_PARSED ||
            ' | LOADED=' || V_ROWS_LOADED ||
            ' | REJECTED=' || V_REJECTED_COUNT;

    END IF;


----------------------------------------------------------------
-- 17. Exception handling
----------------------------------------------------------------

EXCEPTION

    WHEN OTHER THEN

        V_END_TIME := CURRENT_TIMESTAMP();

        V_ERROR_CODE := SQLCODE;
        V_ERROR_STATE := SQLSTATE;
        V_ERROR_MESSAGE := SQLERRM;


        UPDATE INSURANCE_DB.AUDIT.PIPELINE_RUN
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
