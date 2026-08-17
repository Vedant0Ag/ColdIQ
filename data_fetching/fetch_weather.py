import os
import time
import requests
import pandas as pd
from tqdm import tqdm
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock

# =====================================================
# CONFIGURATION
# =====================================================

LOCATION_FILE = "data/raw/location/location_master.csv"
OUTPUT_FILE = "data/raw/weather/weather.csv"
FAILED_FILE = "data/raw/weather/failed_requests.csv"

START = "20220101"
END = "20260719"

MAX_WORKERS = 5
MAX_RETRIES = 3

PARAMETERS = ",".join([
    "T2M",
    "T2M_MAX",
    "T2M_MIN",
    "RH2M",
    "PRECTOTCORR",
    "ALLSKY_SFC_SW_DWN"
])

os.makedirs("data/weather", exist_ok=True)
locations = pd.read_csv(LOCATION_FILE)

# RESUME SUPPORT
completed = set()

if os.path.exists(OUTPUT_FILE):
    temp = pd.read_csv(
        OUTPUT_FILE,
        usecols=["District"]
    )
    completed = set(temp["District"].unique())

locations = locations[
    ~locations["District"].isin(completed)
].reset_index(drop=True)

print(f"Remaining Districts : {len(locations)}")

# =====================================================
# CREATE CSV IF NOT EXISTS
# =====================================================

if not os.path.exists(OUTPUT_FILE):

    columns = [
        "Date",
        "State",
        "District",
        "Latitude",
        "Longitude",
        "T2M",
        "T2M_MAX",
        "T2M_MIN",
        "RH2M",
        "Rainfall",
        "Solar_Radiation"
    ]

    pd.DataFrame(columns=columns).to_csv(
        OUTPUT_FILE,
        index=False
    )

csv_lock = Lock()

# =====================================================
# FETCH FUNCTION
# =====================================================

def fetch_weather(row):

    district = row.District
    state = row.State
    lat = row.Latitude
    lon = row.Longitude

    url = (
        "https://power.larc.nasa.gov/api/temporal/daily/point?"
        f"parameters={PARAMETERS}"
        f"&community=AG"
        f"&longitude={lon}"
        f"&latitude={lat}"
        f"&start={START}"
        f"&end={END}"
        f"&format=JSON"
    )

    for attempt in range(MAX_RETRIES):

        try:

            response = requests.get(
                url,
                timeout=60
            )

            response.raise_for_status()

            js = response.json()

            p = js["properties"]["parameter"]

            rows = []

            for date in p["T2M"]:

                rows.append({

                    "Date": date,

                    "State": state,

                    "District": district,

                    "Latitude": lat,

                    "Longitude": lon,

                    "T2M": p["T2M"][date],

                    "T2M_MAX": p["T2M_MAX"][date],

                    "T2M_MIN": p["T2M_MIN"][date],

                    "RH2M": p["RH2M"][date],

                    "Rainfall": p["PRECTOTCORR"][date],

                    "Solar_Radiation":
                        p["ALLSKY_SFC_SW_DWN"][date]

                })

            df = pd.DataFrame(rows)

            with csv_lock:

                df.to_csv(
                    OUTPUT_FILE,
                    mode="a",
                    index=False,
                    header=False
                )

            return district, True

        except Exception:

            time.sleep(2)

    return district, False

# =====================================================
# MULTITHREADING
# =====================================================

failed = []

with ThreadPoolExecutor(
        max_workers=MAX_WORKERS) as executor:

    futures = [
        executor.submit(fetch_weather, row)
        for _, row in locations.iterrows()
    ]

    for future in tqdm(as_completed(futures),
                       total=len(futures)):

        district, success = future.result()

        if success:

            print(f"✓ {district}")

        else:

            print(f"✗ {district}")

            failed.append(district)

# =====================================================
# SAVE FAILED REQUESTS
# =====================================================

if len(failed):

    pd.DataFrame({

        "District": failed

    }).to_csv(

        FAILED_FILE,

        index=False

    )

print()

print("======================================")

print("Weather Collection Finished")

print(f"Failed : {len(failed)}")

print("======================================")