# ACNH Analytics Pipeline — Monthly Bell Guide

End-to-end data analytics pipeline (Ingestion → Transformation → Delivery) built on the
*Animal Crossing: New Horizons* dataset, for the **New Technologies on IT — Data Analytics**
course at Universidad Anáhuac Mayab.

> **Business question:** How can I earn more Bells this month?

## Team

Pamela, Julio, Luis, Yovana, Marco.

## Project Overview

The pipeline follows a layered data architecture:

```text
CSV files (data/source, data/raw)
   ↓
raw schema        (untransformed data, exactly as it arrives)
   ↓
harmonized schema  (cleaned, typed, deduplicated)
   ↓
analytics schema   (views consumed by the dashboard)
   ↓
Streamlit dashboard (Monthly Bell Guide)
```

Six tables from the ACNH dataset are used: `fish`, `insects`, `fossils`, `villagers`,
`housewares`, and `recipes`. See [`CLAUDE.md`](./CLAUDE.md) for the full data dictionary,
transformation rules, and dashboard spec.

## Tech Stack

- Python 3
- PostgreSQL
- SQLAlchemy / psycopg2
- pandas
- python-dotenv
- watchdog
- Streamlit
- Plotly
- Jupyter Notebook

## Repository Structure

```text
acnh-analytics-pipeline/
├── app.py                  # Streamlit dashboard
├── assets/images/          # Optional local image backup
├── data/
│   ├── source/              # Original ACNH CSV files (read-only)
│   ├── csv_files/            # Demo batches (1.ingestion / 2.transformation / 3.delivery)
│   └── raw/                  # Watched folder for the ingestion pipeline
├── notebooks/                # Exploration and step-by-step tests
├── scripts/
│   └── split_batches.py      # Builds the 3 demo batches from data/source/
├── sql/                       # Schemas, raw tables, automation, transformations, views
└── src/                        # Ingestion, transformation, pipeline, file watcher
```

## Setup

1. Create and activate a virtual environment (PowerShell):

   ```powershell
   python -m venv .venv
   .venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```

2. Copy `.env.example` to `.env` and fill in your local PostgreSQL credentials.

3. Create the database and run the SQL scripts in `sql/` in order (`01` → `05`).

4. Run the pipeline:

   ```powershell
   python src\pipeline.py
   ```

5. Launch the dashboard:

   ```powershell
   streamlit run app.py
   ```

## Credits

Dataset: ACNH community spreadsheet (Kaggle, June 2021). Item and villager artwork
courtesy of the Animal Crossing community spreadsheet / Nintendo, served via the
unofficial community CDN `acnhcdn.com`.

---

*This README is a work-in-progress skeleton and will be expanded as the pipeline is built.*
