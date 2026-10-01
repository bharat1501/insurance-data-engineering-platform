# Insurance Source Data Generator

This module simulates source-system data for the Insurance Data Engineering Platform.

## Current Generator

### Claims

`claims_generator.py`

Generates synthetic insurance claim records in CSV format.

Current version generates:

- Claim ID
- Policy ID
- Customer ID
- Claim date
- Incident date
- Claim type
- Claim status
- Claim amount
- Approved amount
- Settlement date
- Created timestamp
- Updated timestamp

## Reproducibility

The generator currently uses a fixed random seed so that test data can be reproduced consistently.

## Planned Data Quality Scenarios

Future versions will intentionally generate:

- Duplicate records
- NULL values
- Invalid dates
- Negative claim amounts
- Invalid claim statuses
- Customer/policy mismatches
- Duplicate files
- Late-arriving claims
- Out-of-order updates
- Schema evolution
