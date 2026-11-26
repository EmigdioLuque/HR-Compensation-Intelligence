# ============================================================
# HR COMPENSATION INTELLIGENCE
# 01 - Data Exploration
# ============================================================

from pathlib import Path
import pandas as pd

# ------------------------------------------------------------
# 1. PROJECT CONFIGURATION
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "data" / "raw"

datasets = {
    "6032.csv": "Labour Costs",
    "28185.csv": "Salary by Economic Activity",
    "28186.csv": "Salary by Occupation",
    "28192.csv": "Regional Salary by Sector",
    "28193.csv": "Regional Salary by Occupation"
}

# ------------------------------------------------------------
# 2. DATA EXPLORATION
# ------------------------------------------------------------

print("=" * 70)
print("HR COMPENSATION INTELLIGENCE")
print("DATA EXPLORATION REPORT")
print("=" * 70)

total_records = 0

for filename, description in datasets.items():

    file_path = RAW_DIR / filename

    print("\n" + "=" * 70)
    print(f"DATASET: {description}")
    print(f"FILE: {filename}")
    print("=" * 70)

    try:
        df = pd.read_csv(
            file_path,
            sep=";",
            encoding="latin-1",
            na_values=[".."]
        )

        total_records += len(df)

        # Dataset dimensions
        print("\n1. DATASET DIMENSIONS")
        print(f"Rows: {df.shape[0]:,}")
        print(f"Columns: {df.shape[1]}")

        # Column names
        print("\n2. COLUMN NAMES")
        print(df.columns.tolist())

        # Data types
        print("\n3. DATA TYPES")
        print(df.dtypes)

        # Missing values
        print("\n4. MISSING VALUES")
        print(df.isnull().sum())

        # Duplicate records
        print("\n5. DUPLICATE RECORDS")
        print(df.duplicated().sum())

        # Sample records
        print("\n6. SAMPLE DATA")
        print(df.head().to_string(index=False))

    except Exception as error:
        print(f"Error loading dataset: {error}")

# ------------------------------------------------------------
# 3. FINAL SUMMARY
# ------------------------------------------------------------

print("\n" + "=" * 70)
print("EXPLORATION SUMMARY")
print("=" * 70)

print(f"Datasets configured: {len(datasets)}")
print(f"Total records loaded: {total_records:,}")

print("=" * 70)