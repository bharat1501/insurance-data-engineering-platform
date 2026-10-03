from pathlib import Path
import csv
import json


BASE_DIR = Path("data/generated")

CLAIMS_FILE = sorted(
    (BASE_DIR / "claims").glob("claims_*.csv")
)[-1]

POLICIES_FILE = sorted(
    (BASE_DIR / "policies").glob("policies_*.csv")
)[-1]

PAYMENTS_FILE = sorted(
    (BASE_DIR / "payments").glob("payments_*.json")
)[-1]


def load_csv(file_path):
    with file_path.open(
        "r",
        encoding="utf-8",
        newline="",
    ) as file:
        return list(csv.DictReader(file))


def load_json_lines(file_path):
    records = []

    with file_path.open(
        "r",
        encoding="utf-8",
    ) as file:

        for line in file:
            line = line.strip()

            if line:
                records.append(json.loads(line))

    return records


def main():

    claims = load_csv(CLAIMS_FILE)
    policies = load_csv(POLICIES_FILE)
    payments = load_json_lines(PAYMENTS_FILE)

    claim_map = {
        claim["claim_id"]: claim
        for claim in claims
    }

    policy_map = {
        policy["policy_id"]: policy
        for policy in policies
    }

    missing_claims = []
    missing_policies = []
    policy_mismatches = []

    for payment in payments:

        payment_id = payment["payment_id"]
        claim_id = payment["claim_id"]
        policy_id = payment["policy_id"]

        # Check claim reference
        if claim_id not in claim_map:
            missing_claims.append(
                (payment_id, claim_id)
            )
            continue

        claim = claim_map[claim_id]

        # Check policy reference
        if policy_id not in policy_map:
            missing_policies.append(
                (payment_id, policy_id)
            )
            continue

        # Check payment policy against claim policy
        if claim["policy_id"] != policy_id:
            policy_mismatches.append(
                (
                    payment_id,
                    claim_id,
                    policy_id,
                    claim["policy_id"],
                )
            )

    print(f"Total payments: {len(payments)}")
    print(f"Missing claims: {len(missing_claims)}")
    print(f"Missing policies: {len(missing_policies)}")
    print(f"Policy mismatches: {len(policy_mismatches)}")

    if missing_claims:
        print("\nSample missing claims:")
        print(missing_claims[:5])

    if missing_policies:
        print("\nSample missing policies:")
        print(missing_policies[:5])

    if policy_mismatches:
        print("\nSample policy mismatches:")
        print(policy_mismatches[:5])


if __name__ == "__main__":
    main()
