import os
import pandas as pd

from helpers import load_state_mapping

INPUT_FILE = "data/raw/weather/weather.csv"

OUTPUT_FOLDER = "data/processed/weather"
OUTPUT_FILE = os.path.join(
    OUTPUT_FOLDER,
    "weather_clean.csv"
)

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

print("Loading")

weather = pd.read_csv(INPUT_FILE)
location = pd.read_csv(
    "data/processed/location/location_clean.csv"
)

state_mapping = load_state_mapping()

weather = weather.drop_duplicates()

text_cols = ["State","District"]
for col in text_cols:
    weather[col] = (
        weather[col]
        .astype(str)
        .str.strip())
    
weather["State"] = weather["State"].replace(
    state_mapping)

weather["Date"] = pd.to_datetime(
    weather["Date"].astype(str),
    format="%Y%m%d")

weather_cols = [
    "T2M",
    "T2M_MAX",
    "T2M_MIN",
    "RH2M",
    "Rainfall",
    "Solar_Radiation"
]
weather[weather_cols] = (
    weather[weather_cols]
    .replace(-999, pd.NA)
)

before = len(weather)
weather = weather.dropna(
    subset=weather_cols
)
print(
    f"Rows Removed (-999): {before-len(weather)}")

weather = weather[
    (weather["RH2M"] >= 0)    &
    (weather["RH2M"] <= 100)
]

weather = weather[
    weather["Rainfall"] >= 0
]

location["State_Key"] = (
    location["State"]
    .str.strip()
    .str.lower()
    .str.replace(r"\s+", "", regex=True)
)
location["District_Key"] = (
    location["District"]
    .str.strip()
    .str.lower()
    .str.replace(r"\s+", "", regex=True)
)
weather["State_Key"] = (
    weather["State"]
    .str.strip()
    .str.lower()
    .str.replace(r"\s+", "", regex=True)
)
weather["District_Key"] = (
    weather["District"]
    .str.strip()
    .str.lower()
    .str.replace(r"\s+", "", regex=True))

district_lookup = location[
    [
        "State_Key",
        "District_Key",
        "District_ID"
    ]
]

weather = weather.merge(
    district_lookup,
    on=[
        "State_Key",
        "District_Key"],
    how="left")

weather.drop(
    columns=[
        "State_Key",
        "District_Key"],
    inplace=True
)
weather = weather.reset_index(drop=True)
weather.insert(
    0,
    "Weather_ID",
    weather.index + 1
)

weather.to_csv(
    OUTPUT_FILE,
    index=False
)
