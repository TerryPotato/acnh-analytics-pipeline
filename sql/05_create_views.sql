-- ============================================================
-- Analytics views
-- ============================================================
-- app.py reads only from these views, never from raw or harmonized
-- directly. Every view is filterable by hemisphere and/or month in the
-- dashboard's sidebar.

-- ============================================================
-- v_top_creatures_by_month
-- ============================================================
-- Fish and insects ranked by Sell price within each hemisphere/month.
-- Powers the "Top 10 most profitable" horizontal bar chart (app.py
-- filters WHERE rank <= 10).

CREATE OR REPLACE VIEW analytics.v_top_creatures_by_month AS
SELECT
    hemisphere,
    month,
    creature_type,
    name,
    sell,
    time_window,
    icon_url,
    -- NULLS LAST because Sell can be NULL for a species with dirty/missing
    -- price data; those should rank last, not tie for first place (which
    -- is what Postgres's default NULLS FIRST for DESC would otherwise do).
    RANK() OVER (
        PARTITION BY hemisphere, month
        ORDER BY sell DESC NULLS LAST
    ) AS rank
FROM harmonized.creatures_availability;


-- ============================================================
-- v_monthly_bell_potential
-- ============================================================
-- Total potential Bells and species count per hemisphere/month/creature
-- type. Powers the 12-month stacked bar chart (fish vs. insects).

CREATE OR REPLACE VIEW analytics.v_monthly_bell_potential AS
SELECT
    hemisphere,
    month,
    creature_type,
    COUNT(*) AS species_count,
    SUM(sell) AS total_bells
FROM harmonized.creatures_availability
GROUP BY hemisphere, month, creature_type
ORDER BY hemisphere, month, creature_type;


-- ============================================================
-- v_leaving_next_month
-- ============================================================
-- Creatures catchable this month but not next month (December wraps
-- around to January), so players know what to catch before it's gone.

CREATE OR REPLACE VIEW analytics.v_leaving_next_month AS
SELECT
    ca.hemisphere,
    ca.month,
    ca.creature_type,
    ca.name,
    ca.sell,
    ca.icon_url
FROM harmonized.creatures_availability ca
WHERE NOT EXISTS (
    SELECT 1
    FROM harmonized.creatures_availability nxt
    WHERE nxt.hemisphere = ca.hemisphere
      AND nxt.unique_entry_id = ca.unique_entry_id
      AND nxt.month = CASE WHEN ca.month = 12 THEN 1 ELSE ca.month + 1 END
);


-- ============================================================
-- v_hourly_availability
-- ============================================================
-- Species count and total Bells per hemisphere/month/hour/creature type.
-- Powers the "best time to go out" heatmap (hour x creature type).

CREATE OR REPLACE VIEW analytics.v_hourly_availability AS
SELECT
    hemisphere,
    month,
    hour,
    creature_type,
    COUNT(*) AS species_count,
    SUM(sell) AS total_bells
FROM harmonized.creatures_hourly
GROUP BY hemisphere, month, hour, creature_type
ORDER BY hemisphere, month, hour, creature_type;


-- ============================================================
-- v_fossil_summary
-- ============================================================
-- Fossils are available all year, so this is the "fixed income" baseline
-- the dashboard compares against the current month's seasonal creatures.

CREATE OR REPLACE VIEW analytics.v_fossil_summary AS
SELECT
    COUNT(*) AS total_fossils,
    ROUND(AVG(sell)) AS avg_sell,
    MIN(sell) AS min_sell,
    MAX(sell) AS max_sell
FROM harmonized.fossils;


-- ============================================================
-- v_villager_birthdays
-- ============================================================
-- Every villager with their birthday, for the "neighbors of the month"
-- section (app.py filters WHERE birth_month = selected month).

CREATE OR REPLACE VIEW analytics.v_villager_birthdays AS
SELECT
    name AS villager,
    species,
    personality,
    birth_month,
    birth_day,
    icon_url
FROM harmonized.villagers
ORDER BY birth_month, birth_day;


-- ============================================================
-- v_villager_gift_ideas
-- ============================================================
-- Furniture each villager likes, resolved through the villager_furniture
-- bridge table (villagers.Furniture List -> housewares.Internal ID).
-- DISTINCT because some villagers' Furniture List repeats the same
-- Internal ID more than once in the source data (e.g. Knox's list
-- contains "...;3772;3772;3772;3772;...").

CREATE OR REPLACE VIEW analytics.v_villager_gift_ideas AS
SELECT DISTINCT
    vf.villager_name AS villager,
    h.name AS furniture_name,
    h.buy,
    h.sell
FROM harmonized.villager_furniture vf
JOIN harmonized.housewares h ON h.internal_id = vf.internal_id;


-- ============================================================
-- v_villager_recipes
-- ============================================================
-- Recipes each personality can be gifted. recipes.source holds text like
-- "Smug villagers" or "Big Sister villagers", and can list more than one
-- origin per recipe, so personality is matched with LIKE instead of a
-- direct join (see CLAUDE.md section 6).

CREATE OR REPLACE VIEW analytics.v_villager_recipes AS
SELECT
    p.personality,
    r.name AS recipe_name,
    r.sell,
    r.category
FROM (
    SELECT DISTINCT personality
    FROM harmonized.villagers
    WHERE personality IS NOT NULL
) p
JOIN harmonized.recipes r
    ON r.source ILIKE '%' || p.personality || ' villagers%';
