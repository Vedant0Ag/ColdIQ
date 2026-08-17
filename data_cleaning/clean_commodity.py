import os
import re
import pandas as pd
import numpy as np

INPUT_FILE = "data/raw/commodity/commodity.csv"
OUTPUT_FOLDER = "data/processed/commodity"
OUTPUT_FILE = os.path.join(
    OUTPUT_FOLDER,
    "commodity_clean.csv"
)

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

print("loading dataset")
commodity = pd.read_csv(INPUT_FILE,encoding="cp1252")
print("loaded dataset")

duplicate_rows = commodity.duplicated().sum()
commodity = commodity.drop_duplicates()

commodity["Commodity_Name"] = (
    commodity["Commodity_Name"]
    .astype(str)
    .str.strip())

commodity["Commodity_Category"] = (
    commodity["Commodity_Category"]
    .astype(str)
    .str.strip())

selected_commodities = [
    # Fruits
    "Apples",
    "Grapes",
    "Guava",
    "Litchi",
    "Mango",
    "Orange",
    "Papaya",
    "Pineapples",
    "Pomegranate",
    "Tangerine",

    # Vegetables
    "Potato (early)",
    "Onion",
    "Tomato",
    "Cabbage (early)",
    "Cabbage (late)",
    "Cauliflower",
    "Carrot (Bunched)",
    "Cucumber",
    "Chilli",
    "Peas"
]

commodity = commodity[
    commodity["Commodity_Name"].isin(selected_commodities)
]

# SHELF LIFE PARSER
def parse_shelf_life(value):
    if pd.isna(value):
        return np.nan, np.nan
    
    text = str(value).lower().strip()
    text=text.replace("Â", "")
    nums = re.findall(r"\d+\.?\d*", text)
    if len(nums) == 0:
        return np.nan, np.nan
    nums = [float(i) for i in nums]
    if len(nums) == 1:
        low = high = nums[0]
    else:
        low, high = nums[0], nums[1]

    # -------- Convert units --------
    if "day" in text:
        factor = 1
    elif "week" in text:
        factor = 7
    elif "month" in text:
        factor = 30
    elif "year" in text:
        factor = 365
    else:
        factor = 1
    low *= factor
    high *= factor
    return round(low), round(high)

commodity[
    ["Min_Shelf_Life(Days)",
     "Max_Shelf_Life(Days)"]
] = commodity["Recommended_Storage_Duration"].apply(
    lambda x: pd.Series(parse_shelf_life(x))
)
commodity["Average_Shelf_Life(Days)"] = (
    commodity["Min_Shelf_Life(Days)"] +
    commodity["Max_Shelf_Life(Days)"]
) / 2

commodity["Average_Spoilage_Rate"] = pd.to_numeric(
    commodity["Average_Spoilage_Rate"],
    errors="coerce")

commodity = commodity[
    commodity["Average_Spoilage_Rate"].notna()]


commodity = commodity.reset_index(drop=True)

commodity["Commodity_ID"] = (
    commodity.index + 1
)


commodity.to_csv(
    OUTPUT_FILE,
    index=False,
    encoding="utf-8-sig"
)

print("done")