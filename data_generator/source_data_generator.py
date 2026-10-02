import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path


# ============================================================
# Configuration
# ============================================================

OUTPUT_ROOT = Path("data/generated")

RANDOM_SEED = 42

CUSTOMER_COUNT = 500
POLICY_COUNT = 1000
CLAIM_COUNT = 5000


POLICY_TYPES = [
    "AUTO",
    "HEALTH",
    "HOME",
    "TRAVEL",
    "LIFE",
]

POLICY_STATUSES = [
    "ACTIVE",
    "EXPIRED",
    "CANCELLED",
]

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
# Utility
# ============================================================

def random_date(start_date, end_date):
    """
    Generate a random date between two dates.
    """

    days = (end_date - start_date).days

    return start_date + timedelta(
        days=random.randint(0, days)
    )


# ============================================================
# Customer Generator
# ============================================================

def generate_customers():

    customers = []

    for i in range(1, CUSTOMER_COUNT + 1):

        customers.append(
            {
                "customer_id": f"CUST{i:06d}",
                "first_name": f"Customer{i}",
                "last_name": f"User{i}",
                "date_of_birth": random_date(
                    date(1960, 1, 1),
                    date(2000, 12, 31),
                ).isoformat(),
                "email": (
                    f"customer{i}@example.com"
                ),
                "phone": (
                    f"90000{i:05d}"
                ),
                "address": (
                    f"{i} Main Street"
                ),
                "city": "Hyderabad",
                "state": "Telangana",
                "customer_type": random.choice(
                    ["INDIVIDUAL", "BUSINESS"]
                ),
                "created_at": datetime.now().isoformat(
                    sep=" "
                ),
                "updated_at": datetime.now().isoformat(
                    sep=" "
                ),
            }
        )

    return customers


# ============================================================
# Policy Generator
# ============================================================

def generate_policies(customers):

    policies = []

    for i in range(1, POLICY_COUNT + 1):

        customer = random.choice(customers)

        start_date = random_date(
            date(2024, 1, 1),
            date.today(),
        )

        end_date = start_date + timedelta(
            days=365
        )

        policies.append(
            {
                "policy_id": f"POL{i:06d}",
                "customer_id": customer["customer_id"],
                "policy_type": random.choice(
                    POLICY_TYPES
                ),
                "policy_status": random.choice(
                    POLICY_STATUSES
                ),
                "policy_start_date": (
                    start_date.isoformat()
                ),
                "policy_end_date": (
                    end_date.isoformat()
                ),
                "premium_amount": round(
                    random.uniform(
                        5000,
                        100000
                    ),
                    2
                ),
                "coverage_amount": round(
                    random.uniform(
                        100000,
                        10000000
                    ),
                    2
                ),
                "agent_id": (
                    f"AGT{random.randint(1, 100):06d}"
                ),
                "created_at": datetime.now().isoformat(
                    sep=" "
                ),
                "updated_at": datetime.now().isoformat(
                    sep=" "
                ),
            }
        )

    return policies


# ============================================================
# Claim Generator
# ============================================================

def generate_claims(policies):

    claims = []

    for i in range(1, CLAIM_COUNT + 1):

        policy = random.choice(policies)

        claim_date = random_date(
            date(2025, 1, 1),
            date.today(),
        )

        incident_date = claim_date - timedelta(
            days=random.randint(0, 10)
        )

        claim_amount = round(
            random.uniform(
                1000,
                100000
            ),
            2
        )

        status = random.choice(
            CLAIM_STATUSES
        )

        approved_amount = None

        if status in [
            "APPROVED",
            "SETTLED"
        ]:
            approved_amount = round(
                random.uniform(
                    claim_amount * 0.5,
                    claim_amount
                ),
                2
            )

        settlement_date = None

        if status == "SETTLED":
            settlement_date = (
                claim_date
                + timedelta(
                    days=random.randint(
                        5,
                        30
                    )
                )
            )

        claims.append(
            {
                "claim_id": f"CLM{i:06d}",

                "policy_id": policy["policy_id"],

                # IMPORTANT:
                # Customer comes from the selected policy.
                "customer_id": policy["customer_id"],

                "claim_date": (
                    claim_date.isoformat()
                ),

                "incident_date": (
                    incident_date.isoformat()
                ),

                "claim_type": random.choice(
                    CLAIM_TYPES
                ),

                "claim_status": status,

                "claim_amount": claim_amount,

                "approved_amount": approved_amount,

                "settlement_date": (
                    settlement_date.isoformat()
                    if settlement_date
                    else None
                ),

                "created_at": datetime.now().isoformat(
                    sep=" "
                ),

                "updated_at": datetime.now().isoformat(
                    sep=" "
                ),
            }
        )

    return claims


# ============================================================
# CSV Writer
# ============================================================

def write_csv(
    records,
    output_file,
    fieldnames
):

    output_file.parent.mkdir(
        parents=True,
        exist_ok=True
    )

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


# ============================================================
# Main
# ============================================================

def main():

    random.seed(RANDOM_SEED)

    today = datetime.now().strftime(
        "%Y%m%d"
    )

    # --------------------------------------------------------
    # Generate source entities
    # --------------------------------------------------------

    customers = generate_customers()

    policies = generate_policies(
        customers
    )

    claims = generate_claims(
        policies
    )

    # --------------------------------------------------------
    # Write Customers
    # --------------------------------------------------------

    write_csv(
        customers,
        OUTPUT_ROOT
        / "customers"
        / f"customers_{today}_001.csv",

        [
            "customer_id",
            "first_name",
            "last_name",
            "date_of_birth",
            "email",
            "phone",
            "address",
            "city",
            "state",
            "customer_type",
            "created_at",
            "updated_at",
        ]
    )

    # --------------------------------------------------------
    # Write Policies
    # --------------------------------------------------------

    write_csv(
        policies,
        OUTPUT_ROOT
        / "policies"
        / f"policies_{today}_001.csv",

        [
            "policy_id",
            "customer_id",
            "policy_type",
            "policy_status",
            "policy_start_date",
            "policy_end_date",
            "premium_amount",
            "coverage_amount",
            "agent_id",
            "created_at",
            "updated_at",
        ]
    )

    # --------------------------------------------------------
    # Write Claims
    # --------------------------------------------------------

    write_csv(
        claims,
        OUTPUT_ROOT
        / "claims"
        / f"claims_{today}_001.csv",

        [
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
    )

    print(
        f"Generated {len(customers)} customers."
    )

    print(
        f"Generated {len(policies)} policies."
    )

    print(
        f"Generated {len(claims)} claims."
    )


if __name__ == "__main__":
    main()
