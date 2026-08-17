import os
import math
import pandas as pd


LOCATION_FILE = "data/raw/location/location_master.csv"

OUTPUT_FOLDER = "data/raw/transportation"
OUTPUT_FILE = os.path.join(
    OUTPUT_FOLDER,
    "transportation.csv"
)

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# HAVERSINE FUNCTION

EARTH_RADIUS = 6371.0088  # km

def haversine(lat1, lon1, lat2, lon2):

    lat1 = math.radians(lat1)
    lon1 = math.radians(lon1)
    lat2 = math.radians(lat2)
    lon2 = math.radians(lon2)

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(lat1)
        * math.cos(lat2)
        * math.sin(dlon / 2) ** 2
    )

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return EARTH_RADIUS * c

# LOAD LOCATION

print("Loading Location Table...")

location = pd.read_csv(LOCATION_FILE)

required_cols = [
    "District_ID",
    "Latitude",
    "Longitude"
]

location = location[required_cols].dropna()

location["Latitude"] = location["Latitude"].astype(float)
location["Longitude"] = location["Longitude"].astype(float)

print(f"Districts Loaded : {len(location)}")


rows = []
transport_no = 1
total = len(location)

print("Calculating distances...")
for i in range(total):
    src = location.iloc[i]
    if (i + 1) % 25 == 0:
        print(f"Processed {i+1}/{total} source districts")
    for j in range(total):

        dst = location.iloc[j]

        distance = haversine(
            src["Latitude"],
            src["Longitude"],
            dst["Latitude"],
            dst["Longitude"]
        )

        rows.append({
            "Transport_ID": f"T{transport_no:06d}",
            "Source_District_ID": src["District_ID"],
            "Destination_District_ID": dst["District_ID"],
            "Distance_KM": round(distance, 2)
        })

        transport_no += 1

transport = pd.DataFrame(rows)

transport.to_csv(
    OUTPUT_FILE,
    index=False
)

print("\nDone!")

print(f"Rows Generated : {len(transport):,}")

print(f"Saved To : {OUTPUT_FILE}")