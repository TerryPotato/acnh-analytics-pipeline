"""
Monthly Bell Guide — ACNH Analytics Dashboard.

Streamlit dashboard answering the team's business question:
"How can I earn more Bells this month?"

Reads only from the analytics schema (never raw or harmonized directly).
Filterable by hemisphere and month from the sidebar.
"""

from pathlib import Path
import base64
import sys
import logging

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

# ============================================================
# Import project modules
# ============================================================

BASE_DIR = Path(__file__).resolve().parent
SRC_DIR = BASE_DIR / "src"
sys.path.append(str(SRC_DIR))

from db_connection import get_engine

# ============================================================
# Logging configuration
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)

# ============================================================
# Streamlit page configuration
# ============================================================

st.set_page_config(
    page_title="Monthly Bell Guide",
    page_icon="🔔",
    layout="wide",
)

# ============================================================
# Design tokens
# ============================================================
# Colors sampled from the team's Animal Crossing palette + the community
# "Animal Crossing UI Kit" Figma file (Style Guide / Color Swatches frames).
# fish/insect colors were run through the dataviz skill's palette
# validator (CVD separation + contrast) before being picked.

BG_MAIN = "#FFFFF7"
BG_CARD = "#FFFDF5"
BG_CARD_BORDER = "#EEE9CA"
BG_DARK = "#253B52"
TEXT_DARK = "#2A2118"
TEXT_MUTED = "#8A7B66"
ACCENT_GOLD = "#C97F1F"
ACCENT_TEAL = "#0F9A7C"
ACCENT_MINT = "#8FE3A3"
ACCENT_SKY = "#6FD6DE"

CREATURE_COLORS = {"fish": ACCENT_GOLD, "insect": ACCENT_TEAL}
CREATURE_LABELS = {"fish": "Fish", "insect": "Insects"}

# Single-hue sequential ramp (light -> dark gold) for the hourly heatmap.
GOLD_SCALE = ["#FFF6E5", "#FFE1A8", "#F5B860", "#D98C2B", "#A85D0A"]

MONTH_NAMES = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]

# ============================================================
# Icon assets
# ============================================================
# Exported from the community "Animal Crossing UI Kit" Figma file (Nook
# Phone app badges, the Nook Shopping money icon, the DIY/Seasonal menu
# icons) plus the team's own game screenshots (fossil, calendar). Embedded
# as base64 data URIs so app.py has no external asset-server dependency.

ICONS_DIR = "assets/images/icons"


@st.cache_data
def icon_data_uri(filename: str) -> str:
    """Read an icon from assets/images/icons/ and return a base64 data URI."""
    file_path = BASE_DIR / ICONS_DIR / filename
    suffix = file_path.suffix.lstrip(".")
    mime = "image/svg+xml" if suffix == "svg" else f"image/{suffix}"
    encoded = base64.b64encode(file_path.read_bytes()).decode()
    return f"data:{mime};base64,{encoded}"


def load_icons() -> dict:
    return {
        "bells": icon_data_uri("bells.png"),
        "calendar": icon_data_uri("calendar.png"),
        "fossil": icon_data_uri("fossil.png"),
        "shopping": icon_data_uri("app_nook_shopping.svg"),
        "critterpedia": icon_data_uri("app_critterpedia.svg"),
        "diy": icon_data_uri("app_diy_recipe.svg"),
        "map": icon_data_uri("app_map.svg"),
        "gift": icon_data_uri("inventory_clothes.svg"),
        "leaf_mint": icon_data_uri("leaf_mint.svg"),
        "leaf_gold": icon_data_uri("leaf_gold.svg"),
        "leaf_teal": icon_data_uri("leaf_teal.svg"),
    }


def inject_custom_css(icons: dict) -> None:
    """Inject the Animal Crossing-themed styling for this page."""

    st.markdown(
        f"""
        <style>
        @import url('https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=Nunito:wght@400;600;700&display=swap');

        /* Dot-grid texture, styled after the Nook Shopping menu background */
        .stApp {{
            background-color: {BG_MAIN};
            background-image: radial-gradient({BG_CARD_BORDER} 2.4px, transparent 2.4px);
            background-size: 26px 26px;
        }}
        .block-container {{
            position: relative;
            z-index: 1;
        }}

        html, body, [class*="css"] {{
            font-family: 'Nunito', sans-serif;
            color: {TEXT_DARK};
        }}
        h1, h2, h3, h4 {{
            font-family: 'Fredoka', sans-serif !important;
            color: {TEXT_DARK} !important;
        }}

        section[data-testid="stSidebar"] {{
            background-color: {BG_CARD};
            border-right: 2px solid {BG_CARD_BORDER};
        }}

        header[data-testid="stHeader"] {{
            background-color: {BG_MAIN};
        }}

        /* Rounded, card-style containers for chart sections */
        div[data-testid="stVerticalBlockBorderWrapper"] {{
            background-color: {BG_CARD};
            border: 2px solid {BG_CARD_BORDER} !important;
            border-radius: 22px !important;
            padding: 4px;
        }}

        .acnh-title-row {{
            display: flex;
            align-items: center;
            gap: 14px;
        }}
        .acnh-title-row img {{
            width: 56px;
            height: 56px;
        }}
        .acnh-title-row h1 {{
            margin: 0 !important;
        }}
        .acnh-subtitle {{
            font-size: 1.05rem;
            color: {TEXT_MUTED};
            margin-top: -4px;
            margin-left: 70px;
        }}

        .section-header {{
            display: flex;
            align-items: center;
            gap: 12px;
            margin: 6px 0 10px 0;
        }}
        .section-header img, .section-header .emoji-icon {{
            width: 42px;
            height: 42px;
            flex-shrink: 0;
        }}
        .section-header .emoji-icon {{
            font-size: 32px;
            line-height: 42px;
            text-align: center;
        }}
        .section-header h2 {{
            margin: 0 !important;
            font-size: 1.5rem !important;
        }}

        .acnh-tile {{
            background-color: {BG_CARD};
            border: 2px solid {BG_CARD_BORDER};
            border-radius: 20px;
            padding: 16px 10px;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            gap: 6px;
            min-height: 148px;
            margin-bottom: 16px;
        }}
        .acnh-tile .tile-badge {{
            width: 48px;
            height: 48px;
            flex-shrink: 0;
        }}
        .acnh-tile .tile-badge-photo {{
            width: 48px;
            height: 48px;
            flex-shrink: 0;
            border-radius: 14px;
            background: {BG_MAIN};
            border: 2px solid {BG_CARD_BORDER};
            padding: 5px;
        }}
        .acnh-tile .tile-text {{
            display: flex;
            flex-direction: column;
            align-items: center;
            width: 100%;
            min-width: 0;
        }}
        .acnh-tile .tile-label {{
            font-family: 'Nunito', sans-serif;
            font-size: 0.72rem;
            font-weight: 700;
            color: {TEXT_MUTED};
            text-transform: uppercase;
            letter-spacing: 0.02em;
            max-width: 100%;
            overflow-wrap: break-word;
            line-height: 1.25;
        }}
        .acnh-tile .tile-value {{
            font-family: 'Fredoka', sans-serif;
            font-size: 1.4rem;
            font-weight: 600;
            color: {TEXT_DARK};
            line-height: 1.3;
            max-width: 100%;
            overflow-wrap: break-word;
        }}

        .acnh-note {{
            background-color: {BG_DARK};
            color: #FFFFF7;
            border-radius: 18px;
            padding: 14px 20px;
            display: flex;
            align-items: center;
            gap: 14px;
            font-size: 0.92rem;
        }}
        .acnh-note img {{
            width: 34px;
            height: 34px;
            flex-shrink: 0;
        }}

        .acnh-villager-card {{
            background-color: {BG_CARD};
            border: 2px solid {BG_CARD_BORDER};
            border-radius: 18px;
            padding: 12px 16px;
            text-align: center;
            margin-bottom: 12px;
        }}
        .acnh-villager-card img {{
            width: 64px;
            height: 64px;
        }}
        .acnh-villager-card .villager-name {{
            font-family: 'Fredoka', sans-serif;
            font-weight: 600;
            font-size: 1.05rem;
        }}
        .acnh-villager-card .villager-meta {{
            color: {TEXT_MUTED};
            font-size: 0.85rem;
        }}
        .acnh-villager-card-selected {{
            border-color: {ACCENT_GOLD};
            border-width: 3px;
            background-color: #FFF3DE;
        }}

        /* Villager cards are clickable: an invisible button is stretched
           over the whole card, so there's no separate "Select" button
           visible underneath it. */
        div[class*="st-key-villager_card_"] {{
            position: relative;
        }}
        div[class*="st-key-villager_card_"] div[data-testid="stElementContainer"]:has(div[data-testid="stButton"]) {{
            position: absolute !important;
            inset: 0 !important;
            width: 100% !important;
            height: 100% !important;
            z-index: 2;
            margin: 0 !important;
        }}
        div[class*="st-key-villager_card_"] div[data-testid="stButton"] {{
            width: 100% !important;
            height: 100% !important;
        }}
        div[class*="st-key-villager_card_"] div[data-testid="stButton"] button {{
            width: 100% !important;
            height: 100% !important;
            opacity: 0;
            border: none;
            background: transparent;
            margin: 0;
            cursor: pointer;
        }}
        div[class*="st-key-villager_card_"]:hover .acnh-villager-card {{
            border-color: {ACCENT_GOLD};
        }}

        div[data-testid="stButton"] > button {{
            font-family: 'Fredoka', sans-serif;
            font-weight: 600;
            border-radius: 14px;
            border: 2px solid {BG_CARD_BORDER};
            background-color: {BG_MAIN};
            color: {TEXT_DARK};
            margin-top: 6px;
        }}
        div[data-testid="stButton"] > button:hover {{
            border-color: {ACCENT_GOLD};
            color: {ACCENT_GOLD};
        }}

        .acnh-leaf-decoration {{
            position: fixed;
            z-index: 0;
            pointer-events: none;
        }}
        </style>

        <img class="acnh-leaf-decoration" src="{icons['leaf_mint']}"
             style="top:64px; right:-16px; width:130px; opacity:0.30; transform:rotate(18deg);">
        <img class="acnh-leaf-decoration" src="{icons['leaf_gold']}"
             style="bottom:-24px; left:-24px; width:160px; opacity:0.28; transform:rotate(-24deg);">
        """,
        unsafe_allow_html=True,
    )


def section_header(icon_uri: str | None, title: str, emoji_fallback: str = "") -> None:
    """Render a section header with a real icon badge (or an emoji fallback)."""
    icon_html = (
        f'<img src="{icon_uri}">' if icon_uri else f'<span class="emoji-icon">{emoji_fallback}</span>'
    )
    st.markdown(
        f'<div class="section-header">{icon_html}<h2>{title}</h2></div>',
        unsafe_allow_html=True,
    )


# ============================================================
# Database connection
# ============================================================


@st.cache_resource
def get_db_engine():
    return get_engine()


engine = get_db_engine()

# ============================================================
# Data loading (analytics schema only, cached)
# ============================================================


@st.cache_data
def load_top_creatures(hemisphere: str, month: int, top_n: int = 10) -> pd.DataFrame:
    query = """
        SELECT creature_type, name, sell, time_window, icon_url, rank
        FROM analytics.v_top_creatures_by_month
        WHERE hemisphere = %(hemisphere)s AND month = %(month)s AND rank <= %(top_n)s
        ORDER BY rank
    """
    with engine.connect() as conn:
        return pd.read_sql(query, conn, params={"hemisphere": hemisphere, "month": month, "top_n": top_n})


@st.cache_data
def load_monthly_bell_potential(hemisphere: str) -> pd.DataFrame:
    query = """
        SELECT month, creature_type, species_count, total_bells, unpriced_count
        FROM analytics.v_monthly_bell_potential
        WHERE hemisphere = %(hemisphere)s
        ORDER BY month, creature_type
    """
    with engine.connect() as conn:
        return pd.read_sql(query, conn, params={"hemisphere": hemisphere})


@st.cache_data
def load_leaving_next_month(hemisphere: str, month: int) -> pd.DataFrame:
    query = """
        SELECT creature_type, name, sell, icon_url
        FROM analytics.v_leaving_next_month
        WHERE hemisphere = %(hemisphere)s AND month = %(month)s
        ORDER BY sell DESC NULLS LAST
    """
    with engine.connect() as conn:
        return pd.read_sql(query, conn, params={"hemisphere": hemisphere, "month": month})


@st.cache_data
def load_hourly_availability(hemisphere: str, month: int) -> pd.DataFrame:
    query = """
        SELECT hour, creature_type, species_count, total_bells
        FROM analytics.v_hourly_availability
        WHERE hemisphere = %(hemisphere)s AND month = %(month)s
        ORDER BY hour, creature_type
    """
    with engine.connect() as conn:
        return pd.read_sql(query, conn, params={"hemisphere": hemisphere, "month": month})


@st.cache_data
def load_fossil_summary() -> pd.DataFrame:
    query = "SELECT total_fossils, avg_sell, min_sell, max_sell FROM analytics.v_fossil_summary"
    with engine.connect() as conn:
        return pd.read_sql(query, conn)


@st.cache_data
def load_villager_birthdays(month: int) -> pd.DataFrame:
    query = """
        SELECT villager, species, personality, birth_month, birth_day, icon_url
        FROM analytics.v_villager_birthdays
        WHERE birth_month = %(month)s
        ORDER BY birth_day
    """
    with engine.connect() as conn:
        return pd.read_sql(query, conn, params={"month": month})


@st.cache_data
def load_gift_ideas(villager: str) -> pd.DataFrame:
    query = """
        SELECT furniture_name, buy, sell
        FROM analytics.v_villager_gift_ideas
        WHERE villager = %(villager)s
        ORDER BY sell DESC NULLS LAST
    """
    with engine.connect() as conn:
        return pd.read_sql(query, conn, params={"villager": villager})


@st.cache_data
def load_recipes_for_personality(personality: str) -> pd.DataFrame:
    query = """
        SELECT recipe_name, sell, category
        FROM analytics.v_villager_recipes
        WHERE personality = %(personality)s
        ORDER BY sell DESC NULLS LAST
    """
    with engine.connect() as conn:
        return pd.read_sql(query, conn, params={"personality": personality})


# ============================================================
# Formatting helpers
# ============================================================


def format_bells(value) -> str:
    """Compact Bell amount, e.g. 86890 -> '86.9K', 950 -> '950'."""
    if value is None or pd.isna(value):
        return "—"
    value = float(value)
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{value / 1_000:.1f}K"
    return f"{value:,.0f}"


def format_price_column(series: pd.Series, blank_label: str = "—") -> pd.Series:
    """Format a nullable numeric price column as '12,345' / blank_label, never '12345.0'."""
    return series.apply(lambda v: blank_label if pd.isna(v) else f"{int(v):,}")


def stat_tile(icon_uri: str, label: str, value: str, photo: bool = False) -> str:
    """A KPI tile with a real icon badge (Figma kit asset or a live creature photo)."""
    badge_class = "tile-badge-photo" if photo else "tile-badge"
    return f"""
        <div class="acnh-tile">
            <img class="{badge_class}" src="{icon_uri}">
            <div class="tile-text">
                <div class="tile-label">{label}</div>
                <div class="tile-value">{value}</div>
            </div>
        </div>
    """


# ============================================================
# Sidebar filters
# ============================================================

ICONS = load_icons()
inject_custom_css(ICONS)

with st.sidebar:
    st.markdown(
        f'<div class="section-header"><img src="{ICONS["map"]}"><h2>Filters</h2></div>',
        unsafe_allow_html=True,
    )
    hemisphere_label = st.radio("Hemisphere", ["Northern", "Southern"], horizontal=False)
    hemisphere = "NH" if hemisphere_label == "Northern" else "SH"

    month_label = st.selectbox("Month", MONTH_NAMES, index=pd.Timestamp.now().month - 1)
    month = MONTH_NAMES.index(month_label) + 1

    next_month = 1 if month == 12 else month + 1

# ============================================================
# Header
# ============================================================

st.markdown(
    f"""
    <div class="acnh-title-row">
        <img src="{ICONS['bells']}">
        <h1>Monthly Bell Guide</h1>
    </div>
    <div class="acnh-subtitle">How can I earn more Bells this month?</div>
    """,
    unsafe_allow_html=True,
)
st.write("")

# ============================================================
# Section 1 — KPIs
# ============================================================

bell_potential_df = load_monthly_bell_potential(hemisphere)
month_df = bell_potential_df[bell_potential_df["month"] == month]
top_creatures_df = load_top_creatures(hemisphere, month)
leaving_df = load_leaving_next_month(hemisphere, month)

total_species = int(month_df["species_count"].sum()) if not month_df.empty else 0
total_bells_month = month_df["total_bells"].sum() if not month_df.empty else 0
unpriced_species = int(month_df["unpriced_count"].sum()) if not month_df.empty else 0
top_creature_name = top_creatures_df.iloc[0]["name"] if not top_creatures_df.empty else "—"
top_creature_sell = top_creatures_df.iloc[0]["sell"] if not top_creatures_df.empty else None
top_creature_icon = top_creatures_df.iloc[0]["icon_url"] if not top_creatures_df.empty else None

kpi_cols = st.columns(4)
with kpi_cols[0]:
    st.markdown(stat_tile(ICONS["critterpedia"], "Species available", f"{total_species}"), unsafe_allow_html=True)
with kpi_cols[1]:
    st.markdown(stat_tile(ICONS["bells"], "Potential Bells", format_bells(total_bells_month)), unsafe_allow_html=True)
with kpi_cols[2]:
    label = f"{format_bells(top_creature_sell)} Bells" if top_creature_sell is not None else "—"
    icon_for_top = top_creature_icon if top_creature_icon else ICONS["critterpedia"]
    st.markdown(
        stat_tile(icon_for_top, top_creature_name, label, photo=bool(top_creature_icon)),
        unsafe_allow_html=True,
    )
with kpi_cols[3]:
    st.markdown(stat_tile(ICONS["map"], "Leaving next month", f"{len(leaving_df)}"), unsafe_allow_html=True)

unpriced_note = (
    f" <b>{unpriced_species} species</b> have no price in the data yet and are not included in the total."
    if unpriced_species
    else ""
)

st.write("")
st.markdown(
    f"""
    <div class="acnh-note">
        <img src="{ICONS['bells']}">
        <div><b>Potential Bells</b> = sum of one unit of each available species this month.
        It's a ceiling, not a forecast — real earnings depend on spawn rates, luck, and how
        many of each critter you actually catch.{unpriced_note}</div>
    </div>
    """,
    unsafe_allow_html=True,
)
st.write("")

# ============================================================
# Section 2 — Top 10 most profitable
# ============================================================

section_header(ICONS["shopping"], "Top 10 most profitable this month")

with st.container(border=True):
    if top_creatures_df.empty:
        st.info("No fish or insects are available this month/hemisphere.")
    else:
        # Plotly draws the first row at the bottom, so reverse the rank to put #1 on top.
        chart_df = top_creatures_df.sort_values("rank", ascending=False)
        fig = px.bar(
            chart_df,
            x="sell",
            y="name",
            color="creature_type",
            color_discrete_map=CREATURE_COLORS,
            orientation="h",
            text="sell",
            custom_data=["time_window"],
            labels={"sell": "Sell price (Bells)", "name": "", "creature_type": "Type"},
        )
        fig.update_traces(
            texttemplate="%{text:,}",
            textposition="outside",
            cliponaxis=False,
            marker_line_width=0,
            hovertemplate=(
                "<b>%{y}</b><br>Type: %{fullData.name}<br>"
                "Sell price: %{x:,} Bells<br>Time: %{customdata[0]}<extra></extra>"
            ),
        )
        fig.for_each_trace(lambda t: t.update(name=CREATURE_LABELS.get(t.name, t.name)))
        # Headroom past the longest bar so its outside label ("15,000") is not cut off.
        fig.update_xaxes(range=[0, chart_df["sell"].fillna(0).max() * 1.15])
        # Keep the rank order (ties included) instead of Plotly's category sorting.
        fig.update_yaxes(categoryorder="array", categoryarray=chart_df["name"].tolist())
        fig.update_layout(
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)",
            font_family="Nunito, sans-serif",
            font_color=TEXT_DARK,
            bargap=0.35,
            legend_title_text="",
            xaxis=dict(gridcolor="#EEE9CA", zeroline=False),
            yaxis=dict(gridcolor="rgba(0,0,0,0)"),
            margin=dict(l=10, r=10, t=10, b=10),
        )
        st.plotly_chart(fig, use_container_width=True)

st.write("")

# ============================================================
# Section 3 — Monthly Bell potential (12 months)
# ============================================================

section_header(ICONS["calendar"], "Monthly Bell potential")

with st.container(border=True):
    if bell_potential_df.empty:
        st.info("No data available.")
    else:
        pivot_df = bell_potential_df.copy()
        pivot_df["month_name"] = pivot_df["month"].apply(lambda m: MONTH_NAMES[m - 1][:3])
        pivot_df["opacity"] = pivot_df["month"].apply(lambda m: 1.0 if m == month else 0.45)

        fig = go.Figure()
        for creature_type in ["fish", "insect"]:
            subset = pivot_df[pivot_df["creature_type"] == creature_type].sort_values("month")
            fig.add_bar(
                x=subset["month_name"],
                y=subset["total_bells"],
                name=CREATURE_LABELS[creature_type],
                marker_color=CREATURE_COLORS[creature_type],
                marker_opacity=subset["opacity"],
                hovertemplate="%{x}: %{y:,} Bells<extra>" + CREATURE_LABELS[creature_type] + "</extra>",
            )
        fig.update_layout(
            barmode="stack",
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)",
            font_family="Nunito, sans-serif",
            font_color=TEXT_DARK,
            bargap=0.25,
            legend_title_text="",
            yaxis=dict(title="Potential Bells", gridcolor="#EEE9CA", zeroline=False),
            xaxis=dict(title=""),
            margin=dict(l=10, r=10, t=10, b=10),
        )
        st.plotly_chart(fig, use_container_width=True)
        st.caption(f"**{month_label}** is shown at full opacity; other months are dimmed for comparison.")

st.write("")

# ============================================================
# Section 4 — Best time to go out
# ============================================================

section_header(None, "Best time to go out", emoji_fallback="🕐")

hourly_df = load_hourly_availability(hemisphere, month)

with st.container(border=True):
    if hourly_df.empty:
        st.info("No hourly data available.")
    else:
        heat_pivot = hourly_df.pivot_table(
            index="creature_type", columns="hour", values="total_bells", fill_value=0
        ).reindex(["fish", "insect"])
        heat_pivot.index = [CREATURE_LABELS[c] for c in heat_pivot.index]

        fig = px.imshow(
            heat_pivot,
            color_continuous_scale=GOLD_SCALE,
            labels=dict(x="Hour", y="", color="Potential Bells"),
            aspect="auto",
        )
        fig.update_xaxes(tickmode="linear", dtick=1, gridcolor="rgba(0,0,0,0)")
        fig.update_layout(
            plot_bgcolor="rgba(0,0,0,0)",
            paper_bgcolor="rgba(0,0,0,0)",
            font_family="Nunito, sans-serif",
            font_color=TEXT_DARK,
            margin=dict(l=10, r=10, t=10, b=10),
        )
        st.plotly_chart(fig, use_container_width=True)
        st.caption("Darker gold = more potential Bells available that hour.")

st.write("")

# ============================================================
# Section 5 — Fixed vs. seasonal income
# ============================================================

section_header(ICONS["fossil"], "Fixed vs. seasonal income")

fossil_df = load_fossil_summary()

with st.container(border=True):
    fossil_row = fossil_df.iloc[0]
    fixed_income = float(fossil_row["total_fossils"]) * float(fossil_row["avg_sell"] or 0)

    cols = st.columns(2)
    with cols[0]:
        st.markdown(
            stat_tile(
                ICONS["fossil"],
                "Fossils baseline (all year)",
                f"{format_bells(fixed_income)} Bells",
            ),
            unsafe_allow_html=True,
        )
        st.caption(
            f"{int(fossil_row['total_fossils'])} fossil types, "
            f"avg {format_bells(fossil_row['avg_sell'])} Bells each — always available, no season needed."
        )
    with cols[1]:
        st.markdown(
            stat_tile(
                ICONS["leaf_teal"],
                f"{month_label} creatures (seasonal)",
                f"{format_bells(total_bells_month)} Bells",
            ),
            unsafe_allow_html=True,
        )
        st.caption(f"{total_species} fish/insect species catchable only this time of year.")

st.write("")

# ============================================================
# Section 6 — Neighbors of the month
# ============================================================

section_header(None, "Neighbors of the month", emoji_fallback="🎂")

birthdays_df = load_villager_birthdays(month)

with st.container(border=True):
    if birthdays_df.empty:
        st.info(f"No villagers have a birthday in {month_label}.")
        st.session_state.pop("selected_villager", None)
    else:
        # Default to the first birthday villager, and reset the selection
        # whenever it's no longer valid (e.g. the hemisphere/month filter
        # changed and that villager no longer has a birthday this month).
        if st.session_state.get("selected_villager") not in birthdays_df["villager"].values:
            st.session_state.selected_villager = birthdays_df.iloc[0]["villager"]

        st.caption(f"Villagers celebrating a birthday in {month_label} — click one to see their gift ideas & recipes:")
        card_cols = st.columns(min(len(birthdays_df), 6))
        for i, (_, row) in enumerate(birthdays_df.iterrows()):
            with card_cols[i % len(card_cols)]:
                with st.container(key=f"villager_card_{i}"):
                    icon_html = f'<img src="{row["icon_url"]}" />' if row["icon_url"] else "🐾"
                    is_selected = row["villager"] == st.session_state.selected_villager
                    card_class = "acnh-villager-card acnh-villager-card-selected" if is_selected else "acnh-villager-card"
                    st.markdown(
                        f"""
                        <div class="{card_class}">
                            {icon_html}
                            <div class="villager-name">{row['villager']}</div>
                            <div class="villager-meta">{row['species']} · {row['personality']}</div>
                            <div class="villager-meta">Day {int(row['birth_day'])}</div>
                        </div>
                        """,
                        unsafe_allow_html=True,
                    )
                    # Invisible button stretched over the whole card, so the
                    # card itself is the click target instead of a separate
                    # "Select" button below it.
                    if st.button("Select", key=f"select_{row['villager']}", use_container_width=True):
                        st.session_state.selected_villager = row["villager"]
                        st.rerun()

        st.write("")
        selected_villager = st.session_state.selected_villager
        selected_personality = birthdays_df.loc[
            birthdays_df["villager"] == selected_villager, "personality"
        ].iloc[0]

        gift_col, recipe_col = st.columns(2)
        with gift_col:
            st.markdown(
                f'<div class="section-header"><img src="{ICONS["gift"]}"><h2 style="font-size:1.2rem !important;">Gift ideas for {selected_villager}</h2></div>',
                unsafe_allow_html=True,
            )
            gifts_df = load_gift_ideas(selected_villager)
            if gifts_df.empty:
                st.write("No favorite furniture on record.")
            else:
                gifts_df = gifts_df.copy()
                # Buy is NULL because the item is genuinely not purchasable
                # (crafted/found/gifted only), so label it instead of using
                # a bare dash that reads as missing data.
                gifts_df["buy"] = format_price_column(gifts_df["buy"], blank_label="Not for sale")
                gifts_df["sell"] = format_price_column(gifts_df["sell"])
                st.dataframe(
                    gifts_df.rename(columns={"furniture_name": "Furniture", "buy": "Buy", "sell": "Sell"}),
                    hide_index=True,
                    use_container_width=True,
                )

        with recipe_col:
            st.markdown(
                f'<div class="section-header"><img src="{ICONS["diy"]}"><h2 style="font-size:1.2rem !important;">Recipes {selected_personality} villagers can gift</h2></div>',
                unsafe_allow_html=True,
            )
            recipes_df = load_recipes_for_personality(selected_personality)
            if recipes_df.empty:
                st.write("No matching recipes on record.")
            else:
                recipes_df = recipes_df.copy()
                recipes_df["sell"] = format_price_column(recipes_df["sell"])
                st.dataframe(
                    recipes_df.rename(
                        columns={"recipe_name": "Recipe", "sell": "Sell", "category": "Category"}
                    ),
                    hide_index=True,
                    use_container_width=True,
                )
