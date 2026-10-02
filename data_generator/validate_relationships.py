import csv
from pathlib import Path


DATA_ROOT = Path("data/generated")


def read_csv(path):

    with open(
        path,
        encoding="utf-8"
    ) as file:

        return list(
            csv.DictReader(file)
        )


def main():

    policy_file = next(
        (DATA_ROOT / "policies").glob("*.csv")
    )

    claim_file = next(
        (DATA_ROOT / "claims").glob("*.csv")
    )

    policies = read_csv(
        policy_file
    )

    claims = read_csv(
        claim_file
    )

    policy_customer_map = {
        row["policy_id"]:
        row["customer_id"]
        for row in policies
    }

    mismatch_count = 0

    missing_policy_count = 0

    for claim in claims:

        policy_id = claim["policy_id"]

        claim_customer_id = (
            claim["customer_id"]
        )

        policy_customer_id = (
            policy_customer_map.get(
                policy_id
            )
        )

        if policy_customer_id is None:

            missing_policy_count += 1

            continue

        if (
            claim_customer_id
            != policy_customer_id
        ):

            mismatch_count += 1

    print(
        f"Total claims: {len(claims)}"
    )

    print(
        f"Missing policies: "
        f"{missing_policy_count}"
    )

    print(
        f"Customer/policy mismatches: "
        f"{mismatch_count}"
    )


if __name__ == "__main__":
    main()
