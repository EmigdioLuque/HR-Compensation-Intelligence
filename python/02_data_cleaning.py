# ============================================================
# HR COMPENSATION INTELLIGENCE
# 02 - Data Cleaning and Transformation
# ============================================================

from pathlib import Path
import pandas as pd

# ------------------------------------------------------------
# 1. PROJECT CONFIGURATION
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent

RAW_DIR = BASE_DIR / "data" / "raw"
PROCESSED_DIR = BASE_DIR / "data" / "processed"

PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

# Tables with verified negative-sign reliability convention
VERIFIED_RELIABILITY_TABLES = {
    "28185.csv",
    "28186.csv",
    "28192.csv",
    "28193.csv"
}

# ------------------------------------------------------------
# 2. DATASET CONFIGURATION
# ------------------------------------------------------------

datasets = {
    "6032.csv": {
        "output": "labour_costs.csv",
        "columns": {
            "Secciones de la CNAE-09": "economic_activity",
            "Componentes del coste": "cost_component",
            "Periodo": "period",
            "Total": "labour_cost"
        }
    },

    "28185.csv": {
        "output": "salary_economic_activity.csv",
        "columns": {
            "Secciones de la CNAE 2009": "economic_activity",
            "Sexo": "gender",
            "Periodo": "year",
            "Total": "annual_salary"
        }
    },

    "28186.csv": {
        "output": "salary_occupation.csv",
        "columns": {
            "Grupos principales de la CNO-11": "occupation",
            "Sexo": "gender",
            "Periodo": "year",
            "Total": "annual_salary"
        }
    },

    "28192.csv": {
        "output": "salary_regional_sector.csv",
        "columns": {
            "Comunidades autónomas": "region",
            "Sectores de actividad": "sector",
            "Sexo": "gender",
            "Periodo": "year",
            "Total": "annual_salary"
        }
    },

    "28193.csv": {
        "output": "salary_regional_occupation.csv",
        "columns": {
            "Comunidades autónomas": "region",
            "Ocupación": "occupation",
            "Sexo": "gender",
            "Periodo": "year",
            "Total": "annual_salary"
        }
    }
}

# ------------------------------------------------------------
# 3. NUMERIC TRANSFORMATION
# ------------------------------------------------------------

def clean_numeric(series):

    cleaned = (
        series.astype("string")
        .str.strip()
        .str.replace(".", "", regex=False)
        .str.replace(",", ".", regex=False)
    )

    return pd.to_numeric(cleaned, errors="raise")


def classify_salary_quality(series, filename):

    quality = pd.Series(
        "STANDARD",
        index=series.index,
        dtype="string"
    )

    negative_mask = series.lt(0).fillna(False)

    quality.loc[series.isna()] = "MISSING"

    if negative_mask.any():

        if filename not in VERIFIED_RELIABILITY_TABLES:
            raise ValueError(
                f"INE reliability convention pending verification: "
                f"{filename}"
            )

        quality.loc[negative_mask] = "LOW_RELIABILITY"

    return quality


# ------------------------------------------------------------
# 4. DATA CLEANING PIPELINE
# ------------------------------------------------------------

print("=" * 70)
print("HR COMPENSATION INTELLIGENCE")
print("DATA CLEANING REPORT")
print("=" * 70)

summary = []
processed_datasets = {}

for filename, config in datasets.items():

    print("\n" + "=" * 70)
    print(f"PROCESSING: {filename}")
    print("=" * 70)

    # Load original dataset
    df = pd.read_csv(
        RAW_DIR / filename,
        sep=";",
        encoding="latin-1",
        na_values=[".."]
    )

    original_rows = len(df)
    original_missing = df.isna().sum().sum()

    # Standardize column names
    df.columns = df.columns.str.strip()
    df = df.rename(columns=config["columns"])

    # Validate expected columns
    expected_columns = set(config["columns"].values())

    if set(df.columns) != expected_columns:
        raise ValueError(f"Unexpected columns in {filename}")

    # Remove unnecessary whitespace
    for column in df.select_dtypes(include=["object", "string"]):

        df[column] = df[column].str.strip()

    # Standardize gender categories
    if "gender" in df.columns:

        df["gender"] = df["gender"].replace({
            "Ambos sexos": "All",
            "Hombres": "Male",
            "Mujeres": "Female"
        })

        if not df["gender"].isin(["All", "Male", "Female"]).all():
            raise ValueError(f"Unexpected gender category in {filename}")

    # --------------------------------------------------------
    # MONETARY VALUES AND QUALITY FLAGS
    # --------------------------------------------------------

    low_reliability = 0

    if "annual_salary" in df.columns:

        value_column = "annual_salary"

        df[value_column] = clean_numeric(df[value_column])

        # Identify quality before modifying the original sign
        df["quality_flag"] = classify_salary_quality(
            df[value_column],
            filename
        )

        low_reliability = (
            df["quality_flag"] == "LOW_RELIABILITY"
        ).sum()

        # Recover salary magnitude for verified flagged estimates
        flagged_mask = df["quality_flag"] == "LOW_RELIABILITY"

        df.loc[flagged_mask, value_column] = (
            df.loc[flagged_mask, value_column].abs()
        )

        # Validate salary values
        if df[value_column].lt(0).fillna(False).any():
            raise ValueError(f"Negative salary found in {filename}")

    else:

        value_column = "labour_cost"

        df[value_column] = clean_numeric(df[value_column])

    # --------------------------------------------------------
    # TEMPORAL DIMENSIONS
    # --------------------------------------------------------

    if "period" in df.columns:

        if not df["period"].str.fullmatch(r"\d{4}T[1-4]").all():
            raise ValueError(f"Invalid quarterly period in {filename}")

        df["year"] = df["period"].str[:4].astype(int)
        df["quarter"] = df["period"].str[-1].astype(int)

    else:

        df["year"] = df["year"].astype(int)

    # --------------------------------------------------------
    # 5. DATA QUALITY VALIDATION
    # --------------------------------------------------------

    missing_values = df.isna().sum().sum()

    duplicates = df.duplicated().sum()

    dimension_columns = [
        column for column in df.columns
        if column not in [value_column, "quality_flag"]
    ]

    duplicate_keys = df.duplicated(
        subset=dimension_columns
    ).sum()

    # Validate row count
    if len(df) != original_rows:
        raise ValueError(f"Row count changed in {filename}")

    # Validate missing values
    if missing_values != original_missing:
        raise ValueError(f"Missing values changed in {filename}")

    # Validate duplicates
    if duplicates > 0 or duplicate_keys > 0:
        raise ValueError(f"Duplicate records found in {filename}")

    # Validate quality flags
    if "quality_flag" in df.columns:

        valid_flags = [
            "STANDARD",
            "LOW_RELIABILITY",
            "MISSING"
        ]

        if not df["quality_flag"].isin(valid_flags).all():
            raise ValueError(f"Invalid quality flag in {filename}")

        missing_flags = df["quality_flag"].eq("MISSING")

        if not missing_flags.equals(df[value_column].isna().astype("boolean")):
            raise ValueError(f"Inconsistent missing flags in {filename}")

    # Store validated dataset
    processed_datasets[config["output"]] = df

    print(f"Original records:       {original_rows:,}")
    print(f"Processed records:      {len(df):,}")
    print(f"Missing values:         {missing_values}")
    print(f"Low reliability:        {low_reliability}")
    print(f"Duplicate records:      {duplicates}")
    print(f"Duplicate keys:         {duplicate_keys}")
    print(f"Minimum year:           {df['year'].min()}")
    print(f"Maximum year:           {df['year'].max()}")
    print("Validation status:      PASSED")

    print("\nSample transformed data:")
    print(df.head(3).to_string(index=False))

    summary.append({
        "dataset": config["output"],
        "records": len(df),
        "missing_values": missing_values,
        "low_reliability": low_reliability,
        "duplicates": duplicates,
        "duplicate_keys": duplicate_keys,
        "status": "PASSED"
    })

# ------------------------------------------------------------
# 6. EXPORT PROCESSED DATA
# ------------------------------------------------------------

for filename, df in processed_datasets.items():

    df.to_csv(
        PROCESSED_DIR / filename,
        index=False,
        encoding="utf-8"
    )

# ------------------------------------------------------------
# 7. FINAL SUMMARY
# ------------------------------------------------------------

summary_df = pd.DataFrame(summary)

print("\n" + "=" * 70)
print("FINAL DATA QUALITY SUMMARY")
print("=" * 70)

print(summary_df.to_string(index=False))

print("\nTotal datasets processed:", len(summary_df))
print("Total records:", summary_df["records"].sum())
print("Total missing values:", summary_df["missing_values"].sum())
print("Total low reliability:", summary_df["low_reliability"].sum())
print("Total duplicates:", summary_df["duplicates"].sum())
print("Total duplicate keys:", summary_df["duplicate_keys"].sum())

print("\nAll datasets successfully validated and exported.")
print("=" * 70)