# Insurance Data Engineering Platform

A production-style end-to-end data engineering project simulating an insurance company's data platform.

## Objective

Build a reliable analytical data platform for customer, policy, claims, and payment data using modern data engineering practices.

## Technology Stack

* Python
* AWS S3
* Snowflake
* SQL
* dbt
* Apache Airflow
* GitHub Actions
* Power BI

## Architecture

The platform will progressively implement:

```text
Source Systems
      ↓
Python Data Generation
      ↓
AWS S3
      ↓
Snowflake RAW
      ↓
STAGING
      ↓
CURATED
      ↓
GOLD / Analytics
      ↓
Power BI
```

## Production Scenarios

The project will simulate and handle:

* Duplicate files
* Duplicate records
* Schema evolution
* Late-arriving data
* CDC
* Data quality failures
* Invalid records
* Pipeline failures
* Backfills
* Audit logging
* PII protection
* Performance optimization
* CI/CD

## Project Status

Phase 1 — Business Requirements & Architecture

* [x] Business requirements
* [ ] Data model
* [ ] Architecture
* [ ] Source data contracts
* [ ] Python data generator
* [ ] AWS S3 ingestion
* [ ] Snowflake ingestion
* [ ] dbt transformations
* [ ] CDC
* [ ] Airflow orchestration
* [ ] Data quality framework
* [ ] CI/CD
* [ ] Production incident simulations
* [ ] Power BI analytics
