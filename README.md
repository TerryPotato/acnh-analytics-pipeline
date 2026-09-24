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
`housewares`, and `recipes`. See [Data Dictionary](#data-dictionary) below for column-level
detail, and `sql/04_create_harmonized_tables_and_procedures.sql` for the transformation rules.

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
│   ├── source/               # Original ACNH CSV files, 6 tables (read-only)
│   ├── dataset_full/         # Full 30-table ACNH dataset the 6 were pulled from (reference only, unused by the pipeline)
│   ├── csv_files/             # Demo batches (1.ingestion / 2.transformation / 3.delivery)
│   └── raw/                   # Watched folder for the ingestion pipeline
├── notebooks/                 # Exploration and step-by-step tests
│   ├── 01_exploration.ipynb
│   ├── 02_ingestion_test.ipynb
│   └── 03_transformation_test.ipynb
├── scripts/
│   └── split_batches.py       # Builds the 3 demo batches from data/source/
├── sql/                        # Schemas, raw tables, automation, transformations, views
└── src/                         # Ingestion, transformation, pipeline, file watcher
```

## How to Run

### 1. Virtual environment

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2. Configure the database connection

Copy `.env.example` to `.env` and fill in your local PostgreSQL credentials
(`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`). `.env` is
git-ignored — never commit real credentials.

### 3. Create the database and schema

Create the database once, then run the SQL scripts in `sql/` **in order**
against it (`01` → `05`):

```powershell
psql -U postgres -c "CREATE DATABASE acnh_analytics;"

psql -U postgres -d acnh_analytics -f sql\01_create_database_schemas.sql
psql -U postgres -d acnh_analytics -f sql\02_create_raw_tables.sql
psql -U postgres -d acnh_analytics -f sql\03_create_automation_tables.sql
psql -U postgres -d acnh_analytics -f sql\04_create_harmonized_tables_and_procedures.sql
psql -U postgres -d acnh_analytics -f sql\05_create_views.sql
```

(`01` also contains its own `CREATE DATABASE`, meant for running the whole
file at once from pgAdmin/VS Code against the default `postgres` connection
— if you already created the database with `psql` above, that one line will
just error out harmlessly and the rest of the script still runs.)

### 4. Seed the ingestion inbox

The pipeline only loads CSVs it finds under `data/raw/<table>/`. Demo batch 1
is the "clean first load" — copy it in to have something to ingest out of
the box:

```powershell
Copy-Item data\csv_files\1.ingestion\fish01.csv        data\raw\fish\
Copy-Item data\csv_files\1.ingestion\insects01.csv      data\raw\insects\
Copy-Item data\csv_files\1.ingestion\fossils01.csv      data\raw\fossils\
Copy-Item data\csv_files\1.ingestion\villagers01.csv    data\raw\villagers\
Copy-Item data\csv_files\1.ingestion\housewares01.csv   data\raw\housewares\
Copy-Item data\csv_files\1.ingestion\recipes01.csv      data\raw\recipes\
```

To demo incremental ingestion and deduplication, drop batches 2 and 3
(`data\csv_files\2.transformation\`, `data\csv_files\3.delivery\`) into the
same `data\raw\<table>\` folders later and re-run the pipeline — records
sharing a `Unique Entry ID` get deduplicated, keeping the most recently
loaded (and cleaned) version.

### 5. Run the pipeline

Loads new CSVs into `raw.*`, then refreshes `harmonized.*` and
`analytics.*` from them:

```powershell
python src\pipeline.py
```

Or watch `data/raw/` continuously and ingest new files as they land:

```powershell
python src\file_watcher.py
```

### 6. Launch the dashboard

```powershell
streamlit run app.py
```

Opens at http://localhost:8501.

### Optional: notebooks

`notebooks/` has three step-by-step notebooks that mirror the pipeline:

- `01_exploration.ipynb` — profiles the raw source CSVs.
- `02_ingestion_test.ipynb` — exercises `src/ingest_files.py` and checks
  `raw.*` row counts.
- `03_transformation_test.ipynb` — exercises `src/run_transformations.py`
  and queries the `analytics.*` views the dashboard uses.

```powershell
jupyter notebook notebooks/
```

## Data Dictionary

### Layers

| Schema       | Contents                                                                 |
|--------------|---------------------------------------------------------------------------|
| `raw`        | Untransformed data, exactly as it arrives from the CSVs. Every column is `TEXT`. |
| `harmonized` | Cleaned, typed, deduplicated tables, plus derived/bridge tables.          |
| `analytics`  | Views the Streamlit dashboard reads from. `app.py` never queries `raw` or `harmonized` directly. |
| `automation` | `ingestion_log` (tracks which files were loaded) and every stored procedure/function. |

### `raw.*`

One table per source CSV (`fish`, `insects`, `fossils`, `villagers`,
`housewares`, `recipes`), columns matching the original CSV headers
normalized to snake_case (see `src/ingest_files.py::normalize_column_name`):
lowercased, `/` treated as a space (`Where/How` → `where_how`), `#` →
`row_number`, `#1`..`#6` → `qty_1`..`qty_6`. Two metadata columns are added
on load: `source_file` (which CSV the row came from) and `loaded_at`
(when it was ingested). Full column list: `sql/02_create_raw_tables.sql`.

### `harmonized.*`

Built by `automation.sp_transform_all()` (`sql/04`), one procedure per
table, called in dependency order. Base tables mirror `raw.*` with types
cast, names title-cased, blank/`NFS` cells turned into `NULL`, and one row
kept per `unique_entry_id` (`DISTINCT ON`, latest `loaded_at` wins;
`housewares` also collapses color/pattern variants to one row per item).

| Table                     | What it holds                                                                 |
|---------------------------|---------------------------------------------------------------------------------|
| `fish`, `insects`         | Sell price, catch location, monthly availability (NH/SH) per hour window, appearance. |
| `fossils`                 | Buy/sell price, museum info, whether it can be interacted with.                |
| `villagers`                 | Personality, hobby, birthday (split into `birth_month`/`birth_day`), style/color, furniture list. |
| `housewares`                | Buy/sell price, customization flags, HHA category, one row per item (variants collapsed). |
| `recipes`                   | Up to 6 material/quantity pairs, buy/sell price, unlock source, category.       |
| `creatures_availability`     | Fish + insects unpivoted to one row per (creature, hemisphere, month) they're catchable. |
| `creatures_hourly`            | `creatures_availability` expanded to one row per catchable hour (powers the heatmap). |
| `villager_furniture`            | Bridge table: villager ↔ housewares `internal_id`, exploded from `villagers.furniture_list`. |
| `recipe_materials`                | Bridge table: recipe ↔ material/quantity, exploded from `recipes.material_1..6`. |

### `analytics.*` (views)

| View                          | Powers                                                              |
|--------------------------------|----------------------------------------------------------------------|
| `v_top_creatures_by_month`       | Top-10-most-profitable bar chart (ranked by `sell` per hemisphere/month). |
| `v_monthly_bell_potential`         | 12-month stacked bar chart, fish vs. insects total Bell potential.      |
| `v_leaving_next_month`                | Creatures catchable this month but gone next month.                     |
| `v_hourly_availability`                 | "Best time to go out" heatmap (hour × creature type).                    |
| `v_fossil_summary`                        | Fossil baseline stats (count, avg/min/max sell) — fossils are available year-round. |
| `v_villager_birthdays`                       | "Neighbors of the month" section.                                          |
| `v_villager_gift_ideas`                         | Furniture each villager likes, resolved through `villager_furniture`.        |
| `v_villager_recipes`                               | Recipes each personality type can be gifted.                                  |

## Docker

Build and start the Linux containers (dashboard and PostgreSQL):

```bash
docker compose up --build -d
```

Open the dashboard at <http://localhost:8501>. PostgreSQL initializes the schemas,
tables, procedures, and views automatically the first time its volume is created.
If port 8501 is occupied, set `DASHBOARD_PORT` before starting Compose.

To ingest CSV files placed under `data/raw/<source>/`, run the one-shot pipeline:

```bash
docker compose --profile tools run --rm pipeline
```

Stop the containers without deleting the database:

```bash
docker compose down
```

## Credits

Dataset: ACNH community spreadsheet (Kaggle, June 2021). Item and villager artwork
courtesy of the Animal Crossing community spreadsheet / Nintendo, served via the
unofficial community CDN `acnhcdn.com`.

---

*This README is a work-in-progress skeleton and will be expanded as the pipeline is built.*
