import os
import csv
import time
from datetime import datetime, timedelta

import requests

from config import API_KEY
RESOURCE_ID = "35985678-0d79-46b4-9ed6-6f13308a1d24"
BASE_URL = f"https://api.data.gov.in/resource/{RESOURCE_ID}"
# ===================================================
# CONFIGURATION
# ===================================================

START_DATE = datetime(2022, 1, 1)
END_DATE = datetime.today()

LIMIT = 20000

OUTPUT_FOLDER = "data/raw"
OUTPUT_FILE = os.path.join(
    OUTPUT_FOLDER,
    "daily_market_prices.csv"
)

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

HEADERS = {
    "User-Agent": "Mozilla/5.0",
    "Accept": "application/json"
}

# ===================================================
# CREATE CSV IF NOT EXISTS
# ===================================================

if not os.path.exists(OUTPUT_FILE):
    with open(
        OUTPUT_FILE,
        "w",
        newline="",
        encoding="utf-8-sig"
    ) as f:
        writer = csv.writer(f)
        writer.writerow([
            "Arrival_Date",
            "Commodity",
            "Commodity_Code",
            "District",
            "Grade",
            "Market",
            "Max_Price",
            "Min_Price",
            "Modal_Price",
            "State",
            "Variety"
        ])

print("=" * 70)
print("ColdIQ Daily Market Prices Downloader")
print("=" * 70)

current_date = START_DATE

while current_date <= END_DATE:

    date_string = current_date.strftime("%d/%m/%Y")

    print("\n" + "=" * 70)
    print("Date :", date_string)

    offset = 0
    total_downloaded_today = 0
    while True:
        params = {
            "api-key": API_KEY,
            "format": "json",
            "filters[Arrival_Date]": date_string,
            "offset": offset,
            "limit": LIMIT
        }
        retries = 3
        while retries > 0:
            try:
                response = requests.get(
                    BASE_URL,
                    params=params,
                    headers=HEADERS,
                    timeout=(10, 90)
                )
                response.raise_for_status()
                data = response.json()
                records = data.get("records", [])
                break
            except requests.exceptions.Timeout:
                retries -= 1
                print("Timeout... Retrying")
                time.sleep(5)
            except Exception as e:
                print(e)
                retries = 0
                records = []
        if len(records) == 0:
            break

        with open(
            OUTPUT_FILE,
            "a",
            newline="",
            encoding="utf-8-sig"
        ) as f:
            writer = csv.writer(f)
            for row in records:
                writer.writerow([
                    row.get("Arrival_Date"),
                    row.get("Commodity"),
                    row.get("Commodity_Code"),
                    row.get("District"),
                    row.get("Grade"),
                    row.get("Market"),
                    row.get("Max_Price"),
                    row.get("Min_Price"),
                    row.get("Modal_Price"),
                    row.get("State"),
                    row.get("Variety")
                ])
        total_downloaded_today += len(records)
        print(
            f"Offset {offset:<6} "
            f"Downloaded Today : {total_downloaded_today}"
        )

        offset += LIMIT
        time.sleep(0.5)

    print(
        f"Finished {date_string} "
        f"({total_downloaded_today} records)"
    )

    current_date += timedelta(days=1)

print("\nDownload Complete!")
print("CSV Saved At :", OUTPUT_FILE)