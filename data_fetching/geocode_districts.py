import pandas as pd
import os

DISTRICTS_FILE = "data/raw/location/districts.csv"
INDIA_FILE = "data/raw/location/india_districts_renamed.csv"

OUTPUT_FILE = "data/raw/location/location_master.csv"
UNMATCHED_FILE = "data/raw/location/unmatched_districts.csv"

print("Reading files...")

districts = pd.read_csv(DISTRICTS_FILE)
india = pd.read_csv(INDIA_FILE)


# CLEAN DISTRICT NAMES
districts["District"] = (
    districts["District"]
    .astype(str)
    .str.strip()
    .str.title()
)

india["District"] = (
    india["District"]
    .astype(str)
    .str.strip()
    .str.title()
)

duplicates = india[india.duplicated("District", keep=False)]

if len(duplicates) > 0:

    print("\nWARNING: Duplicate district names found!\n")
    print(duplicates.sort_values("District"))

else:

    print("No duplicate district names found.")

# KEEP REQUIRED COLUMNS

india = india[["District", "Latitude", "Longitude"]]

location = districts.merge(
    india,
    on="District",
    how="left"
)

location["Match_Status"] = location["Latitude"].apply(
    lambda x: "Matched" if pd.notna(x) else "Not Found"
)


os.makedirs("data/location", exist_ok=True)

location.to_csv(
    OUTPUT_FILE,
    index=False
)

unmatched = location[
    location["Match_Status"] == "Not Found"
]

unmatched.to_csv(
    UNMATCHED_FILE,
    index=False
)

matched = len(location) - len(unmatched)

print(f"Total Districts : {len(location)}")
print(f"Matched         : {matched}")
print(f"Not Found       : {len(unmatched)}")

if len(unmatched) > 0:

    print("\nDistricts NOT FOUND:\n")

    for district in unmatched["District"]:
        print(f"✗ {district}")

else:

    print("\n Every district matched successfully!")