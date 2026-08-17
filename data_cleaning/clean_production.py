import os
import pandas as pd
from helpers import load_state_mapping


# LOAD MASTER TABLES

state_df = pd.read_csv("config/states.csv")
commodity_df = pd.read_csv("data/processed/commodity/commodity_clean.csv")
commodity_mapping = pd.read_csv("data/raw/commodity/commodity_mapping.csv")

state_mapping = load_state_mapping()

# Make state mapping case-insensitive

INPUT_FOLDER = "data/raw/production"
OUTPUT_FOLDER = "data/processed/production"
OUTPUT_FILE = os.path.join(
    OUTPUT_FOLDER,
    "production_master.csv"
)
os.makedirs(
    OUTPUT_FOLDER,
    exist_ok=True
)
YEAR_MAP = {
    "2019-20": (2, 3, 4),
    "2020-21": (5, 6, 7),
    "2021-22": (8, 9, 10),
    "2022-23": (11, 12, 13),
    "2023-24": (14, 15, 16)
}

# READ ALL FILES
all_tables = []
files = sorted(os.listdir(INPUT_FOLDER))

for file in files:
    if not file.lower().endswith(".csv"):
        continue
    commodity_name = os.path.splitext(file)[0]
    print(f"Processing : {commodity_name}")
    path = os.path.join(INPUT_FOLDER, file)
    df = pd.read_csv(
        path,
        header=None,
        encoding="utf-8",
        engine="python"
    )
    # Actual data starts from row 4
    data = df.iloc[3:].reset_index(drop=True)
    for year, cols in YEAR_MAP.items():
        area_col, prod_col, productivity_col = cols
        temp = pd.DataFrame({
            "State": data[1],
            "Commodity": commodity_name,
            "Year": year,
            "Area": data[area_col],
            "Production": data[prod_col],
            "Productivity": data[productivity_col]
        })

        all_tables.append(temp)

# MERGE ALL FILES
production = pd.concat(
    all_tables,
    ignore_index=True
)

# STATE CLEANING
production["State"] = (
    production["State"]
    .astype(str)
    .str.strip()
    .str.upper()
    .str.title()
)

production["State"] = production["State"].replace(
    state_mapping
)

# REMOVE EMPTY/TOTAL ROWS
production = production[
    production["State"].notna()
]

production = production[
    production["State"] != ""
]

production = production[
    ~production["State"]
    .str.upper()
    .str.contains("TOTAL", na=False)]

# COMMODITY CLEANING
production["Commodity"] = (
    production["Commodity"]
    .astype(str)
    .str.strip()
    .str.lower()
)

commodity_mapping["Production_Commodity"] = (
    commodity_mapping["Production_Commodity"]
    .astype(str)
    .str.strip()
    .str.lower()
)

commodity_mapping["Commodity_Name"] = (
    commodity_mapping["Commodity_Name"]
    .astype(str)
    .str.strip()
)

# DUPLICATE ROWS FOR VARIETIES
production = production.merge(
    commodity_mapping,
    left_on="Commodity",
    right_on="Production_Commodity",
    how="left"
)
production.drop(
    columns=[
        "Commodity",
        "Production_Commodity"
    ],
    inplace=True
)
production.rename(
    columns={
        "Commodity_Name": "Commodity"
    },
    inplace=True
)

# COMMODITY ID
commodity_lookup = commodity_df[
    [
        "Commodity_ID",
        "Commodity_Name"
    ]
].copy()

commodity_lookup["Commodity_Name"] = (
    commodity_lookup["Commodity_Name"]
    .astype(str)
    .str.strip()
)

production = production.merge(
    commodity_lookup,
    left_on="Commodity",
    right_on="Commodity_Name",
    how="left"
)
production.drop(
    columns="Commodity_Name",
    inplace=True
)
production = production[
    production["State"] != "Others"
]
# STATE ID
production = production.merge(
    state_df,
    on="State",
    how="left"
)

# CHECK UNMAPPED COMMODITIES
missing = production[
    production["Commodity_ID"].isna()]
if len(missing):
    print("\nUnmapped Commodities:")
    print(
        sorted(
            missing["Commodity"].dropna().unique()
        )
    )

# NUMERIC CLEANING
for col in [
    "Area",
    "Production",
    "Productivity"
]:
    production[col] = (
        production[col]
        .astype(str)
        .str.replace(",", "", regex=False)
        .str.strip()
    )
    production[col] = pd.to_numeric(
        production[col],
        errors="coerce"
    )

# REMOVE EMPTY NUMERIC ROWS
production = production.dropna(
    subset=[
        "Area",
        "Production",
        "Productivity"
    ],
    how="all"
)

# RESET INDEX
production = production.reset_index(drop=True)

# PRODUCTION ID
production.insert(
    0,
    "Production_ID",
    production.index + 1
)

production.to_csv(
    OUTPUT_FILE,
    index=False
)
