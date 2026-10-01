import csv
import random
from datetime import datetime, timedelta
from pathlib import Path


# ============================================================
# Configuration
# ============================================================

OUTPUT_DIR = Path("data/generated/claims")

NUM_RECORDS = 1000

RANDOM_SEED = 42

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


def generate_claim_record(index):
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
# Main Generator
# ============================================================

def generate_claim_file():

    random.seed(RANDOM_SEED)

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    file_name = (
        f"claims_{datetime.now():%Y%m%d}_001.csv"
    )

    output_file = OUTPUT_DIR / file_name

    records = [
        generate_claim_record(i)
        for i in range(1, NUM_RECORDS + 1)
    ]

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
        f"Generated {len(records)} claims: "
        f"{output_file}"
    )


if __name__ == "__main__":
    generate_claim_file()
