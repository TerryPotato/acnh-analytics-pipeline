-- ============================================================
-- Raw tables
-- ============================================================
-- Every column is TEXT: raw keeps the data exactly as it arrives from
-- the CSV files, with no casting or cleanup. Typing and cleaning happen
-- in the harmonized layer (sql/04).
--
-- Column names are the snake_case version of the original CSV headers
-- (see CLAUDE.md section 8 / src/ingest_files.py for the normalization
-- rules, e.g. "#" -> row_number, "Where/How" -> where_how,
-- "NH Jan" -> nh_jan, "Unique Entry ID" -> unique_entry_id).
--
-- source_file and loaded_at are metadata added by the ingestion script,
-- not part of the original CSV.

-- ============================================================
-- Fish
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.fish (
    row_number              TEXT,
    name                    TEXT,
    sell                    TEXT,
    where_how               TEXT,
    shadow                  TEXT,
    total_catches_to_unlock TEXT,
    spawn_rates             TEXT,
    rain_snow_catch_up      TEXT,
    nh_jan                  TEXT,
    nh_feb                  TEXT,
    nh_mar                  TEXT,
    nh_apr                  TEXT,
    nh_may                  TEXT,
    nh_jun                  TEXT,
    nh_jul                  TEXT,
    nh_aug                  TEXT,
    nh_sep                  TEXT,
    nh_oct                  TEXT,
    nh_nov                  TEXT,
    nh_dec                  TEXT,
    sh_jan                  TEXT,
    sh_feb                  TEXT,
    sh_mar                  TEXT,
    sh_apr                  TEXT,
    sh_may                  TEXT,
    sh_jun                  TEXT,
    sh_jul                  TEXT,
    sh_aug                  TEXT,
    sh_sep                  TEXT,
    sh_oct                  TEXT,
    sh_nov                  TEXT,
    sh_dec                  TEXT,
    color_1                 TEXT,
    color_2                 TEXT,
    size                    TEXT,
    lighting_type           TEXT,
    icon_filename           TEXT,
    critterpedia_filename   TEXT,
    furniture_filename      TEXT,
    internal_id             TEXT,
    unique_entry_id         TEXT,
    source_file             TEXT,
    loaded_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Insects
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.insects (
    row_number              TEXT,
    name                    TEXT,
    sell                    TEXT,
    where_how               TEXT,
    weather                 TEXT,
    total_catches_to_unlock TEXT,
    spawn_rates             TEXT,
    nh_jan                  TEXT,
    nh_feb                  TEXT,
    nh_mar                  TEXT,
    nh_apr                  TEXT,
    nh_may                  TEXT,
    nh_jun                  TEXT,
    nh_jul                  TEXT,
    nh_aug                  TEXT,
    nh_sep                  TEXT,
    nh_oct                  TEXT,
    nh_nov                  TEXT,
    nh_dec                  TEXT,
    sh_jan                  TEXT,
    sh_feb                  TEXT,
    sh_mar                  TEXT,
    sh_apr                  TEXT,
    sh_may                  TEXT,
    sh_jun                  TEXT,
    sh_jul                  TEXT,
    sh_aug                  TEXT,
    sh_sep                  TEXT,
    sh_oct                  TEXT,
    sh_nov                  TEXT,
    sh_dec                  TEXT,
    color_1                 TEXT,
    color_2                 TEXT,
    icon_filename           TEXT,
    critterpedia_filename   TEXT,
    furniture_filename      TEXT,
    internal_id             TEXT,
    unique_entry_id         TEXT,
    source_file             TEXT,
    loaded_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Fossils
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.fossils (
    name            TEXT,
    buy             TEXT,
    sell            TEXT,
    color_1         TEXT,
    color_2         TEXT,
    size            TEXT,
    source          TEXT,
    museum          TEXT,
    version         TEXT,
    interact        TEXT,
    catalog         TEXT,
    filename        TEXT,
    internal_id     TEXT,
    unique_entry_id TEXT,
    source_file     TEXT,
    loaded_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Villagers
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.villagers (
    name            TEXT,
    species         TEXT,
    gender          TEXT,
    personality     TEXT,
    hobby           TEXT,
    birthday        TEXT,
    catchphrase     TEXT,
    favorite_song   TEXT,
    style_1         TEXT,
    style_2         TEXT,
    color_1         TEXT,
    color_2         TEXT,
    wallpaper       TEXT,
    flooring        TEXT,
    furniture_list  TEXT,
    filename        TEXT,
    unique_entry_id TEXT,
    source_file     TEXT,
    loaded_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Housewares
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.housewares (
    name                TEXT,
    variation           TEXT,
    body_title          TEXT,
    pattern             TEXT,
    pattern_title       TEXT,
    diy                 TEXT,
    body_customize      TEXT,
    pattern_customize   TEXT,
    kit_cost            TEXT,
    buy                 TEXT,
    sell                TEXT,
    color_1             TEXT,
    color_2             TEXT,
    size                TEXT,
    miles_price         TEXT,
    source              TEXT,
    source_notes        TEXT,
    version             TEXT,
    hha_concept_1       TEXT,
    hha_concept_2       TEXT,
    hha_series          TEXT,
    hha_set             TEXT,
    interact            TEXT,
    tag                 TEXT,
    outdoor             TEXT,
    speaker_type        TEXT,
    lighting_type       TEXT,
    catalog             TEXT,
    filename            TEXT,
    variant_id          TEXT,
    internal_id         TEXT,
    unique_entry_id     TEXT,
    source_file         TEXT,
    loaded_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Recipes
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.recipes (
    name                TEXT,
    qty_1               TEXT,
    material_1          TEXT,
    qty_2               TEXT,
    material_2          TEXT,
    qty_3               TEXT,
    material_3          TEXT,
    qty_4               TEXT,
    material_4          TEXT,
    qty_5               TEXT,
    material_5          TEXT,
    qty_6               TEXT,
    material_6          TEXT,
    buy                 TEXT,
    sell                TEXT,
    miles_price         TEXT,
    source              TEXT,
    source_notes        TEXT,
    recipes_to_unlock   TEXT,
    version             TEXT,
    category            TEXT,
    serial_id           TEXT,
    internal_id         TEXT,
    unique_entry_id     TEXT,
    source_file         TEXT,
    loaded_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
