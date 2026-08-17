import camelot
import pandas as pd

PDF = "data/raw/energy/Book_2025.pdf"

for page in range(200,211):

    print(f"\nChecking Page {page}")

    try:

        tables = camelot.read_pdf(
            PDF,
            pages=str(page),
            flavor="lattice"
        )

        if tables.n == 0:
            continue

        print(f"Tables Found : {tables.n}")

        for i, table in enumerate(tables):

            df = table.df

            filename = f"page_{page}_table_{i}.xlsx"

            df.to_excel(
                filename,
                index=False
            )

            print(filename)

    except:
        pass