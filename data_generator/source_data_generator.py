from pathlib import Path
from datetime import date, datetime, timedelta
import csv
import json
import random

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

CUSTOMER_COUNT = 500
POLICY_COUNT = 1000
CLAIM_COUNT = 5000
AGENT_COUNT = 100
PAYMENT_COUNT = 6000

RANDOM_SEED = 42

OUTPUT_DIR = Path("data/generated")

random.seed(RANDOM_SEED)


# ---------------------------------------------------------
# Common helpers
# ---------------------------------------------------------

FIRST_NAMES = [
    "Amit", "Rahul", "Priya", "Neha", "Arjun",
    "Sneha", "Vikram", "Ananya", "Rohan", "Pooja"
]

LAST_NAMES = [
    "Sharma", "Kumar", "Singh", "Patel", "Verma",
    "Gupta", "Mehta", "Reddy", "Das", "Roy"
]

CITIES = [
    ("Mumbai", "MH"),
    ("Pune", "MH"),
    ("Bengaluru", "KA"),
    ("Hyderabad", "TS"),
    ("Delhi", "DL"),
    ("Chennai", "TN"),
    ("Kolkata", "WB"),
    ("Jaipur", "RJ"),
]

POLICY_TYPES = [
    "AUTO",
    "HEALTH",
    "LIFE",
    "HOME",
]

POLICY_STATUSES = [
    "ACTIVE",
    "EXPIRED",
    "CANCELLED",
]

CLAIM_TYPES = [
    "ACCIDENT",
    "THEFT",
    "MEDICAL",
    "PROPERTY_DAMAGE",
]

CLAIM_STATUSES = [
    "OPEN",
    "UNDER_REVIEW",
    "APPROVED",
    "REJECTED",
    "SETTLED",
]

PAYMENT_STATUSES = [
    "PENDING",
    "PROCESSED",
    "FAILED",
]

PAYMENT_METHODS = [
    "BANK_TRANSFER",
    "CHEQUE",
    "UPI",
]


def random_date(start_date, end_date):
    delta = end_date - start_date
    return start_date + timedelta(days=random.randint(0, delta.days))


def random_datetime():
    start = datetime(2024, 1, 1)
    end = datetime(2026, 10, 1)

    delta = end - start

    return start + timedelta(
        seconds=random.randint(0, int(delta.total_seconds()))
    )


def random_email(first_name, last_name, identifier):
    return (
        f"{first_name.lower()}.{last_name.lower()}"
        f"{identifier}@example.com"
    )


# ---------------------------------------------------------
# CUSTOMER
# ---------------------------------------------------------

def generate_customers():
    customers = []

    for i in range(1, CUSTOMER_COUNT + 1):

        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)

        city, state = random.choice(CITIES)

        created_at = random_datetime()

        customer = {
            "customer_id": f"CUST{i:06d}",
            "first_name": first_name,
            "last_name": last_name,
            "date_of_birth": random_date(
                date(1960, 1, 1),
                date(2000, 12, 31),
            ).isoformat(),
            "email": random_email(first_name, last_name, i),
            "phone": f"9{random.randint(100000000, 999999999)}",
            "address": f"{random.randint(1, 999)} Main Street",
            "city": city,
            "state": state,
            "customer_type": random.choice(
                ["INDIVIDUAL", "BUSINESS"]
            ),
            "created_at": created_at.isoformat(sep=" "),
            "updated_at": created_at.isoformat(sep=" "),
        }

        customers.append(customer)

    return customers


# ---------------------------------------------------------
# AGENT
# ---------------------------------------------------------

def generate_agents():
    agents = []

    branches = [
        "Mumbai Central",
        "Pune Central",
        "Bengaluru Central",
        "Hyderabad Central",
        "Delhi Central",
    ]

    regions = [
        "WEST",
        "SOUTH",
        "NORTH",
    ]

    for i in range(1, AGENT_COUNT + 1):

        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)

        created_at = random_datetime()

        agent = {
            "agent_id": f"AGT{i:05d}",
            "agent_name": f"{first_name} {last_name}",
            "agent_email": random_email(
                first_name,
                last_name,
                f"agent{i}",
            ),
            "branch": random.choice(branches),
            "region": random.choice(regions),
            "agent_status": random.choice(
                ["ACTIVE", "INACTIVE"]
            ),
            "created_at": created_at.isoformat(sep=" "),
            "updated_at": created_at.isoformat(sep=" "),
        }

        agents.append(agent)

    return agents


# ---------------------------------------------------------
# POLICY
# ---------------------------------------------------------

def generate_policies(customers, agents):

    policies = []

    for i in range(1, POLICY_COUNT + 1):

        customer = random.choice(customers)
        agent = random.choice(agents)

        start_date = random_date(
            date(2024, 1, 1),
            date(2026, 9, 1),
        )

        end_date = start_date + timedelta(
            days=random.choice([365, 730, 1095])
        )

        created_at = random_datetime()

        policy = {
            "policy_id": f"POL{i:06d}",
            "customer_id": customer["customer_id"],
            "policy_type": random.choice(POLICY_TYPES),
            "policy_status": random.choice(POLICY_STATUSES),
            "policy_start_date": start_date.isoformat(),
            "policy_end_date": end_date.isoformat(),
            "premium_amount": round(
                random.uniform(5000, 100000),
                2,
            ),
            "coverage_amount": round(
                random.uniform(100000, 5000000),
                2,
            ),
            "agent_id": agent["agent_id"],
            "created_at": created_at.isoformat(sep=" "),
            "updated_at": created_at.isoformat(sep=" "),
        }

        policies.append(policy)

    return policies


# ---------------------------------------------------------
# CLAIM
# ---------------------------------------------------------

def generate_claims(policies):

    claims = []

    for i in range(1, CLAIM_COUNT + 1):

        policy = random.choice(policies)

        incident_date = random_date(
            date(2024, 1, 1),
            date(2026, 9, 30),
        )

        claim_date = incident_date + timedelta(
            days=random.randint(0, 30)
        )

        claim_amount = round(
            random.uniform(1000, 500000),
            2,
        )

        status = random.choice(CLAIM_STATUSES)

        if status in ["APPROVED", "SETTLED"]:
            approved_amount = round(
                claim_amount * random.uniform(0.5, 1.0),
                2,
            )
        else:
            approved_amount = 0.0

        settlement_date = None

        if status == "SETTLED":
            settlement_date = (
                claim_date
                + timedelta(days=random.randint(5, 60))
            ).isoformat()

        created_at = random_datetime()

        claim = {
            "claim_id": f"CLM{i:07d}",
            "policy_id": policy["policy_id"],
            "customer_id": policy["customer_id"],
            "claim_date": claim_date.isoformat(),
            "incident_date": incident_date.isoformat(),
            "claim_type": random.choice(CLAIM_TYPES),
            "claim_status": status,
            "claim_amount": claim_amount,
            "approved_amount": approved_amount,
            "settlement_date": settlement_date,
            "created_at": created_at.isoformat(sep=" "),
            "updated_at": created_at.isoformat(sep=" "),
        }

        claims.append(claim)

    return claims


# ---------------------------------------------------------
# PAYMENT
# ---------------------------------------------------------

def generate_payments(claims, policies):

    payments = []

    policies_by_id = {
        policy["policy_id"]: policy
        for policy in policies
    }

    for i in range(1, PAYMENT_COUNT + 1):

        claim = random.choice(claims)

        policy = policies_by_id[claim["policy_id"]]

        payment_amount = round(
            random.uniform(
                500,
                max(500, claim["approved_amount"]),
            ),
            2,
        )

        payment_date = random_date(
            date(2024, 1, 1),
            date(2026, 10, 1),
        )

        created_at = random_datetime()

        payment = {
            "payment_id": f"PAY{i:07d}",
            "claim_id": claim["claim_id"],
            "policy_id": policy["policy_id"],
            "payment_date": payment_date.isoformat(),
            "payment_amount": payment_amount,
            "payment_status": random.choice(
                PAYMENT_STATUSES
            ),
            "payment_method": random.choice(
                PAYMENT_METHODS
            ),
            "created_at": created_at.isoformat(sep=" "),
            "updated_at": created_at.isoformat(sep=" "),
        }

        payments.append(payment)

    return payments


# ---------------------------------------------------------
# CSV writer
# ---------------------------------------------------------

def write_csv(records, output_file):

    output_file.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    if not records:
        return

    with output_file.open(
        "w",
        newline="",
        encoding="utf-8",
    ) as file:

        writer = csv.DictWriter(
            file,
            fieldnames=records[0].keys(),
        )

        writer.writeheader()
        writer.writerows(records)


# ---------------------------------------------------------
# JSON writer
# ---------------------------------------------------------

def write_json(records, output_file):

    output_file.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with output_file.open(
        "w",
        encoding="utf-8",
    ) as file:

        for record in records:
            file.write(
                json.dumps(record)
                + "\n"
            )


# ---------------------------------------------------------
# Main
# ---------------------------------------------------------

def main():

    run_date = date.today().strftime("%Y%m%d")

    customers = generate_customers()
    agents = generate_agents()
    policies = generate_policies(
        customers,
        agents,
    )
    claims = generate_claims(policies)
    payments = generate_payments(
        claims,
        policies,
    )

    write_csv(
        customers,
        OUTPUT_DIR
        / "customers"
        / f"customers_{run_date}_001.csv",
    )

    write_csv(
        agents,
        OUTPUT_DIR
        / "agents"
        / f"agents_{run_date}_001.csv",
    )

    write_csv(
        policies,
        OUTPUT_DIR
        / "policies"
        / f"policies_{run_date}_001.csv",
    )

    write_csv(
        claims,
        OUTPUT_DIR
        / "claims"
        / f"claims_{run_date}_001.csv",
    )

    write_json(
        payments,
        OUTPUT_DIR
        / "payments"
        / f"payments_{run_date}_001.json",
    )

    print("Source data generation completed.")
    print(f"Customers : {len(customers)}")
    print(f"Agents    : {len(agents)}")
    print(f"Policies  : {len(policies)}")
    print(f"Claims    : {len(claims)}")
    print(f"Payments  : {len(payments)}")


if __name__ == "__main__":
    main()
