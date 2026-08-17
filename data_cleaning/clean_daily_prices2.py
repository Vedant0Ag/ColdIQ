import pandas as pd
import numpy as np

INPUT_FILE = "data/processed/daily_prices/daily_prices_clean.csv"
OUTPUT_FILE = "data/processed/daily_prices/daily_prices_final.csv"

print("Loading")

df = pd.read_csv(INPUT_FILE)

price_cols = ["Min_Price", "Modal_Price", "Max_Price"]
for col in price_cols:
    df[col] = pd.to_numeric(df[col], errors="coerce")

df = df.dropna(subset=price_cols)

df = df[
    (df["Min_Price"] >= 0) &
    (df["Modal_Price"] >= 0) &
    (df["Max_Price"] >= 0)
]

df = df[
    ~(
        (df["Min_Price"] == 0) &
        (df["Modal_Price"] == 0) &
        (df["Max_Price"] == 0)
    )
]

df = df[
    (df["Min_Price"] <= df["Modal_Price"]) &
    (df["Modal_Price"] <= df["Max_Price"])
]

stats = (
    df.groupby("Commodity")["Modal_Price"]
      .quantile([0.01, 0.999])
      .unstack()
      .rename(columns={
          0.01: "Lower_Limit",
          0.999: "Upper_Limit"
      })
      .reset_index()
)

df = df.merge(stats, on="Commodity", how="left")


df = df[
    (df["Min_Price"] >= df["Lower_Limit"]) &
    (df["Modal_Price"] >= df["Lower_Limit"])
]

df = df[
    (df["Modal_Price"] <= df["Upper_Limit"] * 2) &
    (df["Max_Price"] <= df["Upper_Limit"] * 2)
]

df = df.drop(
    columns=[
        "Lower_Limit",
        "Upper_Limit"
    ]
)

df = df.sort_values(
    ["Arrival_Date", "Commodity", "State", "District", "Market"]
)

df.to_csv(
    OUTPUT_FILE,
    index=False
)

print("-" * 50)
print(f"Rows remaining : {len(df):,}")
print(f"Saved to       : {OUTPUT_FILE}")
print("-" * 50)