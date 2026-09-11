-- ============================================================
-- Harmonized tables and transformation procedures
-- ============================================================
-- Each raw.<table> has one automation.sp_transform_<table>() procedure
-- that TRUNCATEs the harmonized table and re-INSERTs cleaned, typed data
-- from raw.
--
-- Deduplication: raw accumulates every ingested batch (the same item can
-- appear more than once across batches, sometimes with dirtier data than
-- before). DISTINCT ON (unique_entry_id) ORDER BY unique_entry_id,
-- loaded_at DESC always keeps the most recently loaded version of each
-- item, which is also the version the transformation cleans.
--
-- source_file is carried into harmonized so a row's origin stays
-- traceable after transformation.
-- ============================================================
-- Fish
-- ============================================================

CREATE TABLE IF NOT EXISTS harmonized.fish (
    unique_entry_id          TEXT,
    internal_id               TEXT,
    name                       TEXT,
    sell                       INTEGER,
    where_how                  TEXT,
    shadow                     TEXT,
    total_catches_to_unlock    INTEGER,
    spawn_rates                TEXT,
    rain_snow_catch_up         BOOLEAN,
    nh_jan                   TEXT,
    nh_feb                   TEXT,
    nh_mar                   TEXT,
    nh_apr                   TEXT,
    nh_may                   TEXT,
    nh_jun                   TEXT,
    nh_jul                   TEXT,
    nh_aug                   TEXT,
    nh_sep                   TEXT,
    nh_oct                   TEXT,
    nh_nov                   TEXT,
    nh_dec                   TEXT,
    sh_jan                   TEXT,
    sh_feb                   TEXT,
    sh_mar                   TEXT,
    sh_apr                   TEXT,
    sh_may                   TEXT,
    sh_jun                   TEXT,
    sh_jul                   TEXT,
    sh_aug                   TEXT,
    sh_sep                   TEXT,
    sh_oct                   TEXT,
    sh_nov                   TEXT,
    sh_dec                   TEXT,
    color_1                    TEXT,
    color_2                    TEXT,
    size                       TEXT,
    lighting_type              TEXT,
    icon_url                    TEXT,
    furniture_url                TEXT,
    source_file                   TEXT,
    transformed_at                 TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_fish()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.fish;

    INSERT INTO harmonized.fish (
        unique_entry_id,
        internal_id,
        name,
        sell,
        where_how,
        shadow,
        total_catches_to_unlock,
        spawn_rates,
        rain_snow_catch_up,
        nh_jan,
        nh_feb,
        nh_mar,
        nh_apr,
        nh_may,
        nh_jun,
        nh_jul,
        nh_aug,
        nh_sep,
        nh_oct,
        nh_nov,
        nh_dec,
        sh_jan,
        sh_feb,
        sh_mar,
        sh_apr,
        sh_may,
        sh_jun,
        sh_jul,
        sh_aug,
        sh_sep,
        sh_oct,
        sh_nov,
        sh_dec,
        color_1,
        color_2,
        size,
        lighting_type,
        icon_url,
        furniture_url,
        source_file
    )
    SELECT DISTINCT ON (unique_entry_id)
        unique_entry_id,
        internal_id,
        INITCAP(TRIM(name)) AS name,
        NULLIF(TRIM(sell), '')::INTEGER AS sell,
        where_how,
        shadow,
        NULLIF(TRIM(total_catches_to_unlock), '')::INTEGER AS total_catches_to_unlock,
        spawn_rates,
        CASE
            WHEN LOWER(TRIM(rain_snow_catch_up)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(rain_snow_catch_up)) = 'no' THEN FALSE
            ELSE NULL
        END AS rain_snow_catch_up,
        nh_jan,
        nh_feb,
        nh_mar,
        nh_apr,
        nh_may,
        nh_jun,
        nh_jul,
        nh_aug,
        nh_sep,
        nh_oct,
        nh_nov,
        nh_dec,
        sh_jan,
        sh_feb,
        sh_mar,
        sh_apr,
        sh_may,
        sh_jun,
        sh_jul,
        sh_aug,
        sh_sep,
        sh_oct,
        sh_nov,
        sh_dec,
        color_1,
        color_2,
        size,
        lighting_type,
        CASE WHEN NULLIF(TRIM(icon_filename), '') IS NOT NULL
            THEN 'https://acnhcdn.com/latest/MenuIcon/' || TRIM(icon_filename) || '.png'
        END AS icon_url,
        CASE WHEN NULLIF(TRIM(furniture_filename), '') IS NOT NULL
            THEN 'https://acnhcdn.com/latest/FtrIcon/' || TRIM(furniture_filename) || '.png'
        END AS furniture_url,
        source_file
    FROM raw.fish
    WHERE unique_entry_id IS NOT NULL
    -- Prefer a batch where Sell survived intact over a dirtier later batch
    -- that blanked it out; among equally complete batches, keep the latest.
    ORDER BY unique_entry_id, (NULLIF(TRIM(sell), '') IS NULL), loaded_at DESC;
END;
$$;

-- ============================================================
-- Insects
-- ============================================================

CREATE TABLE IF NOT EXISTS harmonized.insects (
    unique_entry_id          TEXT,
    internal_id               TEXT,
    name                       TEXT,
    sell                       INTEGER,
    where_how                  TEXT,
    weather                    TEXT,
    total_catches_to_unlock    INTEGER,
    spawn_rates                TEXT,
    nh_jan                   TEXT,
    nh_feb                   TEXT,
    nh_mar                   TEXT,
    nh_apr                   TEXT,
    nh_may                   TEXT,
    nh_jun                   TEXT,
    nh_jul                   TEXT,
    nh_aug                   TEXT,
    nh_sep                   TEXT,
    nh_oct                   TEXT,
    nh_nov                   TEXT,
    nh_dec                   TEXT,
    sh_jan                   TEXT,
    sh_feb                   TEXT,
    sh_mar                   TEXT,
    sh_apr                   TEXT,
    sh_may                   TEXT,
    sh_jun                   TEXT,
    sh_jul                   TEXT,
    sh_aug                   TEXT,
    sh_sep                   TEXT,
    sh_oct                   TEXT,
    sh_nov                   TEXT,
    sh_dec                   TEXT,
    color_1                    TEXT,
    color_2                    TEXT,
    icon_url                    TEXT,
    furniture_url                 TEXT,
    source_file                    TEXT,
    transformed_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_insects()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.insects;

    INSERT INTO harmonized.insects (
        unique_entry_id,
        internal_id,
        name,
        sell,
        where_how,
        weather,
        total_catches_to_unlock,
        spawn_rates,
        nh_jan,
        nh_feb,
        nh_mar,
        nh_apr,
        nh_may,
        nh_jun,
        nh_jul,
        nh_aug,
        nh_sep,
        nh_oct,
        nh_nov,
        nh_dec,
        sh_jan,
        sh_feb,
        sh_mar,
        sh_apr,
        sh_may,
        sh_jun,
        sh_jul,
        sh_aug,
        sh_sep,
        sh_oct,
        sh_nov,
        sh_dec,
        color_1,
        color_2,
        icon_url,
        furniture_url,
        source_file
    )
    SELECT DISTINCT ON (unique_entry_id)
        unique_entry_id,
        internal_id,
        INITCAP(TRIM(name)) AS name,
        NULLIF(TRIM(sell), '')::INTEGER AS sell,
        where_how,
        weather,
        NULLIF(TRIM(total_catches_to_unlock), '')::INTEGER AS total_catches_to_unlock,
        spawn_rates,
        nh_jan,
        nh_feb,
        nh_mar,
        nh_apr,
        nh_may,
        nh_jun,
        nh_jul,
        nh_aug,
        nh_sep,
        nh_oct,
        nh_nov,
        nh_dec,
        sh_jan,
        sh_feb,
        sh_mar,
        sh_apr,
        sh_may,
        sh_jun,
        sh_jul,
        sh_aug,
        sh_sep,
        sh_oct,
        sh_nov,
        sh_dec,
        color_1,
        color_2,
        CASE WHEN NULLIF(TRIM(icon_filename), '') IS NOT NULL
            THEN 'https://acnhcdn.com/latest/MenuIcon/' || TRIM(icon_filename) || '.png'
        END AS icon_url,
        CASE WHEN NULLIF(TRIM(furniture_filename), '') IS NOT NULL
            THEN 'https://acnhcdn.com/latest/FtrIcon/' || TRIM(furniture_filename) || '.png'
        END AS furniture_url,
        source_file
    FROM raw.insects
    WHERE unique_entry_id IS NOT NULL
    -- Prefer a batch where Sell survived intact over a dirtier later batch
    -- that blanked it out; among equally complete batches, keep the latest.
    ORDER BY unique_entry_id, (NULLIF(TRIM(sell), '') IS NULL), loaded_at DESC;
END;
$$;

-- ============================================================
-- Fossils
-- ============================================================

CREATE TABLE IF NOT EXISTS harmonized.fossils (
    unique_entry_id TEXT,
    internal_id     TEXT,
    name            TEXT,
    buy             INTEGER,
    sell            INTEGER,
    color_1         TEXT,
    color_2         TEXT,
    size            TEXT,
    source          TEXT,
    museum          TEXT,
    version         TEXT,
    interact        BOOLEAN,
    catalog         TEXT,
    source_file     TEXT,
    transformed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_fossils()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.fossils;

    INSERT INTO harmonized.fossils (
        unique_entry_id,
        internal_id,
        name,
        buy,
        sell,
        color_1,
        color_2,
        size,
        source,
        museum,
        version,
        interact,
        catalog,
        source_file
    )
    SELECT DISTINCT ON (unique_entry_id)
        unique_entry_id,
        internal_id,
        INITCAP(TRIM(name)) AS name,
        -- "NFS" (Not For Sale) and blank cells both become NULL.
        NULLIF(NULLIF(TRIM(buy), ''), 'NFS')::INTEGER AS buy,
        NULLIF(TRIM(sell), '')::INTEGER AS sell,
        color_1,
        color_2,
        size,
        source,
        museum,
        version,
        CASE
            WHEN LOWER(TRIM(interact)) = 'yes' THEN TRUE
            WHEN LOWER(TRIM(interact)) = 'no' THEN FALSE
            ELSE NULL
        END AS interact,
        catalog,
        source_file
    FROM raw.fossils
    WHERE unique_entry_id IS NOT NULL
    -- Prefer a batch where Sell (and a real Buy, when not genuinely NFS)
    -- survived intact over a dirtier later batch that blanked it out;
    -- among equally complete batches, keep the latest.
    ORDER BY unique_entry_id,
             (NULLIF(TRIM(sell), '') IS NULL),
             (NULLIF(NULLIF(TRIM(buy), ''), 'NFS') IS NULL),
             loaded_at DESC;
END;
$$;

-- ============================================================
-- Villagers
-- ============================================================

CREATE TABLE IF NOT EXISTS harmonized.villagers (
    unique_entry_id TEXT,
    name            TEXT,
    species         TEXT,
    gender          TEXT,
    personality     TEXT,
    hobby           TEXT,
    birthday        TEXT,
    birth_month     INTEGER,
    birth_day       INTEGER,
    catchphrase     TEXT,
    favorite_song   TEXT,
    style_1         TEXT,
    style_2         TEXT,
    color_1         TEXT,
    color_2         TEXT,
    wallpaper       TEXT,
    flooring        TEXT,
    furniture_list  TEXT,
    icon_url        TEXT,
    source_file     TEXT,
    transformed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_villagers()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.villagers;

    INSERT INTO harmonized.villagers (
        unique_entry_id,
        name,
        species,
        gender,
        personality,
        hobby,
        birthday,
        birth_month,
        birth_day,
        catchphrase,
        favorite_song,
        style_1,
        style_2,
        color_1,
        color_2,
        wallpaper,
        flooring,
        furniture_list,
        icon_url,
        source_file
    )
    SELECT DISTINCT ON (unique_entry_id)
        unique_entry_id,
        INITCAP(TRIM(name)) AS name,
        INITCAP(TRIM(species)) AS species,
        INITCAP(TRIM(gender)) AS gender,
        INITCAP(TRIM(personality)) AS personality,
        INITCAP(TRIM(hobby)) AS hobby,
        birthday,
        -- Birthday is "D-Mon" (e.g. "27-Jan"). A dummy leap year (2000) is
        -- appended only so TO_DATE can parse the day/month; the year itself
        -- is discarded, since ACNH villagers do not have a birth year.
        EXTRACT(MONTH FROM TO_DATE(TRIM(birthday) || '-2000', 'DD-Mon-YYYY'))::INTEGER AS birth_month,
        EXTRACT(DAY FROM TO_DATE(TRIM(birthday) || '-2000', 'DD-Mon-YYYY'))::INTEGER AS birth_day,
        catchphrase,
        favorite_song,
        style_1,
        style_2,
        color_1,
        color_2,
        wallpaper,
        flooring,
        furniture_list,
        CASE WHEN NULLIF(TRIM(filename), '') IS NOT NULL
            THEN 'https://acnhcdn.com/latest/NpcIcon/' || TRIM(filename) || '.png'
        END AS icon_url,
        source_file
    FROM raw.villagers
    WHERE unique_entry_id IS NOT NULL
    ORDER BY unique_entry_id, loaded_at DESC;
END;
$$;

-- ============================================================
-- Housewares
-- ============================================================

CREATE TABLE IF NOT EXISTS harmonized.housewares (
    unique_entry_id    TEXT,
    internal_id        TEXT,
    name               TEXT,
    variation          TEXT,
    diy                BOOLEAN,
    body_customize     BOOLEAN,
    pattern_customize  BOOLEAN,
    buy                INTEGER,
    sell               INTEGER,
    size               TEXT,
    miles_price        INTEGER,
    source             TEXT,
    source_notes       TEXT,
    hha_concept_1      TEXT,
    hha_concept_2      TEXT,
    hha_series         TEXT,
    hha_set            TEXT,
    -- Not a plain Yes/No column: also holds values like Wardrobe/Workbench/Trash.
    interact           TEXT,
    tag                TEXT,
    outdoor            BOOLEAN,
    speaker_type       TEXT,
    lighting_type      TEXT,
    source_file        TEXT,
    transformed_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_housewares()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.housewares;

    -- housewares has two layers of duplication to resolve:
    -- 1. raw_dedup:  the same unique_entry_id can be re-submitted across
    --    ingestion batches (keep the latest load per row).
    -- 2. item_dedup: each item has one row per color/pattern variation
    --    (~1,219 extra rows), all sharing the same internal_id. The
    --    dashboard only needs one canonical row per item, and internal_id
    --    is also the key villagers.furniture_list points to.
    --
    --    Picking which variant survives also decides which Buy/Sell value
    --    the item keeps: the demo's dirty batches blank out some Sell
    --    prices, so a plain tie-break can land on a blanked-out variant
    --    even when a variant with the real price also exists. Ordering by
    --    "has a real sell price" (then "has a real buy price") first makes
    --    item_dedup prefer a complete row over an incomplete one; a blank
    --    only survives when every variant of that item is blank. This does
    --    NOT affect genuinely NFS items — every variant of those already
    --    has Buy = 'NFS', so the tie-break falls through unaffected.
    WITH raw_dedup AS (
        SELECT DISTINCT ON (unique_entry_id) *
        FROM raw.housewares
        WHERE unique_entry_id IS NOT NULL
          AND internal_id IS NOT NULL
        ORDER BY unique_entry_id, loaded_at DESC
    ),
    item_dedup AS (
        SELECT DISTINCT ON (internal_id) *
        FROM raw_dedup
        ORDER BY
            internal_id,
            (NULLIF(TRIM(sell), '') IS NULL),
            (NULLIF(NULLIF(TRIM(buy), ''), 'NFS') IS NULL),
            unique_entry_id
    )
    INSERT INTO harmonized.housewares (
        unique_entry_id,
        internal_id,
        name,
        variation,
        diy,
        body_customize,
        pattern_customize,
        buy,
        sell,
        size,
        miles_price,
        source,
        source_notes,
        hha_concept_1,
        hha_concept_2,
        hha_series,
        hha_set,
        interact,
        tag,
        outdoor,
        speaker_type,
        lighting_type,
        source_file
    )
    SELECT
        unique_entry_id,
        internal_id,
        INITCAP(TRIM(name)) AS name,
        variation,
        CASE WHEN LOWER(TRIM(diy)) = 'yes' THEN TRUE WHEN LOWER(TRIM(diy)) = 'no' THEN FALSE END AS diy,
        CASE WHEN LOWER(TRIM(body_customize)) = 'yes' THEN TRUE WHEN LOWER(TRIM(body_customize)) = 'no' THEN FALSE END AS body_customize,
        CASE WHEN LOWER(TRIM(pattern_customize)) = 'yes' THEN TRUE WHEN LOWER(TRIM(pattern_customize)) = 'no' THEN FALSE END AS pattern_customize,
        NULLIF(NULLIF(TRIM(buy), ''), 'NFS')::INTEGER AS buy,
        NULLIF(TRIM(sell), '')::INTEGER AS sell,
        size,
        NULLIF(TRIM(miles_price), '')::INTEGER AS miles_price,
        source,
        source_notes,
        hha_concept_1,
        hha_concept_2,
        hha_series,
        hha_set,
        interact,
        tag,
        CASE WHEN LOWER(TRIM(outdoor)) = 'yes' THEN TRUE WHEN LOWER(TRIM(outdoor)) = 'no' THEN FALSE END AS outdoor,
        speaker_type,
        lighting_type,
        source_file
    FROM item_dedup;
END;
$$;

-- ============================================================
-- Recipes
-- ============================================================

CREATE TABLE IF NOT EXISTS harmonized.recipes (
    unique_entry_id     TEXT,
    internal_id         TEXT,
    name                TEXT,
    qty_1               INTEGER,
    material_1          TEXT,
    qty_2               INTEGER,
    material_2          TEXT,
    qty_3               INTEGER,
    material_3          TEXT,
    qty_4               INTEGER,
    material_4          TEXT,
    qty_5               INTEGER,
    material_5          TEXT,
    qty_6               INTEGER,
    material_6          TEXT,
    buy                 INTEGER,
    sell                INTEGER,
    miles_price         INTEGER,
    source              TEXT,
    source_notes        TEXT,
    recipes_to_unlock   INTEGER,
    category            TEXT,
    serial_id           TEXT,
    source_file         TEXT,
    transformed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_recipes()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.recipes;

    INSERT INTO harmonized.recipes (
        unique_entry_id,
        internal_id,
        name,
        qty_1, material_1,
        qty_2, material_2,
        qty_3, material_3,
        qty_4, material_4,
        qty_5, material_5,
        qty_6, material_6,
        buy,
        sell,
        miles_price,
        source,
        source_notes,
        recipes_to_unlock,
        category,
        serial_id,
        source_file
    )
    SELECT DISTINCT ON (unique_entry_id)
        unique_entry_id,
        internal_id,
        INITCAP(TRIM(name)) AS name,
        NULLIF(TRIM(qty_1), '')::INTEGER, NULLIF(TRIM(material_1), ''),
        NULLIF(TRIM(qty_2), '')::INTEGER, NULLIF(TRIM(material_2), ''),
        NULLIF(TRIM(qty_3), '')::INTEGER, NULLIF(TRIM(material_3), ''),
        NULLIF(TRIM(qty_4), '')::INTEGER, NULLIF(TRIM(material_4), ''),
        NULLIF(TRIM(qty_5), '')::INTEGER, NULLIF(TRIM(material_5), ''),
        NULLIF(TRIM(qty_6), '')::INTEGER, NULLIF(TRIM(material_6), ''),
        NULLIF(NULLIF(TRIM(buy), ''), 'NFS')::INTEGER AS buy,
        NULLIF(TRIM(sell), '')::INTEGER AS sell,
        NULLIF(TRIM(miles_price), '')::INTEGER AS miles_price,
        source,
        source_notes,
        NULLIF(TRIM(recipes_to_unlock), '')::INTEGER AS recipes_to_unlock,
        category,
        serial_id,
        source_file
    FROM raw.recipes
    WHERE unique_entry_id IS NOT NULL
    -- Prefer a batch where Sell (and a real Buy, when not genuinely NFS)
    -- survived intact over a dirtier later batch that blanked it out;
    -- among equally complete batches, keep the latest.
    ORDER BY unique_entry_id,
             (NULLIF(TRIM(sell), '') IS NULL),
             (NULLIF(NULLIF(TRIM(buy), ''), 'NFS') IS NULL),
             loaded_at DESC;
END;
$$;

-- ============================================================
-- Creatures availability (fish + insects, unpivoted to long format)
-- ============================================================
-- One row per (creature, hemisphere, month) where the creature is
-- actually catchable that month. This is the table analytics.v_top_
-- creatures_by_month and analytics.v_monthly_bell_potential filter by
-- hemisphere and month.

CREATE TABLE IF NOT EXISTS harmonized.creatures_availability (
    creature_type   TEXT,
    unique_entry_id TEXT,
    name            TEXT,
    sell            INTEGER,
    where_how       TEXT,
    hemisphere      TEXT,
    month           INTEGER,
    time_window     TEXT,
    icon_url        TEXT,
    transformed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_creatures_availability()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.creatures_availability;

    INSERT INTO harmonized.creatures_availability (
        creature_type, unique_entry_id, name, sell, where_how,
        hemisphere, month, time_window, icon_url
    )
    SELECT
        'fish',
        f.unique_entry_id,
        f.name,
        f.sell,
        f.where_how,
        v.hemisphere,
        v.month,
        v.time_window,
        f.icon_url
    FROM harmonized.fish f
    CROSS JOIN LATERAL (VALUES
        ('NH', 1, f.nh_jan),
        ('NH', 2, f.nh_feb),
        ('NH', 3, f.nh_mar),
        ('NH', 4, f.nh_apr),
        ('NH', 5, f.nh_may),
        ('NH', 6, f.nh_jun),
        ('NH', 7, f.nh_jul),
        ('NH', 8, f.nh_aug),
        ('NH', 9, f.nh_sep),
        ('NH', 10, f.nh_oct),
        ('NH', 11, f.nh_nov),
        ('NH', 12, f.nh_dec),
        ('SH', 1, f.sh_jan),
        ('SH', 2, f.sh_feb),
        ('SH', 3, f.sh_mar),
        ('SH', 4, f.sh_apr),
        ('SH', 5, f.sh_may),
        ('SH', 6, f.sh_jun),
        ('SH', 7, f.sh_jul),
        ('SH', 8, f.sh_aug),
        ('SH', 9, f.sh_sep),
        ('SH', 10, f.sh_oct),
        ('SH', 11, f.sh_nov),
        ('SH', 12, f.sh_dec)
    ) AS v(hemisphere, month, time_window)
    WHERE NULLIF(TRIM(v.time_window), '') IS NOT NULL

    UNION ALL

    SELECT
        'insect',
        i.unique_entry_id,
        i.name,
        i.sell,
        i.where_how,
        v.hemisphere,
        v.month,
        v.time_window,
        i.icon_url
    FROM harmonized.insects i
    CROSS JOIN LATERAL (VALUES
        ('NH', 1, i.nh_jan),
        ('NH', 2, i.nh_feb),
        ('NH', 3, i.nh_mar),
        ('NH', 4, i.nh_apr),
        ('NH', 5, i.nh_may),
        ('NH', 6, i.nh_jun),
        ('NH', 7, i.nh_jul),
        ('NH', 8, i.nh_aug),
        ('NH', 9, i.nh_sep),
        ('NH', 10, i.nh_oct),
        ('NH', 11, i.nh_nov),
        ('NH', 12, i.nh_dec),
        ('SH', 1, i.sh_jan),
        ('SH', 2, i.sh_feb),
        ('SH', 3, i.sh_mar),
        ('SH', 4, i.sh_apr),
        ('SH', 5, i.sh_may),
        ('SH', 6, i.sh_jun),
        ('SH', 7, i.sh_jul),
        ('SH', 8, i.sh_aug),
        ('SH', 9, i.sh_sep),
        ('SH', 10, i.sh_oct),
        ('SH', 11, i.sh_nov),
        ('SH', 12, i.sh_dec)
    ) AS v(hemisphere, month, time_window)
    WHERE NULLIF(TRIM(v.time_window), '') IS NOT NULL;
END;
$$;

-- ============================================================
-- Hour-parsing helpers
-- ============================================================
-- Time windows look like "4 AM – 9 PM", "9 PM – 4 AM" (crosses
-- midnight), "All day", or two windows separated by ";" (e.g.
-- "9 AM – 4 PM; 9 PM – 4 AM"). Some source cells use a regular
-- space before the en dash and others a non-breaking space (U+00A0),
-- which is why both fn_expand_hours and fn_parse_hour normalize
-- whitespace before parsing.

CREATE OR REPLACE FUNCTION automation.fn_parse_hour(hour_text TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    clean_text TEXT;
    meridiem   TEXT;
    hour_part  INTEGER;
BEGIN
    clean_text := UPPER(TRIM(REPLACE(hour_text, CHR(160), ' ')));

    IF clean_text = '' THEN
        RETURN NULL;
    END IF;

    meridiem := RIGHT(clean_text, 2);

    IF meridiem NOT IN ('AM', 'PM') THEN
        RETURN NULL;
    END IF;

    hour_part := TRIM(LEFT(clean_text, LENGTH(clean_text) - 2))::INTEGER;

    IF meridiem = 'AM' THEN
        RETURN CASE WHEN hour_part = 12 THEN 0 ELSE hour_part END;
    ELSE
        RETURN CASE WHEN hour_part = 12 THEN 12 ELSE hour_part + 12 END;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION automation.fn_expand_hours(time_window TEXT)
RETURNS SETOF INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    single_window TEXT;
    start_text    TEXT;
    end_text      TEXT;
    start_hour    INTEGER;
    end_hour      INTEGER;
BEGIN
    IF time_window IS NULL OR TRIM(time_window) = '' THEN
        RETURN;
    END IF;

    IF TRIM(time_window) ILIKE 'all day' THEN
        RETURN QUERY SELECT generate_series(0, 23);
        RETURN;
    END IF;

    -- A cell can hold more than one catch window, separated by ";".
    FOREACH single_window IN ARRAY string_to_array(time_window, ';')
    LOOP
        single_window := TRIM(single_window);

        IF single_window = '' THEN
            CONTINUE;
        END IF;

        start_text := TRIM(SPLIT_PART(single_window, CHR(8211), 1));
        end_text   := TRIM(SPLIT_PART(single_window, CHR(8211), 2));

        start_hour := automation.fn_parse_hour(start_text);
        end_hour   := automation.fn_parse_hour(end_text);

        IF start_hour IS NULL OR end_hour IS NULL THEN
            CONTINUE;
        END IF;

        IF start_hour = end_hour THEN
            RETURN QUERY SELECT generate_series(0, 23);
        ELSIF start_hour < end_hour THEN
            RETURN QUERY SELECT generate_series(start_hour, end_hour - 1);
        ELSE
            -- Window crosses midnight, e.g. "9 PM – 4 AM".
            RETURN QUERY
                SELECT generate_series(start_hour, 23)
                UNION ALL
                SELECT generate_series(0, end_hour - 1);
        END IF;
    END LOOP;

    RETURN;
END;
$$;

-- ============================================================
-- Creatures hourly (creatures_availability expanded to one row per hour)
-- ============================================================
-- Powers the "best time to go out" heatmap (hour x creature type).

CREATE TABLE IF NOT EXISTS harmonized.creatures_hourly (
    creature_type   TEXT,
    unique_entry_id TEXT,
    name            TEXT,
    sell            INTEGER,
    hemisphere      TEXT,
    month           INTEGER,
    hour            INTEGER,
    transformed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_creatures_hourly()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.creatures_hourly;

    INSERT INTO harmonized.creatures_hourly (
        creature_type, unique_entry_id, name, sell, hemisphere, month, hour
    )
    SELECT
        ca.creature_type,
        ca.unique_entry_id,
        ca.name,
        ca.sell,
        ca.hemisphere,
        ca.month,
        h.hour
    FROM harmonized.creatures_availability ca
    CROSS JOIN LATERAL automation.fn_expand_hours(ca.time_window) AS h(hour);
END;
$$;

-- ============================================================
-- Villager furniture (bridge table)
-- ============================================================
-- Explodes villagers.furniture_list ("717;1849;7047;...") into one row
-- per (villager, internal_id), so it can be joined against
-- harmonized.housewares.internal_id to build gift ideas.

CREATE TABLE IF NOT EXISTS harmonized.villager_furniture (
    villager_name  TEXT,
    internal_id    TEXT,
    transformed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_villager_furniture()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.villager_furniture;

    INSERT INTO harmonized.villager_furniture (villager_name, internal_id)
    SELECT
        v.name,
        TRIM(f.internal_id)
    FROM harmonized.villagers v
    CROSS JOIN LATERAL unnest(string_to_array(v.furniture_list, ';')) AS f(internal_id)
    WHERE NULLIF(TRIM(v.furniture_list), '') IS NOT NULL
      AND NULLIF(TRIM(f.internal_id), '') IS NOT NULL;
END;
$$;

-- ============================================================
-- Recipe materials
-- ============================================================
-- Normalizes recipes' material_1..material_6 / qty_1..qty_6 pairs into
-- one row per (recipe, material). Not every recipe uses all 6 slots, so
-- empty materials are skipped.

CREATE TABLE IF NOT EXISTS harmonized.recipe_materials (
    recipe_name    TEXT,
    material       TEXT,
    quantity       INTEGER,
    transformed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE automation.sp_transform_recipe_materials()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE harmonized.recipe_materials;

    INSERT INTO harmonized.recipe_materials (recipe_name, material, quantity)
    SELECT
        r.name,
        m.material,
        m.quantity
    FROM harmonized.recipes r
    CROSS JOIN LATERAL (VALUES
        (r.material_1, r.qty_1),
        (r.material_2, r.qty_2),
        (r.material_3, r.qty_3),
        (r.material_4, r.qty_4),
        (r.material_5, r.qty_5),
        (r.material_6, r.qty_6)
    ) AS m(material, quantity)
    WHERE NULLIF(TRIM(m.material), '') IS NOT NULL;
END;
$$;

-- ============================================================
-- Master transformation procedure
-- ============================================================
-- Runs every transformation in dependency order: the base tables first
-- (fish, insects, fossils, villagers, housewares, recipes), then the
-- derived tables that read from them.

CREATE OR REPLACE PROCEDURE automation.sp_transform_all()
LANGUAGE plpgsql
AS $$
BEGIN
    CALL automation.sp_transform_fish();
    CALL automation.sp_transform_insects();
    CALL automation.sp_transform_fossils();
    CALL automation.sp_transform_villagers();
    CALL automation.sp_transform_housewares();
    CALL automation.sp_transform_recipes();

    CALL automation.sp_transform_creatures_availability();
    CALL automation.sp_transform_creatures_hourly();
    CALL automation.sp_transform_villager_furniture();
    CALL automation.sp_transform_recipe_materials();
END;
$$;
