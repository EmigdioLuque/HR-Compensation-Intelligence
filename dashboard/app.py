from html import escape
from pathlib import Path
import json
from urllib.request import urlopen

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

from database import run_query


# ============================================================
# APPLICATION CONFIGURATION
# ============================================================

st.set_page_config(
    page_title="HR Compensation Intelligence",
    page_icon="◈",
    layout="wide",
    initial_sidebar_state="collapsed"
)

NAVY = "#692D40"
TEAL = "#285B4B"
BLUE = "#98704D"
SLATE = "#746B63"
LIGHT = "#F7F3EB"
WHITE = "#FFFCF6"
RED = "#873D50"

PALETTE = [
    NAVY,
    TEAL,
    BLUE,
    "#B9A99A",
    "#A77A39",
    "#765C70"
]


# ============================================================
# VISUAL IDENTITY
# ============================================================

st.markdown("""
<style>
.stApp {background:#F7F3EB;}
.block-container {max-width:1450px;padding:1.6rem 3rem 3rem;}
[data-testid="stSidebar"], [data-testid="stSidebarCollapsedControl"] {display:none;}
[data-testid="stHeader"] {background:#F7F3EB;}
.masthead {display:flex;justify-content:space-between;align-items:center;gap:24px;border-bottom:1px solid #692D40;padding:4px 0 12px;}
.masthead strong {font-family:Georgia,serif;font-size:30px;color:#692D40;font-weight:normal;}
.masthead small {display:block;letter-spacing:2px;font-size:10px;color:#746B63;text-transform:uppercase;}
.edition {text-align:right;font-size:12px;color:#746B63;}
h1,h2,h3 {font-family:Georgia,serif!important;color:#302C2A!important;font-weight:normal!important;letter-spacing:-.7px;}
h1 {font-size:clamp(34px,3.5vw,50px)!important;}
.brand-label {font-size:11px;letter-spacing:2px;color:#692D40;font-weight:700;margin-top:4px;}
.page-description {color:#746B63;font-size:15px;margin-bottom:12px;max-width:900px;}
[data-testid="stMetric"] {background:transparent;border:0;border-top:2px solid #692D40;border-radius:0;padding:14px 5px 12px;box-shadow:none;}
[data-testid="stMetricValue"] {font-family:Georgia,serif;color:#692D40;font-size:clamp(20px,2.4vw,34px);font-weight:normal;letter-spacing:-1px;}
[data-testid="stPlotlyChart"] {background:#FFFCF6;border:1px solid #E5DDD0;border-radius:3px;padding:8px;}
[data-testid="stDataFrame"] {border-radius:3px;}
.insight-box {background:#E9EEE5;border-left:3px solid #285B4B;padding:20px;margin:12px 0;color:#302C2A;line-height:1.6;}
.insight-box:before {content:"EXECUTIVE BRIEF";display:block;font-size:10px;letter-spacing:2px;font-weight:700;color:#285B4B;margin-bottom:10px;}
.footer {border-top:1px solid #CBBEAE;color:#746B63;font-size:12px;padding-top:20px;margin-top:36px;}
.stDownloadButton button {border-radius:3px;}
/* Editorial navigation: native buttons, scoped to the menu only. */
.st-key-editorial_navigation [data-testid="stHorizontalBlock"] {gap:0.35rem;}
.st-key-editorial_navigation button {
    background:transparent!important; border:0!important;
    border-bottom:2px solid transparent!important; border-radius:0!important;
    box-shadow:none!important; color:#746B63!important;
    min-height:42px; padding:0.45rem 0.2rem!important;
    transition:color .15s, border-color .15s;
}
.st-key-editorial_navigation button[kind="primary"] {
    color:#692D40!important; border-bottom-color:#692D40!important;
    font-weight:700!important;
}
.st-key-editorial_navigation button:hover {color:#692D40!important;border-bottom-color:#B9A99A!important;}
.st-key-editorial_navigation button[kind="primary"]:hover {border-bottom-color:#692D40!important;}
.st-key-editorial_navigation button:focus:not(:focus-visible) {outline:none!important;box-shadow:none!important;}
.st-key-editorial_navigation button:focus-visible {outline:1px dashed #692D40!important;outline-offset:2px;}
.st-key-editorial_navigation button p {font-size:0.88rem;white-space:nowrap;}
.st-key-editorial_navigation {margin-top:-0.5rem;}
[data-testid="stMetricDelta"] {font-size:13px;}
[data-testid="stVerticalBlock"] {gap:0.85rem;}
[data-testid="stMarkdownContainer"] hr {margin:0.8rem 0;}
.stButton button,.stDownloadButton button {border:1px solid #CBBEAE;border-radius:4px;background:#FFFCF6;}
.stButton button:hover,.stDownloadButton button:hover {border-color:#692D40;color:#692D40;}
[data-testid="stMetricLabel"] {white-space:normal;}
[data-testid="stPlotlyChart"] {overflow:hidden;}

@media(max-width:700px){.block-container{padding:2rem 1rem}.masthead{flex-wrap:wrap}.edition{text-align:left}}
</style>
""", unsafe_allow_html=True)


# ============================================================
# DATA ACCESS
# ============================================================

ALLOWED_VIEWS = {
    "vw_executive_overview",
    "vw_regional_benchmarking",
    "vw_sector_salary_intelligence",
    "vw_occupational_salary_intelligence",
    "vw_gender_pay_gap",
    "vw_labour_cost_intelligence",
    "vw_salary_economic_activity",
    "vw_salary_occupation",
    "vw_salary_regional_occupation",
    "vw_salary_regional_sector",
    "vw_labour_costs"
}


@st.cache_data(ttl=600, show_spinner=False)
def load_view(view_name):

    if view_name not in ALLOWED_VIEWS:
        raise ValueError("Invalid analytical view.")

    return run_query(
        f"SELECT * FROM analytics.{view_name};"
    )


# ============================================================
# FORMATTING UTILITIES
# ============================================================

def euro(value):

    if pd.isna(value):
        return "N/A"

    return f"€{float(value):,.2f}"


def pct(value):

    if pd.isna(value):
        return "N/A"

    return f"{float(value):,.2f}%"


def pp(value):

    if pd.isna(value):
        return "N/A"

    return f"{float(value):+.2f} pp"


def number(value):

    if pd.isna(value):
        return "N/A"

    return f"{float(value):,.0f}"


def numeric_columns(df, columns):

    df = df.copy()

    for column in columns:

        if column in df.columns:

            df[column] = pd.to_numeric(
                df[column],
                errors="coerce"
            )

    return df


def page_header(title, description):

    st.markdown(
        '<div class="brand-label">'
        'PEOPLE ANALYTICS / COMPENSATION INTELLIGENCE'
        '</div>',
        unsafe_allow_html=True
    )

    st.title(title)

    st.markdown(
        f'<div class="page-description">'
        f'{escape(description)}</div>',
        unsafe_allow_html=True
    )


def insight(text):

    st.markdown(
        f'<div class="insight-box">'
        f'{escape(text)}</div>',
        unsafe_allow_html=True
    )


def download_data(df, filename):

    st.download_button(
        label="Download analytical data",
        data=df.to_csv(index=False).encode("utf-8-sig"),
        file_name=filename,
        mime="text/csv",
        key=f"download_{filename}"
    )


def show_table(df):

    display = df.copy()
    config = {}
    for col in display.columns:
        label = col.replace("_", " ").title().replace("Yoy", "YoY").replace("Pct", "(%)").replace("Eur", "(€)").replace("Pp", "(pp)")
        if pd.api.types.is_numeric_dtype(display[col]):
            fmt = "%d" if col in {"year", "rank", "employees", "quarter"} else "%.2f"
            if col.endswith("_pct"):
                fmt = "%.2f%%"
            elif col.endswith("_pp"):
                fmt = "%.2f pp"
            elif "salary" in col or "cost" in col or col.endswith("_eur"):
                if "index" not in col and "ratio" not in col:
                    fmt = "€ %.2f"
            config[col] = st.column_config.NumberColumn(label, format=fmt)
        else:
            config[col] = st.column_config.Column(label)
    st.dataframe(
        display,
        column_config=config,
        width="stretch",
        hide_index=True
    )


def require_data(df):

    if df.empty:

        st.warning(
            "No observations are available "
            "for the selected filters."
        )

        st.stop()


def chart_style(fig, height=420):

    fig.update_layout(
        template="plotly_white",
        height=height,
        paper_bgcolor=WHITE,
        plot_bgcolor=WHITE,
        colorway=PALETTE,
        font=dict(
            family="Arial, sans-serif",
            color=NAVY,
            size=12
        ),
        margin=dict(
            l=25,
            r=25,
            t=55,
            b=35
        ),
        legend=dict(
            orientation="h",
            y=1.04,
            x=0
        ),
        hoverlabel=dict(
            bgcolor=WHITE,
            font_color=NAVY
        )
    )

    fig.update_xaxes(
        showgrid=False,
        zeroline=False
    )

    fig.update_yaxes(
        gridcolor="#E5DDD0",
        zeroline=False
    )

    labels = {"labour_cost_growth_yoy_pct": "Year-on-year growth", "labour_cost_growth_qoq_pct": "Quarter-on-quarter growth", "average_salary": "Average annual salary", "value": "Amount", "period": "Quarter"}
    for trace in fig.data:
        if trace.name in labels:
            trace.name = labels[trace.name]
    for axis in (fig.layout.xaxis, fig.layout.yaxis):
        title = axis.title.text
        if title in labels:
            axis.title.text = labels[title]
        elif title and "_" in title:
            axis.title.text = title.replace("_", " ").capitalize()
    if fig.layout.legend.title.text in ("variable", "value"):
        fig.layout.legend.title.text = ""
    return fig


def render_chart(fig, height=420):

    st.plotly_chart(
        chart_style(fig, height),
        width="stretch",
        config={
            "displaylogo": False,
            "responsive": True
        }
    )


def ranking_chart(
    df,
    category,
    value,
    label,
    benchmark=None
):

    ranked = (
        df.dropna(subset=[value])
        .sort_values(value, ascending=True)
    )

    fig = px.bar(
        ranked,
        x=value,
        y=category,
        orientation="h",
        color=value,
        color_continuous_scale=[
            "#E3D8C8",
            TEAL,
            NAVY
        ],
        labels={
            value: label,
            category: ""
        }
    )

    fig.update_layout(
        coloraxis_showscale=False
    )

    if benchmark is not None and pd.notna(benchmark):

        fig.add_vline(
            x=float(benchmark),
            line_dash="dash",
            line_color=SLATE,
            annotation_text="National benchmark"
        )

    fig.update_xaxes(
        tickprefix="€",
        tickformat=",.0f"
    )

    return fig


def salary_line(
    df,
    x,
    y,
    color=None
):

    fig = px.line(
        df,
        x=x,
        y=y,
        color=color,
        markers=True,
        color_discrete_sequence=PALETTE,
        labels={x: "Year", y: "Average annual salary", **({color: "Category"} if color else {})}
    )

    fig.update_traces(
        line_width=3
    )

    fig.update_yaxes(
        tickprefix="€",
        tickformat=",.0f"
    )

    return fig


# ============================================================
# INITIAL DATA
# ============================================================

try:

    executive = load_view(
        "vw_executive_overview"
    )

except Exception:

    st.error(
        "The PostgreSQL connection could not be established. "
        "Check the database service and environment configuration."
    )

    st.stop()


executive = numeric_columns(
    executive,
    [
        "year",
        "average_salary",
        "male_salary",
        "female_salary",
        "salary_growth_pct",
        "gender_pay_gap_eur",
        "gender_pay_gap_pct"
    ]
)

executive = executive.sort_values("year")

require_data(executive)

years = sorted(
    executive["year"].dropna().astype(int).unique(),
    reverse=True
)

latest_year = max(years)


# ============================================================
# SIDEBAR NAVIGATION
# ============================================================

st.markdown(f"""
<div class="masthead"><div><small>Independent market research / People analytics</small>
<strong>HR Compensation Intelligence</strong></div>
<div class="edition">SPAIN · INE DATA<br>Salary coverage {min(years)}–{max(years)}</div></div>
""", unsafe_allow_html=True)

modules = {
    "Executive Overview": "Overview",
    "Regional Benchmarking": "Regions",
    "Sector Intelligence": "Sectors",
    "Occupational Intelligence": "Occupations",
    "Gender Pay Gap": "Pay equity",
    "Labour Cost Intelligence": "Labour costs",
    "Workforce Cost Simulator": "Planning",
    "Data & Methodology": "Methodology",
}
if st.session_state.get("active_module") not in modules:
    st.session_state["active_module"] = next(iter(modules))


def select_module(module):
    st.session_state["active_module"] = module


with st.container(key="editorial_navigation"):
    nav_columns = st.columns(len(modules))
    for column, (module, label) in zip(nav_columns, modules.items()):
        with column:
            st.button(
                label,
                key=f"nav_{module}",
                type="primary" if st.session_state["active_module"] == module else "secondary",
                width="stretch",
                on_click=select_module,
                args=(module,),
            )

page = st.session_state["active_module"]
filter_col, context_col, refresh_col = st.columns([1, 3, 1], vertical_alignment="bottom")
with filter_col:
    if page not in ["Labour Cost Intelligence", "Workforce Cost Simulator", "Data & Methodology"]:
        selected_year = st.selectbox("Reference year", years, key="reference_year")
    else:
        selected_year = latest_year
with context_col:
    st.caption("MARKET / SPAIN · SOURCE / INE · DATA / POSTGRESQL")
with refresh_col:
    if st.button("Refresh data", width="stretch"):
        st.cache_data.clear()
        st.rerun()
st.divider()


# ============================================================
# 01. EXECUTIVE OVERVIEW
# ============================================================

if page == "Executive Overview":

    page_header(
        "Executive Overview",
        "National compensation benchmarks, salary dynamics "
        "and workforce remuneration indicators."
    )

    current = executive[
        executive["year"] == selected_year
    ]

    require_data(current)

    row = current.iloc[0]
    previous = executive[executive["year"] == selected_year - 1]

    def annual_delta(column, formatter):
        if previous.empty or pd.isna(row[column]) or pd.isna(previous.iloc[0][column]):
            return None
        return formatter(float(row[column]) - float(previous.iloc[0][column])) + " vs prior year"

    st.caption(
        f"SPAIN · ANNUAL COMPENSATION · {selected_year}"
    )

    c1, c2, c3, c4 = st.columns(4)

    c1.metric(
        "National average salary",
        euro(row["average_salary"]),
        delta=annual_delta("average_salary", lambda v: f"{v:+,.2f} €"),
        delta_color="off"
    )

    c2.metric(
        "Annual salary growth",
        pct(row["salary_growth_pct"]),
        delta=annual_delta("salary_growth_pct", pp),
        delta_color="off"
    )

    c3.metric(
        "Unadjusted pay gap",
        pct(row["gender_pay_gap_pct"]),
        delta=annual_delta("gender_pay_gap_pct", pp),
        delta_color="off"
    )

    c4.metric(
        "Gender earnings difference",
        euro(row["gender_pay_gap_eur"]),
        delta=annual_delta("gender_pay_gap_eur", lambda v: f"{v:+,.2f} €"),
        delta_color="off"
    )

    st.divider()

    historical = executive[
        executive["year"] <= selected_year
    ]

    trend_col, brief_col = st.columns([2, 1])
    with trend_col:
        st.subheader("National salary evolution")

        fig = salary_line(
            historical,
            "year",
            "average_salary"
        )

        fig.update_layout(
            xaxis_title="Year",
            yaxis_title="Average annual salary"
        )

        render_chart(fig)

    with brief_col:
        st.subheader("Market briefing")
        insight(f"Average annual earnings reached {euro(row['average_salary'])} in {selected_year}. Nominal annual growth was {pct(row['salary_growth_pct'])}.")
        st.metric("Women’s earnings relative to men’s", pct(100 - row['gender_pay_gap_pct']))
        st.caption("Unadjusted annual earnings comparison; not a like-for-like pay measure.")

    left, right = st.columns(2)

    with left:

        st.subheader("Annual salary growth")

        fig = px.bar(
            historical,
            x="year",
            y="salary_growth_pct",
            color="salary_growth_pct",
            color_continuous_scale=[
                RED,
                "#E5DDD0",
                TEAL
            ],
            color_continuous_midpoint=0
        )

        fig.update_layout(
            coloraxis_showscale=False,
            xaxis_title="Year",
            yaxis_title="Annual growth"
        )

        fig.update_yaxes(
            ticksuffix="%"
        )

        render_chart(fig)

    with right:

        st.subheader("Compensation by gender")

        fig = go.Figure()

        fig.add_trace(
            go.Scatter(
                x=historical["year"],
                y=historical["male_salary"],
                name="Men",
                mode="lines+markers",
                line=dict(
                    color=NAVY,
                    width=3
                )
            )
        )

        fig.add_trace(
            go.Scatter(
                x=historical["year"],
                y=historical["female_salary"],
                name="Women",
                mode="lines+markers",
                line=dict(
                    color=TEAL,
                    width=3
                )
            )
        )

        fig.update_yaxes(
            tickprefix="€",
            tickformat=",.0f"
        )

        render_chart(fig)

    st.subheader("Executive market brief")
    regional = load_view("vw_regional_benchmarking")
    regional = numeric_columns(regional, ["year", "regional_salary"])
    regional = regional[(regional["year"] == selected_year) & regional["regional_salary"].notna() & ~regional["region"].str.contains(r"^(?:\d+\s+)?(?:Total|España|Nacional|Todas)", case=False, na=False)]
    if not regional.empty:
        high = regional.loc[regional["regional_salary"].idxmax()]
        low = regional.loc[regional["regional_salary"].idxmin()]
        insight(f"Regional salary dispersion: {high['region']} leads at {euro(high['regional_salary'])}, compared with {low['region']} at {euro(low['regional_salary'])}. The spread is {euro(high['regional_salary'] - low['regional_salary'])}.")
    if not previous.empty:
        insight(f"Annual salary change: {annual_delta('average_salary', lambda v: f'{v:+,.2f} €') or 'Unavailable'}. Pay gap change: {annual_delta('gender_pay_gap_pct', pp) or 'Unavailable'}. Changes are nominal and the pay gap is unadjusted.")
    st.subheader("Executive insights")

    insight(
        f"In {selected_year}, Spain recorded an average "
        f"annual salary of {euro(row['average_salary'])}. "
        f"The year-on-year salary change was "
        f"{pct(row['salary_growth_pct'])}, while the "
        f"unadjusted annual gender pay gap stood at "
        f"{pct(row['gender_pay_gap_pct'])}."
    )

    with st.expander("Historical analytical data"):

        show_table(historical)

        download_data(
            historical,
            "executive_overview.csv"
        )


# ============================================================
# 02. REGIONAL BENCHMARKING
# ============================================================

elif page == "Regional Benchmarking":

    page_header(
        "Regional Benchmarking",
        "Evaluate geographical compensation differences "
        "and regional salary competitiveness."
    )

    df = load_view(
        "vw_regional_benchmarking"
    )

    df = numeric_columns(
        df,
        [
            "year",
            "regional_salary",
            "national_salary",
            "salary_difference_pct",
            "salary_growth_yoy_pct",
            "regional_salary_index"
        ]
    )

    current = df[
        (df["year"] == selected_year)
        & df["regional_salary"].notna()
        & ~df["region"].str.contains(
            r"^(?:\d+\s+)?(?:Total|España|Nacional|Todas)",
            case=False,
            na=False
        )
    ].copy()

    require_data(current)

    current = current.sort_values(
        "regional_salary",
        ascending=False
    )

    top = current.iloc[0]
    bottom = current.iloc[-1]

    benchmark = current["national_salary"].dropna()

    national = (
        benchmark.iloc[0]
        if not benchmark.empty
        else float("nan")
    )

    c1, c2, c3, c4 = st.columns(4)

    c1.metric(
        "Highest regional salary",
        euro(top["regional_salary"])
    )

    c2.metric(
        "Lowest regional salary",
        euro(bottom["regional_salary"])
    )

    c3.metric(
        "National benchmark",
        euro(national)
    )

    c4.metric(
        "Regional salary spread",
        euro(
            top["regional_salary"]
            - bottom["regional_salary"]
        )
    )

    st.subheader(f"Geographical salary intelligence · {selected_year}")
    codes = {
        "Galicia":"ES11", "Asturias, Principado de":"ES12", "Cantabria":"ES13",
        "País Vasco":"ES21", "Navarra, Comunidad Foral de":"ES22", "Rioja, La":"ES23",
        "Aragón":"ES24", "Madrid, Comunidad de":"ES30", "Castilla y León":"ES41",
        "Castilla - La Mancha":"ES42", "Extremadura":"ES43", "Cataluña":"ES51",
        "Comunitat Valenciana":"ES52", "Balears, Illes":"ES53", "Andalucía":"ES61",
        "Murcia, Región de":"ES62", "Canarias":"ES70"}
    map_data = current.copy()
    map_data["code"] = map_data["region"].str.replace(r"^\d+\s+", "", regex=True).str.strip().map(codes)
    metrics = {"Average annual salary (€)": "regional_salary", "National benchmark index (Spain = 100)": "regional_salary_index", "Year-on-year salary growth (%)": "salary_growth_yoy_pct"}
    metric = st.selectbox("Map indicator", list(metrics), key="regional_map_indicator")
    column = metrics[metric]
    @st.cache_data(ttl=86400, show_spinner=False)
    def boundaries():
        local = Path(__file__).resolve().parents[1] / "assets" / "spain_nuts2.geojson"
        if local.exists():
            data = json.loads(local.read_text(encoding="utf-8"))
        else:
            with urlopen("https://gisco-services.ec.europa.eu/distribution/v2/nuts/geojson/NUTS_RG_03M_2024_4326_LEVL_2.geojson", timeout=12) as response:
                data = json.load(response)
        features = [f for f in data["features"] if f["properties"].get("NUTS_ID") in codes.values()]
        if len(features) != 17:
            raise ValueError("Incomplete regional boundaries")
        return {"type":"FeatureCollection", "features":features}
    try:
        geo = boundaries()
        fig = px.choropleth(map_data.dropna(subset=["code", column]), geojson=geo,
            locations="code", featureidkey="properties.NUTS_ID", color=column,
            hover_name="region", hover_data={"code":False,"regional_salary":":,.2f","regional_salary_index":":.1f","salary_growth_yoy_pct":":.2f"},
            color_continuous_scale=["#D9C6B3", "#A66B77", "#68283D"], labels={column:metric})
        fig.update_geos(fitbounds="locations", visible=False, projection_type="mercator", bgcolor=WHITE)
        fig.update_traces(marker_line_color=WHITE, marker_line_width=1)
        fig.update_layout(coloraxis_colorbar=dict(title=metric, thickness=14))
        render_chart(fig, height=550)
        st.caption("Salary data: INE. Boundaries: Eurostat GISCO, NUTS 2024. Unmatched or missing observations are omitted.")
    except Exception:
        st.info("Geographical boundaries unavailable. Regional ranking remains available below.")
    if map_data["code"].isna().any():
        st.caption("Unmatched regions: " + ", ".join(map_data.loc[map_data["code"].isna(), "region"].astype(str)))
    st.subheader("Regional salary benchmark · Spain = 100")
    fig = px.bar(current.sort_values("regional_salary_index"), x="regional_salary_index", y="region", orientation="h", color_discrete_sequence=[NAVY], labels={"regional_salary_index":"Benchmark index", "region":""})
    fig.add_vline(x=100, line_dash="dash", line_color=TEAL)
    render_chart(fig, height=550)

    st.subheader(
        f"Regional compensation ranking · {selected_year}"
    )

    fig = ranking_chart(
        current,
        "region",
        "regional_salary",
        "Average annual salary",
        national
    )

    render_chart(
        fig,
        height=max(500, len(current) * 30)
    )

    st.subheader("Regional comparison")

    regions = sorted(
        current["region"].dropna().unique()
    )

    selected_regions = st.multiselect(
        "Select regions",
        regions,
        default=current["region"].head(3).tolist()
    )

    comparison = df[
        df["region"].isin(selected_regions)
        & (df["year"] <= selected_year)
    ].sort_values("year")

    if not comparison.empty:

        fig = salary_line(
            comparison,
            "year",
            "regional_salary",
            "region"
        )

        render_chart(fig)

    insight(
        f"{top['region']} records the highest available "
        f"regional salary in {selected_year}, while "
        f"{bottom['region']} records the lowest. "
        f"The difference amounts to "
        f"{euro(top['regional_salary'] - bottom['regional_salary'])}."
    )

    st.subheader("Regional benchmarking data")

    show_table(
        current[
            [
                "region",
                "regional_salary",
                "national_salary",
                "salary_difference_pct",
                "salary_growth_yoy_pct",
                "regional_salary_index",
                "benchmark_position"
            ]
        ]
    )

    download_data(
        current,
        "regional_benchmarking.csv"
    )


# ============================================================
# 03 & 04. SALARY INTELLIGENCE
# ============================================================

elif page in [
    "Sector Intelligence",
    "Occupational Intelligence"
]:

    is_sector = page == "Sector Intelligence"

    if is_sector:

        view = "vw_sector_salary_intelligence"
        category = "economic_activity"
        index_column = "sector_salary_index"

        description = (
            "Analyse compensation across economic activities "
            "and identify sector-specific salary benchmarks."
        )

    else:

        view = "vw_occupational_salary_intelligence"
        category = "occupation"
        index_column = "occupational_salary_index"

        description = (
            "Explore remuneration by occupational group "
            "and compare workforce salary competitiveness."
        )

    page_header(page, description)

    df = load_view(view)

    df = numeric_columns(
        df,
        [
            "year",
            "average_salary",
            "national_salary",
            "salary_difference_pct",
            "salary_growth_yoy_pct",
            "gender_pay_gap_pct",
            index_column
        ]
    )

    aggregate_pattern = (
        r"^(?:B_S|Total|Todas|Todos|Nacional|España)"
    )

    df = df[
        ~df[category].str.contains(
            aggregate_pattern,
            case=False,
            na=False
        )
    ]

    current = df[
        (df["year"] == selected_year)
        & df["average_salary"].notna()
    ].copy()

    require_data(current)

    current = current.sort_values(
        "average_salary",
        ascending=False
    )

    top = current.iloc[0]
    bottom = current.iloc[-1]

    c1, c2, c3, c4 = st.columns(4)

    c1.metric(
        "Highest average salary",
        euro(top["average_salary"])
    )

    c2.metric(
        "Lowest average salary",
        euro(bottom["average_salary"])
    )

    c3.metric(
        "Salary spread",
        euro(
            top["average_salary"]
            - bottom["average_salary"]
        )
    )

    c4.metric(
        "Categories analysed",
        number(current[category].nunique())
    )

    st.subheader(
        f"Compensation ranking · {selected_year}"
    )

    fig = ranking_chart(
        current,
        category,
        "average_salary",
        "Annual salary",
        top["national_salary"]
    )

    render_chart(
        fig,
        height=max(500, len(current) * 35)
    )

    st.subheader("Salary benchmark index · Spain = 100")
    idx = current.dropna(subset=[index_column]).sort_values(index_column)
    if not idx.empty:
        fig = px.bar(idx, x=index_column, y=category, orientation="h", color_discrete_sequence=[NAVY], labels={index_column:"Benchmark index", category:""})
        fig.add_vline(x=100, line_dash="dash", line_color=TEAL)
        render_chart(fig, height=max(450, len(idx)*30))
    st.subheader("Salary growth and market positioning")

    fig = px.scatter(
        current,
        x="salary_growth_yoy_pct",
        y="average_salary",
        hover_name=category,
        color="benchmark_position",
        color_discrete_sequence=PALETTE,
        labels={
            "salary_growth_yoy_pct": "Annual growth (%)",
            "average_salary": "Annual salary",
            "benchmark_position": "Market position"
        }
    )

    fig.update_traces(
        marker=dict(
            size=13,
            opacity=0.85
        )
    )

    fig.add_vline(
        x=0,
        line_dash="dash",
        line_color=SLATE
    )

    fig.update_yaxes(
        tickprefix="€",
        tickformat=",.0f"
    )

    if pd.notna(top["national_salary"]):
        fig.add_hline(y=float(top["national_salary"]), line_dash="dot", line_color=SLATE)
    render_chart(fig)

    if pd.notna(top["national_salary"]):
        # Reference line is added before rendering in the positioning chart.
        st.caption(f"National salary benchmark: {euro(top['national_salary'])}. Growth is nominal year-on-year.")

    st.subheader("Historical compensation comparison")

    categories = sorted(
        current[category].dropna().unique()
    )

    selected = st.multiselect(
        "Select categories",
        categories,
        default=current[category].head(3).tolist()
    )

    historical = df[
        df[category].isin(selected)
        & (df["year"] <= selected_year)
    ].sort_values("year")

    if not historical.empty:

        fig = salary_line(
            historical,
            "year",
            "average_salary",
            category
        )

        render_chart(fig)

    insight(
        f"The highest available average salary in "
        f"{selected_year} corresponds to {top[category]}, "
        f"at {euro(top['average_salary'])}. "
        f"The lowest corresponds to {bottom[category]}, "
        f"at {euro(bottom['average_salary'])}."
    )

    st.subheader("Compensation intelligence data")

    show_table(
        current[
            [
                category,
                "average_salary",
                "national_salary",
                "salary_difference_pct",
                "salary_growth_yoy_pct",
                "gender_pay_gap_pct",
                index_column,
                "benchmark_position"
            ]
        ]
    )

    download_data(
        current,
        f"{view}.csv"
    )


# ============================================================
# 05. GENDER PAY GAP
# ============================================================

elif page == "Gender Pay Gap":

    page_header(
        "Gender Pay Gap",
        "Monitor unadjusted annual salary differences "
        "between men and women across workforce segments."
    )

    df = load_view(
        "vw_gender_pay_gap"
    )

    df = numeric_columns(
        df,
        [
            "year",
            "male_salary",
            "female_salary",
            "salary_gap_eur",
            "gender_pay_gap_pct",
            "female_to_male_salary_ratio",
            "gap_change_yoy_pp"
        ]
    )

    national = df[
        df["analysis_type"] == "National"
    ].sort_values("year")

    current = national[
        national["year"] == selected_year
    ]

    require_data(current)

    row = current.iloc[0]

    c1, c2, c3, c4 = st.columns(4)

    c1.metric(
        "Male average salary",
        euro(row["male_salary"])
    )

    c2.metric(
        "Female average salary",
        euro(row["female_salary"])
    )

    c3.metric(
        "Unadjusted pay gap",
        pct(row["gender_pay_gap_pct"])
    )

    c4.metric(
        "Annual gap change",
        pp(row["gap_change_yoy_pp"])
    )

    st.subheader("National gender pay gap evolution")

    historical = national[
        national["year"] <= selected_year
    ]

    fig = px.line(
        historical,
        x="year",
        y="gender_pay_gap_pct",
        markers=True,
        color_discrete_sequence=[TEAL],
        labels={
            "year": "Year",
            "gender_pay_gap_pct": "Gender pay gap"
        }
    )

    fig.update_traces(
        line_width=3
    )

    fig.update_yaxes(
        ticksuffix="%"
    )

    render_chart(fig)

    st.subheader("Workforce segment analysis")

    types = sorted(
        df.loc[
            df["analysis_type"] != "National",
            "analysis_type"
        ].dropna().unique()
    )

    if types:

        analysis_type = st.selectbox(
            "Analysis dimension",
            types
        )

        segment = df[
            (df["analysis_type"] == analysis_type)
            & (df["year"] == selected_year)
        ].copy()

        region_values = sorted(
            segment["region"].dropna().unique()
        )

        if len(region_values) > 1:

            region = st.selectbox(
                "Region",
                region_values
            )

            segment = segment[
                segment["region"] == region
            ]

        segment = segment.dropna(
            subset=["gender_pay_gap_pct"]
        )

        if not segment.empty:

            segment = segment.sort_values(
                "gender_pay_gap_pct"
            )

            fig = px.bar(
                segment,
                x="gender_pay_gap_pct",
                y="category",
                orientation="h",
                color="gender_pay_gap_pct",
                color_continuous_scale=[
                    TEAL,
                    "#E3D8C8",
                    NAVY
                ],
                labels={
                    "gender_pay_gap_pct": "Pay gap (%)",
                    "category": ""
                }
            )

            fig.update_layout(
                coloraxis_showscale=False
            )

            fig.add_vline(
                x=0,
                line_color=SLATE
            )

            render_chart(
                fig,
                height=max(450, len(segment) * 30)
            )

            show_table(
                segment[
                    [
                        "category",
                        "male_salary",
                        "female_salary",
                        "salary_gap_eur",
                        "gender_pay_gap_pct",
                        "gap_change_yoy_pp",
                        "gap_trend",
                        "gap_quality_flag"
                    ]
                ]
            )

            download_data(
                segment,
                "gender_pay_gap.csv"
            )

        else:

            st.info(
                "No comparable salary observations "
                "are available for this selection."
            )

    insight(
        f"In {selected_year}, the national annual salary "
        f"difference was {euro(row['salary_gap_eur'])}. "
        f"Women's average annual salary represented "
        f"{pct(row['female_to_male_salary_ratio'])} "
        f"of men's average annual salary."
    )

    st.caption(
        "Methodological note: this is an unadjusted annual "
        "earnings gap. It does not control for working hours, "
        "occupation, seniority or other explanatory factors "
        "and is not a direct measure of unequal pay for equal work."
    )


# ============================================================
# 06. LABOUR COST INTELLIGENCE
# ============================================================

elif page == "Labour Cost Intelligence":

    page_header(
        "Labour Cost Intelligence",
        "Monitor employer labour costs, salary expenditure "
        "and non-salary cost structures."
    )

    df = load_view(
        "vw_labour_cost_intelligence"
    )

    df = numeric_columns(
        df,
        [
            "year",
            "quarter",
            "total_labour_cost",
            "salary_cost",
            "non_salary_cost",
            "employer_contributions",
            "labour_cost_growth_yoy_pct",
            "labour_cost_growth_qoq_pct"
        ]
    )

    periods = (
        df[
            ["year", "quarter", "period"]
        ]
        .drop_duplicates()
        .sort_values(
            ["year", "quarter"],
            ascending=False
        )["period"]
        .tolist()
    )

    period = st.selectbox(
        "Reference quarter",
        periods
    )

    national = df[
        df["analysis_type"] == "National"
    ].sort_values(
        ["year", "quarter"]
    )

    if national.empty:

        national = df[
            df["economic_activity"].str.startswith(
                "B_S",
                na=False
            )
        ].sort_values(
            ["year", "quarter"]
        )

    current = national[
        national["period"] == period
    ]

    require_data(current)

    row = current.iloc[0]

    c1, c2, c3, c4 = st.columns(4)

    c1.metric(
        "Total labour cost",
        euro(row["total_labour_cost"])
    )

    c2.metric(
        "Salary cost",
        euro(row["salary_cost"])
    )

    c3.metric(
        "Non-salary cost",
        euro(row["non_salary_cost"])
    )

    c4.metric(
        "Year-on-year growth",
        pct(row["labour_cost_growth_yoy_pct"])
    )

    st.caption(
        "Quarterly observations expressed in the "
        "original monetary unit of the source series."
    )

    st.subheader("National labour cost evolution")

    historical = national[
        (
            national["year"] * 4
            + national["quarter"]
        ) <= (
            row["year"] * 4
            + row["quarter"]
        )
    ]

    fig = salary_line(
        historical,
        "period",
        "total_labour_cost"
    )

    fig.update_xaxes(
        nticks=12
    )

    render_chart(fig)

    left, right = st.columns(2)

    with left:

        st.subheader("Labour cost composition")

        values = [
            row["salary_cost"],
            row["non_salary_cost"]
        ]

        if all(
            pd.notna(v) and v >= 0
            for v in values
        ) and sum(values) > 0:

            fig = go.Figure(
                go.Pie(
                    labels=[
                        "Salary cost",
                        "Non-salary cost"
                    ],
                    values=values,
                    hole=0.70,
                    marker=dict(
                        colors=[NAVY, TEAL]
                    )
                )
            )

            render_chart(fig)

    with right:

        st.subheader("Cost growth dynamics")

        fig = px.line(
            historical,
            x="period",
            y=[
                "labour_cost_growth_yoy_pct",
                "labour_cost_growth_qoq_pct"
            ],
            color_discrete_sequence=[
                NAVY,
                TEAL
            ]
        )

        fig.update_xaxes(
            nticks=8
        )

        fig.update_yaxes(
            ticksuffix="%"
        )

        render_chart(fig)

    st.subheader("Labour cost by economic activity")

    sector = df[
        (df["period"] == period)
        & (df["analysis_type"] == "Economic Activity")
    ].dropna(
        subset=["total_labour_cost"]
    )

    if not sector.empty:

        fig = ranking_chart(
            sector,
            "economic_activity",
            "total_labour_cost",
            "Total labour cost",
            row["total_labour_cost"]
        )

        render_chart(
            fig,
            height=max(550, len(sector) * 35)
        )

        show_table(
            sector.sort_values(
                "total_labour_cost",
                ascending=False
            )[
                [
                    "economic_activity",
                    "total_labour_cost",
                    "salary_cost",
                    "non_salary_cost",
                    "employer_contributions",
                    "labour_cost_growth_yoy_pct",
                    "benchmark_position"
                ]
            ]
        )

        download_data(
            sector,
            "labour_cost_intelligence.csv"
        )

    insight(
        f"The national labour cost observation for "
        f"{period} was {euro(row['total_labour_cost'])}, "
        f"with a year-on-year change of "
        f"{pct(row['labour_cost_growth_yoy_pct'])}."
    )


# ============================================================
# 07. WORKFORCE COST SIMULATOR
# ============================================================

elif page == "Workforce Cost Simulator":

    page_header(
        "Workforce Cost Simulator",
        "Model annual workforce expenditure and estimate "
        "the financial impact of compensation decisions."
    )

    df = load_view(
        "vw_labour_cost_intelligence"
    )

    df = numeric_columns(
        df,
        [
            "year",
            "quarter",
            "salary_cost",
            "non_salary_cost",
            "total_labour_cost"
        ]
    )

    df = df[
        df["analysis_type"] == "Economic Activity"
    ].copy()

    df = df[
        (df["salary_cost"] > 0)
        & df["non_salary_cost"].notna()
    ]

    require_data(df)

    periods = (
        df[
            ["year", "quarter", "period"]
        ]
        .drop_duplicates()
        .sort_values(
            ["year", "quarter"],
            ascending=False
        )["period"]
        .tolist()
    )

    st.subheader("Workforce assumptions")

    left, right = st.columns(2)

    with left:

        period = st.selectbox(
            "Labour cost benchmark period",
            periods
        )

        available = df[
            df["period"] == period
        ]

        activity = st.selectbox(
            "Economic activity",
            sorted(
                available["economic_activity"]
                .dropna()
                .unique()
            )
        )

        employees = st.number_input(
            "Number of employees",
            min_value=1,
            max_value=100000,
            value=25,
            step=1
        )

        gross_salary = st.number_input(
            "Annual gross salary per employee (€)",
            min_value=0.0,
            max_value=1000000.0,
            value=30000.0,
            step=1000.0
        )

    benchmark = available[
        available["economic_activity"] == activity
    ].iloc[0]

    benchmark_rate = (
        benchmark["non_salary_cost"]
        / benchmark["salary_cost"]
        * 100
    )

    with right:

        st.metric(
            "Sector non-salary / salary cost ratio",
            pct(benchmark_rate)
        )

        custom_rate = st.checkbox(
            "Override sector cost assumption"
        )

        if custom_rate:

            cost_rate = st.number_input(
                "Non-salary cost rate (%)",
                min_value=0.0,
                max_value=200.0,
                value=float(
                    min(
                        max(benchmark_rate, 0),
                        200
                    )
                ),
                step=0.5
            )

        else:

            cost_rate = float(benchmark_rate)

        salary_increase = st.slider(
            "Projected salary adjustment (%)",
            min_value=-10.0,
            max_value=30.0,
            value=3.0,
            step=0.5
        )

        additional_cost = st.number_input(
            "Additional annual cost per employee (€)",
            min_value=0.0,
            value=0.0,
            step=100.0
        )

    salary_budget = employees * gross_salary

    non_salary_budget = (
        salary_budget * cost_rate / 100
    )

    additional_budget = (
        employees * additional_cost
    )

    total_budget = (
        salary_budget
        + non_salary_budget
        + additional_budget
    )

    projected_salary = (
        salary_budget
        * (1 + salary_increase / 100)
    )

    projected_non_salary = (
        projected_salary
        * cost_rate / 100
    )

    projected_budget = (
        projected_salary
        + projected_non_salary
        + additional_budget
    )

    difference = (
        projected_budget - total_budget
    )

    st.divider()

    st.subheader("Annual workforce budget")

    c1, c2, c3, c4 = st.columns(4)

    c1.metric(
        "Gross salary expenditure",
        euro(salary_budget)
    )

    c2.metric(
        "Estimated non-salary cost",
        euro(non_salary_budget)
    )

    c3.metric(
        "Total workforce cost",
        euro(total_budget)
    )

    c4.metric(
        "Cost per employee",
        euro(total_budget / employees)
    )

    st.subheader("Budget scenario comparison")

    scenarios = pd.DataFrame({
        "Scenario": [
            "Current",
            "Projected"
        ],
        "Gross salaries": [
            salary_budget,
            projected_salary
        ],
        "Non-salary costs": [
            non_salary_budget,
            projected_non_salary
        ],
        "Additional costs": [
            additional_budget,
            additional_budget
        ]
    })

    fig = px.bar(
        scenarios,
        x="Scenario",
        y=[
            "Gross salaries",
            "Non-salary costs",
            "Additional costs"
        ],
        barmode="stack",
        color_discrete_sequence=[
            NAVY,
            TEAL,
            "#B9A99A"
        ]
    )

    fig.update_yaxes(
        tickprefix="€",
        tickformat=",.0f"
    )

    render_chart(fig)

    c1, c2, c3 = st.columns(3)

    c1.metric(
        "Projected annual budget",
        euro(projected_budget)
    )

    c2.metric(
        "Annual budget impact",
        euro(difference)
    )

    c3.metric(
        "Projected monthly budget",
        euro(projected_budget / 12)
    )

    insight(
        f"A workforce of {employees:,} employees with "
        f"an average annual gross salary of "
        f"{euro(gross_salary)} generates an estimated "
        f"annual workforce cost of {euro(total_budget)}. "
        f"The selected salary adjustment of "
        f"{salary_increase:+.1f}% changes the estimated "
        f"annual budget by {euro(difference)}."
    )

    st.caption(
        "Planning estimate, not a payroll calculation. "
        "The benchmark uses the observed non-salary-to-salary "
        "cost ratio for the selected activity and period. "
        "Actual employer costs depend on individual contracts, "
        "contribution bases, applicable regulations and benefits. "
        "Additional costs should exclude amounts already "
        "represented in the non-salary cost assumption."
    )

    st.divider()
    st.subheader("Strategic workforce planning")
    st.caption("Illustrative scenarios with constant cost ratio and additional cost per employee. Not a forecast of market wages.")
    a, b = st.columns(2)
    with a:
        hires = st.number_input("Additional employees in year 1", min_value=0, max_value=100000, value=0, step=1)
    with b:
        annual_raise = st.slider("Annual salary growth in years 2–5 (%)", -5.0, 15.0, 3.0, 0.5)
    spread = st.slider("Scenario adjustment around base (percentage points)", 0.0, 10.0, 2.0, 0.5)
    scenario_rows = []
    for name, adjustment in [("Conservative", salary_increase - spread), ("Base", salary_increase), ("Expansion", salary_increase + spread)]:
        for year in range(1, 6):
            wage = gross_salary * (1 + adjustment / 100) * (1 + annual_raise / 100) ** (year - 1)
            budget = (employees + hires) * (wage * (1 + cost_rate / 100) + additional_cost)
            scenario_rows.append({"Scenario": name, "Year": year, "Annual budget": budget})
    projection = pd.DataFrame(scenario_rows)
    fig = px.line(projection, x="Year", y="Annual budget", color="Scenario", markers=True, color_discrete_sequence=PALETTE)
    fig.update_yaxes(tickprefix="€", tickformat=",.0f")
    fig.update_xaxes(dtick=1)
    render_chart(fig)
    show_table(projection.pivot(index="Year", columns="Scenario", values="Annual budget").reset_index())
    download_data(projection, "five_year_workforce_scenarios.csv")

    result = pd.DataFrame({
        "Economic activity": [activity],
        "Benchmark period": [period],
        "Employees": [employees],
        "Annual gross salary": [gross_salary],
        "Non-salary cost rate": [cost_rate],
        "Current annual budget": [total_budget],
        "Projected annual budget": [projected_budget],
        "Annual budget impact": [difference]
    })

    download_data(
        result,
        "workforce_cost_simulation.csv"
    )


# ============================================================
# 08. DATA & METHODOLOGY
# ============================================================

elif page == "Data & Methodology":

    page_header(
        "Data & Methodology",
        "Data provenance, analytical definitions "
        "and technical architecture."
    )

    st.subheader("Platform purpose")

    st.write(
        "HR Compensation Intelligence is an independent "
        "analytics platform designed to support workforce "
        "compensation benchmarking, labour market research "
        "and strategic workforce cost planning in Spain."
    )

    c1, c2, c3 = st.columns(3)

    c1.metric(
        "Official source datasets",
        "5"
    )

    c2.metric(
        "Analytical SQL views",
        str(len(ALLOWED_VIEWS))
    )

    c3.metric(
        "Analytical modules",
        "8"
    )

    st.divider()

    st.subheader("Data sources")

    sources = pd.DataFrame({
        "Dataset ID": [
            "6032",
            "28185",
            "28186",
            "28192",
            "28193"
        ],
        "Analytical domain": [
            "Labour costs by economic activity",
            "Annual salaries by economic activity",
            "Annual salaries by occupation",
            "Regional salaries by sector",
            "Regional salaries by occupation"
        ],
        "Provider": [
            "INE",
            "INE",
            "INE",
            "INE",
            "INE"
        ]
    })

    sources["Official table"] = sources["Dataset ID"].map(lambda x: f"https://www.ine.es/jaxiT3/Tabla.htm?t={x}")
    st.dataframe(sources, hide_index=True, width="stretch", column_config={"Official table": st.column_config.LinkColumn("Official table", display_text="Open INE table")})

    st.link_button(
        "Instituto Nacional de Estadística",
        "https://www.ine.es/"
    )

    st.subheader("Technical architecture")

    architecture = pd.DataFrame({
        "Layer": [
            "Source",
            "Data preparation",
            "Staging",
            "Data warehouse",
            "Analytics",
            "Data access",
            "Presentation"
        ],
        "Technology": [
            "INE CSV datasets",
            "Python / Pandas",
            "PostgreSQL",
            "Relational dimensional model",
            "SQL analytical views",
            "SQLAlchemy / PostgreSQL driver",
            "Streamlit / Plotly"
        ],
        "Purpose": [
            "Official statistical observations",
            "Cleaning and standardisation",
            "Structured data ingestion",
            "Dimensions and fact tables",
            "Business metrics and benchmarking",
            "Application database connectivity",
            "Interactive analytical interface"
        ]
    })

    stages = [("01", "INE", "Official data"), ("02", "Python", "ETL"), ("03", "PostgreSQL", "Warehouse"), ("04", "SQL", "Analytics"), ("05", "Streamlit", "Delivery")]
    for col, (step, name, detail) in zip(st.columns(5), stages):
        with col:
            st.caption(step)
            st.markdown(f"**{name}**")
            st.caption(detail)
    show_table(architecture)

    st.subheader("Analytical definitions")

    definitions = pd.DataFrame({
        "Metric": [
            "Average annual salary",
            "Year-on-year salary growth",
            "Gender pay gap",
            "Salary benchmark index",
            "Non-salary cost ratio",
            "Estimated workforce budget"
        ],
        "Definition": [
            "Reported mean annual gross earnings",
            "(Current salary / Previous salary - 1) × 100",
            "(Male salary - Female salary) / Male salary × 100",
            "Category salary / National salary × 100",
            "Non-salary cost / Salary cost × 100",
            "Gross salary budget plus estimated non-salary and additional costs"
        ]
    })

    show_table(definitions)

    st.subheader("Data quality and limitations")

    st.markdown("""
    - Missing observations are not automatically treated as zero.
    - Annual salary and quarterly labour cost series are analysed separately.
    - Salary benchmarks represent aggregated statistical observations.
    - Gender pay gap indicators are unadjusted.
    - Published salary estimates may carry statistical quality flags.
    - Workforce cost simulations are illustrative planning estimates.
    - Nominal salary changes are not adjusted for inflation.
    """)

    st.subheader("Data quality report")
    root = Path(__file__).resolve().parents[1] / "data" / "raw"
    quality = []
    for dataset in [6032, 28185, 28186, 28192, 28193]:
        path = root / f"{dataset}.csv"
        if not path.exists():
            continue
        try:
            raw = pd.read_csv(path, sep=";", encoding="latin1", dtype=str, keep_default_na=False)
            values = pd.to_numeric(raw["Total"].str.replace(".", "", regex=False).str.replace(",", ".", regex=False), errors="coerce")
            quality.append({"Dataset":str(dataset), "Rows":len(raw), "Missing / nonnumeric":int(values.isna().sum()), "Numeric coverage (%)":round(100*values.notna().mean(),2), "Duplicate dimension keys":int(raw.duplicated(subset=[c for c in raw.columns if c != "Total"]).sum()), "First period":raw["Periodo"].min(), "Last period":raw["Periodo"].max()})
        except (OSError, ValueError, KeyError) as exc:
            st.warning(f"Dataset {dataset}: quality report unavailable ({type(exc).__name__}).")
    if quality:
        report = pd.DataFrame(quality)
        show_table(report)
        download_data(report, "source_data_quality.csv")
    if len(quality) < 5:
        st.caption("Some raw source files are unavailable in this deployment; only accessible files are reported.")
    st.caption("Coverage is calculated from raw source rows; nonnumeric observations are not interpreted as zero. Numeric coverage is not a statistical reliability measure.")
    for dataset in [6032, 28185, 28186, 28192, 28193]:
        st.markdown(f"[INE dataset {dataset}](https://www.ine.es/jaxiT3/Tabla.htm?t={dataset})")
    st.subheader("Database inventory")

    if st.button("Inspect analytical views"):

        inventory = []

        for view in sorted(ALLOWED_VIEWS):

            data = load_view(view)

            inventory.append({
                "Analytical view": view,
                "Records": len(data),
                "Columns": len(data.columns)
            })

        show_table(
            pd.DataFrame(inventory)
        )

    st.subheader("Project information")

    st.write(
        "Independent Business Intelligence and People Analytics "
        "portfolio project developed using official Spanish "
        "labour market statistics."
    )


# ============================================================
# APPLICATION FOOTER
# ============================================================

st.markdown("""
<div class="footer">
    HR Compensation Intelligence &nbsp;·&nbsp;
    Spanish Labour Market Analytics &nbsp;·&nbsp;
    INE / PostgreSQL / Python &nbsp;·&nbsp;
    Independent Analytics Project &nbsp;·&nbsp;
    Official statistics, independent analysis
</div>
""", unsafe_allow_html=True)