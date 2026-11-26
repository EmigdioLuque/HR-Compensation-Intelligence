# ============================================================
# HR COMPENSATION INTELLIGENCE
# PostgreSQL Database Connection
# ============================================================

import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


# ------------------------------------------------------------
# 1. DATABASE CONFIGURATION
# ------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parents[1]

load_dotenv(BASE_DIR / ".env")

DATABASE_URL = URL.create(
    drivername="postgresql+psycopg2",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT", "2525")),
    database=os.getenv("DB_NAME")
)


# ------------------------------------------------------------
# 2. DATABASE ENGINE
# ------------------------------------------------------------

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True
)


# ------------------------------------------------------------
# 3. QUERY EXECUTION
# ------------------------------------------------------------

def run_query(query, params=None):

    with engine.connect() as connection:

        return pd.read_sql(
            text(query),
            connection,
            params=params
        )


# ------------------------------------------------------------
# 4. CONNECTION TEST
# ------------------------------------------------------------

if __name__ == "__main__":

    print("=" * 60)
    print("HR COMPENSATION INTELLIGENCE")
    print("DATABASE CONNECTION TEST")
    print("=" * 60)

    result = run_query("""
        SELECT
            current_database() AS database_name,
            current_user AS database_user,
            version() AS postgresql_version;
    """)

    print(result.to_string(index=False))

    views = run_query("""
        SELECT COUNT(*) AS analytical_views
        FROM information_schema.views
        WHERE table_schema = 'analytics';
    """)

    print("\nAnalytical views:", views.iloc[0, 0])

    print("\nDatabase connection successful.")
    print("=" * 60)