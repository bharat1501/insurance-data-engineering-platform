import argparse
import csv
import random
from datetime import datetime, timedelta
from pathlib import Path


# ============================================================
# Configuration
# ============================================================

OUTPUT_DIR = Path("data/generated/claims")

CLAIM_TYPES = [
    "AUTO",
    "HEALTH",
    "HOME",
    "TRAVEL",
    "LIFE",
]

CLAIM_STATUSES = [
    "SUBMITTED",
    "UNDER_REVIEW",
    "APPROVED",
    "REJECTED",
    "SETTLED",
]

INVALID_STATUSES = [
    "UNKNOWN",
    "INVALID_STATUS",
    "PENDING_X",
]


# ============================================================
# Helper Functions
# ============================================================

def generate_claim_date():
    """
    Generate a claim date within the last 30 days.
    """

    today = datetime.now().date()

    days_ago = random.randint(0, 30)

    return today - timedelta(days=days_ago)


def generate_valid_claim(index):
    """
    Generate one valid claim record.
    """

    claim_date = generate_claim_date()

    incident_date = claim_date - timedelta(
        days=random.randint(0, 10)
    )

    claim_amount = round(
        random.uniform(1000, 100000),
        2
    )

    status = random.choice(CLAIM_STATUSES)

    approved_amount = None

    if status in ["APPROVED", "SETTLED"]:
        approved_amount = round(
            random.uniform(
                claim_amount * 0.5,
                claim_amount
            ),
            2
        )

    settlement_date = None

    if status == "SETTLED":
        settlement_date = claim_date + timedelta(
            days=random.randint(5, 30)
        )

    created_at = datetime.combine(
        claim_date,
        datetime.min.time()
    ).replace(
        hour=random.randint(0, 23),
        minute=random.randint(0, 59)
    )

    updated_at = created_at + timedelta(
        hours=random.randint(1, 48)
    )

    return {
        "claim_id": f"CLM{index:06d}",
        "policy_id": f"POL{random.randint(1, 500):06d}",
        "customer_id": f"CUST{random.randint(1, 500):06d}",
        "claim_date": claim_date.isoformat(),
        "incident_date": incident_date.isoformat(),
        "claim_type": random.choice(CLAIM_TYPES),
        "claim_status": status,
        "claim_amount": claim_amount,
        "approved_amount": approved_amount,
        "settlement_date": (
            settlement_date.isoformat()
            if settlement_date
            else None
        ),
        "created_at": created_at.isoformat(
            sep=" "
        ),
        "updated_at": updated_at.isoformat(
            sep=" "
        ),
    }


# ============================================================
# Data Quality Issue Generators
# ============================================================

def introduce_invalid_amount(record):
    """
    Introduce a negative claim amount.
    """

    record["claim_amount"] = -abs(
        float(record["claim_amount"])
    )

    return record


def introduce_invalid_status(record):
    """
    Introduce an invalid claim status.
    """

    record["claim_status"] = random.choice(
        INVALID_STATUSES
    )

    return record


def introduce_invalid_date(record):
    """
    Introduce an invalid date string.
    """

    record["claim_date"] = "2026-13-45"

    return record


def introduce_null_claim_id(record):
    """
    Remove the claim identifier.
    """

    record["claim_id"] = None

    return record


def introduce_null_amount(record):
    """
    Remove the claim amount.
    """

    record["claim_amount"] = None

    return record


def introduce_data_quality_issue(record):
    """
    Randomly introduce one data quality issue.
    """

    issue = random.choice([
        "invalid_amount",
        "invalid_status",
        "invalid_date",
        "null_claim_id",
        "null_amount",
    ])

    if issue == "invalid_amount":
        return introduce_invalid_amount(record)

    if issue == "invalid_status":
        return introduce_invalid_status(record)

    if issue == "invalid_date":
        return introduce_invalid_date(record)

    if issue == "null_claim_id":
        return introduce_null_claim_id(record)

    if issue == "null_amount":
        return introduce_null_amount(record)

    return record


# ============================================================
# Duplicate Generation
# ============================================================

def create_duplicates(records, duplicate_rate):
    """
    Duplicate existing records according to the requested rate.
    """

    if duplicate_rate <= 0:
        return records

    duplicate_count = int(
        len(records) * duplicate_rate
    )

    if duplicate_count == 0:
        return records

    duplicate_records = random.sample(
        records,
        min(duplicate_count, len(records))
    )

    records.extend(
        duplicate_records
    )

    return records


# ============================================================
# Argument Parser
# ============================================================

def parse_arguments():

    parser = argparse.ArgumentParser(
        description="Generate synthetic insurance claims data."
    )

    parser.add_argument(
        "--records",
        type=int,
        default=1000,
        help="Number of base records to generate."
    )

    parser.add_argument(
        "--duplicate-rate",
        type=float,
        default=0.0,
        help="Percentage of duplicate records."
    )

    parser.add_argument(
        "--invalid-rate",
        type=float,
        default=0.0,
        help="Percentage of records containing data quality issues."
    )

    parser.add_argument(
        "--null-rate",
        type=float,
        default=0.0,
        help="Reserved for future NULL scenarios."
    )

    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducibility."
    )

    return parser.parse_args()


# ============================================================
# Main Generator
# ============================================================

def generate_claim_file():

    args = parse_arguments()

    random.seed(args.seed)

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    file_name = (
        f"claims_{datetime.now():%Y%m%d}_001.csv"
    )

    output_file = OUTPUT_DIR / file_name

    records = []

    invalid_count = 0

    for index in range(
        1,
        args.records + 1
    ):

        record = generate_valid_claim(index)

        if random.random() < args.invalid_rate:

            record = introduce_data_quality_issue(
                record
            )

            invalid_count += 1

        records.append(record)

    records = create_duplicates(
        records,
        args.duplicate_rate
    )

    fieldnames = [
        "claim_id",
        "policy_id",
        "customer_id",
        "claim_date",
        "incident_date",
        "claim_type",
        "claim_status",
        "claim_amount",
        "approved_amount",
        "settlement_date",
        "created_at",
        "updated_at",
    ]

    with open(
        output_file,
        "w",
        newline="",
        encoding="utf-8"
    ) as file:

        writer = csv.DictWriter(
            file,
            fieldnames=fieldnames
        )

        writer.writeheader()

        writer.writerows(records)

    print(
        f"Generated {len(records)} records."
    )

    print(
        f"Base records: {args.records}"
    )

    print(
        f"Invalid records introduced: "
        f"{invalid_count}"
    )

    print(
        f"Output file: {output_file}"
    )


if __name__ == "__main__":
    generate_claim_file()
