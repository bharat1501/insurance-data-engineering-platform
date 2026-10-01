# Data Architecture

## 1. High-Level Architecture

```text
                    SOURCE SYSTEMS
                         |
        +----------------+----------------+
        |                |                |
     Customer          Policy           Claims
      System           System           System
        |                |                |
        +----------------+----------------+
                         |
                    Python Generator
                         |
                         ▼
                    AWS S3
                  Raw File Zone
                         |
                         ▼
                 Snowflake RAW
                         |
                         ▼
                    STAGING
                         |
                         ▼
                    CURATED
                         |
                         ▼
                  GOLD / MARTS
                         |
                         ▼
                    Power BI
```

## 2. Data Layers

### RAW

Purpose:

* Preserve source data as received.
* Maintain source-level traceability.
* Capture ingestion metadata.
* Support reprocessing.

### STAGING

Purpose:

* Standardize data types.
* Normalize column names.
* Perform basic cleansing.
* Prepare source data for business transformations.

### CURATED

Purpose:

* Apply business rules.
* Remove duplicates.
* Process CDC.
* Maintain trusted business entities.
* Implement historical processing.

### GOLD

Purpose:

* Provide analytics-ready dimensional models.
* Support reporting and BI.
* Optimize datasets for analytical queries.

## 3. Core Entities

```text
CUSTOMER
    |
    +---- POLICY
              |
              +---- CLAIM
                       |
                       +---- PAYMENT

AGENT
    |
    +---- POLICY
```

## 4. Historical Strategy

Customer, Policy, and Agent dimensions will use SCD Type 2 where historical tracking is required.

Claims will support change tracking through CDC and preserve relevant claim history.

Payments will be treated as transactional events.

## 5. Operational Metadata

The ingestion framework will capture:

* Source file
* Source row number
* Load timestamp
* Pipeline run ID
* Source system
* Record hash

This metadata will support data lineage, troubleshooting, reconciliation, and duplicate detection.

## 6. Production Design Principles

The platform will be designed around:

* Idempotency
* Incremental processing
* Fault tolerance
* Data quality
* Observability
* Auditability
* Security
* Reproducibility
* Automated testing
* CI/CD
