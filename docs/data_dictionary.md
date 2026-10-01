# Data Dictionary

## CUSTOMER

**Grain:** One row represents one customer.

| Column        | Description                             | Type      | Key |
| ------------- | --------------------------------------- | --------- | --- |
| customer_id   | Unique business identifier for customer | VARCHAR   | PK  |
| first_name    | Customer first name                     | VARCHAR   |     |
| last_name     | Customer last name                      | VARCHAR   |     |
| date_of_birth | Customer date of birth                  | DATE      |     |
| email         | Customer email address                  | VARCHAR   | PII |
| phone         | Customer phone number                   | VARCHAR   | PII |
| address       | Customer address                        | VARCHAR   | PII |
| city          | Customer city                           | VARCHAR   |     |
| state         | Customer state                          | VARCHAR   |     |
| customer_type | Customer classification                 | VARCHAR   |     |
| created_at    | Source record creation timestamp        | TIMESTAMP |     |
| updated_at    | Source record update timestamp          | TIMESTAMP |     |

---

## POLICY

**Grain:** One row represents one insurance policy.

| Column            | Description                     | Type      | Key |
| ----------------- | ------------------------------- | --------- | --- |
| policy_id         | Unique policy identifier        | VARCHAR   | PK  |
| customer_id       | Customer associated with policy | VARCHAR   | FK  |
| policy_type       | Type of insurance policy        | VARCHAR   |     |
| policy_status     | Current policy status           | VARCHAR   |     |
| policy_start_date | Policy effective date           | DATE      |     |
| policy_end_date   | Policy expiration date          | DATE      |     |
| premium_amount    | Policy premium                  | NUMBER    |     |
| coverage_amount   | Maximum coverage amount         | NUMBER    |     |
| agent_id          | Agent associated with policy    | VARCHAR   | FK  |
| created_at        | Source creation timestamp       | TIMESTAMP |     |
| updated_at        | Source update timestamp         | TIMESTAMP |     |

---

## CLAIM

**Grain:** One row represents one insurance claim.

| Column          | Description                    | Type      | Key |
| --------------- | ------------------------------ | --------- | --- |
| claim_id        | Unique claim identifier        | VARCHAR   | PK  |
| policy_id       | Policy associated with claim   | VARCHAR   | FK  |
| customer_id     | Customer associated with claim | VARCHAR   | FK  |
| claim_date      | Date claim was submitted       | DATE      |     |
| incident_date   | Date incident occurred         | DATE      |     |
| claim_type      | Type of claim                  | VARCHAR   |     |
| claim_status    | Current claim status           | VARCHAR   |     |
| claim_amount    | Amount requested in claim      | NUMBER    |     |
| approved_amount | Amount approved by insurer     | NUMBER    |     |
| settlement_date | Date claim was settled         | DATE      |     |
| created_at      | Source creation timestamp      | TIMESTAMP |     |
| updated_at      | Source update timestamp        | TIMESTAMP |     |

---

## PAYMENT

**Grain:** One row represents one payment transaction.

| Column         | Description                    | Type      | Key |
| -------------- | ------------------------------ | --------- | --- |
| payment_id     | Unique payment identifier      | VARCHAR   | PK  |
| claim_id       | Claim associated with payment  | VARCHAR   | FK  |
| policy_id      | Policy associated with payment | VARCHAR   | FK  |
| payment_date   | Payment transaction date       | DATE      |     |
| payment_amount | Amount paid                    | NUMBER    |     |
| payment_status | Payment status                 | VARCHAR   |     |
| payment_method | Payment method                 | VARCHAR   |     |
| created_at     | Source creation timestamp      | TIMESTAMP |     |
| updated_at     | Source update timestamp        | TIMESTAMP |     |

---

## AGENT

**Grain:** One row represents one insurance agent.

| Column       | Description               | Type      | Key |
| ------------ | ------------------------- | --------- | --- |
| agent_id     | Unique agent identifier   | VARCHAR   | PK  |
| agent_name   | Agent name                | VARCHAR   |     |
| agent_email  | Agent email address       | VARCHAR   | PII |
| branch       | Agent branch              | VARCHAR   |     |
| region       | Agent region              | VARCHAR   |     |
| agent_status | Current agent status      | VARCHAR   |     |
| created_at   | Source creation timestamp | TIMESTAMP |     |
| updated_at   | Source update timestamp   | TIMESTAMP |     |

---

# Warehouse Audit Columns

The RAW and downstream layers may contain operational metadata such as:

| Column          | Purpose                       |
| --------------- | ----------------------------- |
| source_file     | Identifies source file        |
| file_row_number | Identifies source row         |
| load_timestamp  | Identifies ingestion time     |
| load_batch_id   | Identifies pipeline execution |
| record_hash     | Supports change detection     |
| source_system   | Identifies originating system |

These fields support traceability, reconciliation, deduplication, and troubleshooting.
