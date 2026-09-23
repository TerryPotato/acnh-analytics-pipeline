"""
Build the 3 demo batches (ingestion, transformation, delivery) from the
original ACNH source CSVs in data/source/.

Why 3 batches per table?
The class ITD pipeline is demonstrated incrementally, so each table is split
into three groups of rows:

    Batch 1 (data/csv_files/1.ingestion/<table>01.csv)
        Clean first load. Also copied into data/raw/<table>/ so the
        ingestion pipeline has something to pick up out of the box.

    Batch 2 (data/csv_files/2.transformation/<table>02.csv)
        Re-submits batch 1's rows (now dirty) plus a new group of rows,
        with intentional dirty data: inconsistent name casing, extra
        whitespace, blank prices, and duplicated rows.

    Batch 3 (data/csv_files/3.delivery/<table>03.csv)
        Re-submits batch 2's new rows (dirtier still) plus the final group
        of rows, with even more dirty data and duplicates.

Re-submitting rows across batches with the same Unique Entry ID (but messier
data) is what gives sql/04's DISTINCT ON (unique_entry_id) ORDER BY
loaded_at DESC deduplication something real to demonstrate: raw accumulates
every batch, and harmonized always keeps the latest, cleaned version.

Prices are blanked at random, but every item keeps its real price in at least
one batch (see ensure_price_survives), so dedup can always recover it.

Run from the project root:

    python scripts\\split_batches.py
"""

from pathlib import Path
import random

import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent
SOURCE_DIR = BASE_DIR / "data" / "source"
CSV_FILES_DIR = BASE_DIR / "data" / "csv_files"
RAW_DIR = BASE_DIR / "data" / "raw"

TABLES = ["fish", "insects", "fossils", "villagers", "housewares", "recipes"]

# Fixed seed so the batches are reproducible across teammates' machines.
RANDOM_SEED = 42

# Column holding the display name we can mangle (casing / whitespace).
NAME_COLUMNS = {
    "fish": "Name",
    "insects": "Name",
    "fossils": "Name",
    "villagers": "Name",
    "housewares": "Name",
    "recipes": "Name",
}

# Price-like columns per table that exist and are safe to blank out.
# fish/insects only have Sell; villagers has neither.
PRICE_COLUMNS = {
    "fish": ["Sell"],
    "insects": ["Sell"],
    "fossils": ["Buy", "Sell"],
    "villagers": [],
    "housewares": ["Buy", "Sell"],
    "recipes": ["Buy", "Sell"],
}


def dirty_name(value: str, rng: random.Random) -> str:
    """Randomly mangle the casing and whitespace of a name value."""
    if not isinstance(value, str) or not value:
        return value

    choice = rng.random()
    if choice < 0.34:
        value = value.lower()
    elif choice < 0.67:
        value = value.upper()

    if rng.random() < 0.5:
        value = f"  {value}  "

    return value


def blank_out_price(value: str, rng: random.Random) -> str:
    """Randomly blank a price value to simulate missing/dirty data."""
    if rng.random() < 0.15:
        return ""
    return value


def make_dirty(df: pd.DataFrame, table: str, rng: random.Random) -> pd.DataFrame:
    """Return a copy of df with intentional dirty data injected."""
    df = df.copy()

    name_col = NAME_COLUMNS.get(table)
    if name_col and name_col in df.columns:
        df[name_col] = df[name_col].apply(lambda v: dirty_name(v, rng))

    for col in PRICE_COLUMNS.get(table, []):
        if col in df.columns:
            df[col] = df[col].apply(lambda v: blank_out_price(v, rng))

    return df


def duplicate_some_rows(df: pd.DataFrame, rng: random.Random, frac: float = 0.1) -> pd.DataFrame:
    """Append duplicated rows to simulate re-submitted / duplicate records."""
    if df.empty:
        return df

    n_dupes = max(1, int(len(df) * frac))
    dupes = df.sample(n=n_dupes, random_state=rng.randint(0, 1_000_000))
    return pd.concat([df, dupes], ignore_index=True)


def ensure_price_survives(batches: list[pd.DataFrame], source: pd.DataFrame, table: str) -> None:
    """
    Guarantee every item keeps its original price in at least one batch.

    make_dirty blanks prices at random, so an item that only ever appears in
    dirty batches (e.g. group C, which only ships in batch 3) can lose its
    price in every version, and no dedup rule can recover it. In a real feed
    one file may arrive broken, but not every version of the same record.

    For each price column, any Unique Entry ID left blank in all batches gets
    its source value restored in its first row of the earliest batch it
    appears in. Every other dirty value is left untouched. This step draws
    nothing from the RNG, so the rest of the output stays reproducible.
    """
    original = source.set_index("Unique Entry ID")

    for col in PRICE_COLUMNS.get(table, []):
        if col not in source.columns:
            continue

        survived = set()
        for batch in batches:
            has_price = batch[col].fillna("").str.strip().ne("")
            survived.update(batch.loc[has_price, "Unique Entry ID"])

        restored = 0
        for batch in batches:
            ids = batch["Unique Entry ID"]
            lost = batch[~ids.isin(survived)].drop_duplicates("Unique Entry ID")
            for idx, entry_id in lost["Unique Entry ID"].items():
                value = original.at[entry_id, col]
                if value.strip():
                    batch.at[idx, col] = value
                    restored += 1
                survived.add(entry_id)

        if restored:
            print(f"  Restored {col} for {restored} item(s) blanked in every batch")


def write_batch(df: pd.DataFrame, table: str, batch_number: int, folder: Path) -> None:
    """Write one batch CSV, creating the destination folder if needed."""
    folder.mkdir(parents=True, exist_ok=True)
    file_path = folder / f"{table}0{batch_number}.csv"
    df.to_csv(file_path, index=False, encoding="utf-8-sig")
    print(f"  Wrote {len(df):>5} rows -> {file_path.relative_to(BASE_DIR)}")


def split_table(table: str, rng: random.Random) -> None:
    """Build and write the 3 demo batches for one table."""
    source_path = SOURCE_DIR / f"{table}.csv"
    df = pd.read_csv(source_path, dtype=str, encoding="utf-8-sig", keep_default_na=False)

    # Shuffle once so the 3 groups are a random sample of the table,
    # not just the first/last N rows in the original file.
    df = df.sample(frac=1, random_state=RANDOM_SEED).reset_index(drop=True)

    thirds = len(df) // 3
    group_a = df.iloc[:thirds]
    group_b = df.iloc[thirds : thirds * 2]
    group_c = df.iloc[thirds * 2 :]

    # Batch 1: clean first load, group A only.
    batch_01 = group_a.copy()

    # Batch 2: group A resubmitted dirty (tests dedup) + new group B, also dirty.
    batch_02 = pd.concat([group_a, group_b], ignore_index=True)
    batch_02 = make_dirty(batch_02, table, rng)
    batch_02 = duplicate_some_rows(batch_02, rng, frac=0.10)

    # Batch 3: group B resubmitted even dirtier + new group C, dirty too.
    batch_03 = pd.concat([group_b, group_c], ignore_index=True)
    batch_03 = make_dirty(batch_03, table, rng)
    batch_03 = make_dirty(batch_03, table, rng)  # applied twice: dirtier than batch 2
    batch_03 = duplicate_some_rows(batch_03, rng, frac=0.15)

    ensure_price_survives([batch_01, batch_02, batch_03], df, table)

    write_batch(batch_01, table, 1, CSV_FILES_DIR / "1.ingestion")
    write_batch(batch_02, table, 2, CSV_FILES_DIR / "2.transformation")
    write_batch(batch_03, table, 3, CSV_FILES_DIR / "3.delivery")

    # Seed the watched folder with the clean first load so the ingestion
    # pipeline has something to process out of the box. Batches 2 and 3 are
    # meant to be dropped into data/raw/<table>/ manually during the demo,
    # to show the file watcher and the dedup logic in action.
    write_batch(batch_01, table, 1, RAW_DIR / table)


def main() -> None:
    rng = random.Random(RANDOM_SEED)

    for table in TABLES:
        print(f"\n=== {table} ===")
        split_table(table, rng)

    print("\nDone. Batches 2 and 3 are staged in data/csv_files/ — "
          "drop them into data/raw/<table>/ during the demo to show "
          "incremental ingestion and deduplication.")


if __name__ == "__main__":
    main()
