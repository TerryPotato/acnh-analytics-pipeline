-- ============================================================
-- Database and schemas
-- ============================================================

-- Run this script once, connected to the default "postgres" database.
-- The database name must stay in sync with .env / .env.example (DB_NAME).

CREATE DATABASE acnh_analytics;

-- After creating the database, reconnect to it before running the rest
-- of this script (in psql: \c acnh_analytics — in pgAdmin/VS Code, just
-- switch the active connection to acnh_analytics).

-- raw:        untransformed data, exactly as it arrives from CSV files.
-- harmonized: cleaned, typed, deduplicated tables and derived tables.
-- analytics:  views consumed by the Streamlit dashboard.
-- automation: ingestion_log table and all stored procedures.
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS harmonized;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS automation;
