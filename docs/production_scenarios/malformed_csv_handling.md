# Production Scenario: Malformed CSV Handling

## Objective

Validate how Snowflake handles malformed CSV records during S3-to-Snowflake ingestion, and distinguish file parsing errors from business data quality errors.

## Test Setup

- Source: AWS S3
- File: `claims_malformed_20261016.csv`
- Expected source columns: 12
- Deliberate issue: one data row contains an extra field
- Snowflake test table: `INSURANCE_DB.RAW.CLAIM_CSV_PARSE_TEST`
- File format: `INSURANCE_DB.RAW.CLAIMS_CSV_STRICT_FORMAT`

## Test Results

The strict file-format validation identified a CSV parsing error. The actual `COPY INTO` test with `ON_ERROR = 'CONTINUE'` returned:

| Metric | Result |
|---|---:|
| Rows parsed | 3 |
| Rows loaded | 2 |
| Errors seen | 1 |
| COPY status | `PARTIALLY_LOADED` |

The two valid records, `CLM_TEST_001` and `CLM_TEST_003`, loaded successfully. The malformed record, `CLM_TEST_002`, was not inserted into the test table.

## Production Lessons

1. A successful SQL execution does not necessarily mean every source record was loaded.
2. `ON_ERROR = 'CONTINUE'` allows valid records to load while parsing errors are encountered.
3. File-level load status and record-level data quality status are different concerns.
4. Reconciliation must compare parsed, loaded, and rejected counts.
5. Parsing errors should be associated with the source file and pipeline run.
6. Reprocessing must not duplicate previously loaded records.
7. Validation-only tests should be performed before modifying production data.

## Follow-up Work

- Integrate parsing-error handling into `SP_LOAD_CLAIMS`.
- Persist rejected-row details and parsing diagnostics where available.
- Ensure audit records accurately reflect partial loads.
- Test retries and recovery using a new file or controlled test batch.
- Define whether partial loads are accepted, quarantined, or treated as failed according to business requirements.

## Scope Note

This was a controlled test using a dedicated Snowflake test table. The production ingestion procedure has not yet been proven to handle this exact malformed-file scenario.

