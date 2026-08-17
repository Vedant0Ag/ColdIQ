import camelot
import pandas as pd
import os

PDF_FILE = "data/raw/production/HORTICULTURAL_STATISTICS_AT_A_GLANCE_2024.pdf"
OUTPUT_FOLDER = "../output_tables"
START_PAGE = 140
END_PAGE = 186

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

all_tables = []
for page in range(START_PAGE, END_PAGE + 1):
    print(f"Reading Page {page}")
    tables = camelot.read_pdf(
        PDF_FILE,
        pages=str(page),
        flavor="lattice"      
    )
    print(f"Tables Found: {tables.n}")
    for i, table in enumerate(tables):
        df = table.df
        df.to_csv(
            f"{OUTPUT_FOLDER}/page_{page}_table_{i+1}.csv",
            index=False
        )
        all_tables.append(df)
print("Finished")