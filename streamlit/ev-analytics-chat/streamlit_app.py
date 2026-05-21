import os
import streamlit as st
import altair as alt
import pandas as pd

VERIFIED_QUERIES = {
    "yoy_growth": {
        "keywords": ["yoy", "year over year", "growth", "trend", "annual", "growing"],
        "title": "YoY Growth Trend in EV Registrations",
        "description": "Shows registration counts and year-over-year growth by EV type. Note: 2023 data is partial (dataset extracted mid-2023).",
        "sql": """
            SELECT MODEL_YEAR, EV_TYPE_SHORT, REGISTRATIONS AS REGISTRATION_COUNT,
                   YOY_GROWTH_PCT, CUMULATIVE_REGISTRATIONS, PCT_OF_YEAR_TOTAL
            FROM EV_GOLD.SERVING.AGG_YOY_GROWTH
            ORDER BY MODEL_YEAR, EV_TYPE_SHORT
        """,
        "suggestions": ["Which regions have the highest adoption?", "What is the BEV vs PHEV split?"],
    },
    "regional_adoption": {
        "keywords": ["region", "county", "adoption", "where", "location", "geographic", "area", "king", "snohomish"],
        "title": "Regional EV Adoption (Top 10 WA Counties)",
        "description": "King County leads with 52.5% of all WA EV registrations, followed by Snohomish and Pierce.",
        "sql": """
            SELECT COUNTY, REGION_GROUP,
                   SUM(REGISTRATIONS) AS TOTAL_EVS,
                   ROUND(100.0 * SUM(REGISTRATIONS) / 22120, 2) AS WA_SHARE_PCT
            FROM EV_GOLD.SERVING.AGG_REGIONAL_ADOPTION
            GROUP BY COUNTY, REGION_GROUP
            ORDER BY TOTAL_EVS DESC
            LIMIT 10
        """,
        "suggestions": ["Compare Tesla vs others by region", "What is the YoY growth trend?"],
    },
    "bev_vs_phev": {
        "keywords": ["bev", "phev", "battery", "plug-in", "hybrid", "penetration", "vehicle type", "type split", "electric type"],
        "title": "Market Penetration: BEV vs PHEV",
        "description": "BEVs dominate with 76.91% of all registrations (17,060 vehicles). PHEVs account for 23.09% (5,123).",
        "sql": """
            SELECT EV_TYPE_SHORT,
                   SUM(REGISTRATIONS) AS TOTAL,
                   ROUND(100.0 * SUM(REGISTRATIONS) / 22183, 2) AS MARKET_SHARE_PCT
            FROM EV_GOLD.SERVING.AGG_MARKET_SHARE
            GROUP BY EV_TYPE_SHORT
            ORDER BY TOTAL DESC
        """,
        "suggestions": ["What is the YoY growth trend?", "What percentage are CAFV eligible?"],
    },
    "tesla_market_share": {
        "keywords": ["tesla", "market share", "manufacturer", "brand", "compare", "vs other", "oem"],
        "title": "Tesla vs Other Manufacturers — Market Share",
        "description": "Tesla holds 44.71% market share in WA. All other manufacturers combined hold 55.29%.",
        "sql": """
            SELECT
              CASE WHEN IS_TESLA THEN 'Tesla' ELSE 'Other' END AS MANUFACTURER_GROUP,
              STATE_CODE,
              SUM(REGISTRATIONS) AS TOTAL,
              ROUND(100.0 * SUM(REGISTRATIONS) /
                SUM(SUM(REGISTRATIONS)) OVER (PARTITION BY STATE_CODE), 2) AS SHARE_PCT
            FROM EV_GOLD.SERVING.AGG_MARKET_SHARE
            WHERE STATE_CODE = 'WA'
            GROUP BY CASE WHEN IS_TESLA THEN 'Tesla' ELSE 'Other' END, STATE_CODE
        """,
        "suggestions": ["Which models are trending?", "Which regions have the highest adoption?"],
    },
    "cafv_eligibility": {
        "keywords": ["cafv", "eligible", "incentive", "clean fuel", "alternative fuel", "percentage eligible"],
        "title": "CAFV Incentive Eligibility Breakdown",
        "description": "50.33% of EVs are eligible for Clean Alternative Fuel Vehicle incentives. 36.76% have unknown eligibility (battery range not researched).",
        "sql": """
            SELECT EV_TYPE_SHORT, CAFV_ELIGIBILITY,
                   REGISTRATIONS AS VEHICLE_COUNT,
                   PCT_OF_TOTAL AS ELIGIBILITY_PCT,
                   PCT_WITHIN_EV_TYPE AS TYPE_ELIGIBILITY_PCT
            FROM EV_GOLD.SERVING.AGG_CAFV_ELIGIBILITY
            ORDER BY REGISTRATIONS DESC
        """,
        "suggestions": ["What is the BEV vs PHEV split?", "What is the YoY growth trend?"],
    },
    "trending_models": {
        "keywords": ["model", "trending", "popular", "top", "rank", "model 3", "model y", "leaf", "bolt"],
        "title": "Top Trending Vehicle Models (2022)",
        "description": "Tesla Model 3 leads overall, followed by Model Y and Nissan Leaf. Showing top 10 models by 2022 registrations.",
        "sql": """
            SELECT MAKE, MODEL, MODEL_YEAR, REGISTRATIONS AS REGISTRATION_COUNT,
                   RANK_IN_YEAR, YOY_MOMENTUM_PCT
            FROM EV_GOLD.SERVING.AGG_MODEL_TRENDS
            WHERE MODEL_YEAR = 2022 AND RANK_IN_YEAR <= 10
            ORDER BY RANK_IN_YEAR
        """,
        "suggestions": ["Compare Tesla vs other manufacturers", "What is the YoY growth trend?"],
    },
    "total_overview": {
        "keywords": ["total", "how many", "count", "overview", "summary", "all", "registrations", "dataset"],
        "title": "EV Registration Overview",
        "description": "Washington State EV Population dataset: 22,183 registered vehicles across 33 makes, 111 models, spanning 1999-2023.",
        "sql": """
            SELECT
                COUNT(*) AS TOTAL_VEHICLES,
                COUNT(DISTINCT v.MAKE) AS UNIQUE_MAKES,
                COUNT(DISTINCT v.MODEL) AS UNIQUE_MODELS,
                MIN(f.DATE_KEY) AS EARLIEST_YEAR,
                MAX(f.DATE_KEY) AS LATEST_YEAR,
                SUM(CASE WHEN v.EV_TYPE_SHORT = 'BEV' THEN 1 ELSE 0 END) AS BEV_COUNT,
                SUM(CASE WHEN v.EV_TYPE_SHORT = 'PHEV' THEN 1 ELSE 0 END) AS PHEV_COUNT,
                SUM(CASE WHEN f.IS_WA_RECORD THEN 1 ELSE 0 END) AS WA_VEHICLES
            FROM EV_GOLD.SERVING.FACT_EV_REGISTRATIONS f
            LEFT JOIN EV_GOLD.SERVING.DIM_VEHICLE v ON f.VEHICLE_KEY = v.VEHICLE_KEY
        """,
        "suggestions": ["What is the YoY growth trend?", "Which regions have the highest adoption?"],
    },
}

SUGGESTIONS = {
    ":blue[:material/trending_up:] YoY growth trend": "What is the YoY growth trend in EV registrations?",
    ":green[:material/map:] Regional adoption": "Which regions have the highest EV adoption rates?",
    ":orange[:material/electric_car:] BEV vs PHEV": "What is market penetration by vehicle type (BEV vs PHEV)?",
    ":red[:material/business:] Tesla market share": "Compare Tesla vs other manufacturers in market share by region",
    ":violet[:material/savings:] CAFV eligibility": "What percentage of EVs are eligible for CAFV incentives?",
    ":blue[:material/auto_graph:] Trending models": "Which vehicle models are trending?",
}

st.set_page_config(page_title="EV Analytics Chat", page_icon=":material/electric_car:", layout="wide")
st.title(":material/electric_car: EV Analytics Chat")
st.caption("Ask questions about Washington State's 22,183 registered electric vehicles")

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))


def match_query(user_input):
    lower_input = user_input.lower()
    best_match = None
    best_score = 0
    for key, vqr in VERIFIED_QUERIES.items():
        score = sum(1 for kw in vqr["keywords"] if kw in lower_input)
        if score > best_score:
            best_score = score
            best_match = key
    if best_match:
        return VERIFIED_QUERIES[best_match]
    return VERIFIED_QUERIES["total_overview"]


def auto_chart(df):
    if df.empty or len(df.columns) < 2:
        return None
    numeric_cols = df.select_dtypes(include=["number"]).columns.tolist()
    non_numeric_cols = [c for c in df.columns if c not in numeric_cols]
    if not numeric_cols or not non_numeric_cols:
        return None
    x_col = non_numeric_cols[0]
    y_col = numeric_cols[0]
    color_col = non_numeric_cols[1] if len(non_numeric_cols) > 1 else None
    is_time_like = any(kw in x_col.upper() for kw in ["YEAR", "DATE", "MONTH", "TIME"])
    if is_time_like:
        chart = alt.Chart(df).mark_line(point=True).encode(
            x=alt.X(x_col, sort=None),
            y=alt.Y(y_col),
            **({"color": color_col} if color_col else {}),
        )
    else:
        chart = alt.Chart(df).mark_bar().encode(
            x=alt.X(y_col),
            y=alt.Y(x_col, sort="-x"),
            **({"color": color_col} if color_col else {}),
        )
    return chart.properties(height=400).interactive()


if "messages" not in st.session_state:
    st.session_state.messages = []

if not st.session_state.messages:
    selected = st.pills("Try asking:", list(SUGGESTIONS.keys()), label_visibility="collapsed")
    if selected:
        prompt = SUGGESTIONS[selected]
        st.session_state.messages.append({"role": "user", "content": prompt})
        st.rerun()

for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        if msg["role"] == "assistant":
            if "text" in msg:
                st.markdown(msg["text"])
            if "sql" in msg and msg["sql"]:
                with st.expander(":material/code: View SQL", expanded=False):
                    st.code(msg["sql"], language="sql")
            if "df" in msg and msg["df"] is not None:
                st.dataframe(msg["df"], use_container_width=True)
                chart = auto_chart(msg["df"])
                if chart:
                    st.altair_chart(chart, use_container_width=True)
            if "suggestions" in msg and msg["suggestions"]:
                st.caption("Suggested follow-ups:")
                for s in msg["suggestions"]:
                    st.markdown(f"- {s}")
        else:
            st.write(msg["content"])

if prompt := st.chat_input("Ask about EV registrations, trends, or market share..."):
    st.session_state.messages.append({"role": "user", "content": prompt})

    with st.chat_message("user"):
        st.write(prompt)

    with st.chat_message("assistant"):
        with st.spinner("Analyzing..."):
            try:
                matched = match_query(prompt)
                display_text = f"**{matched['title']}**\n\n{matched['description']}"
                st.markdown(display_text)

                sql_query = matched["sql"]
                with st.expander(":material/code: View SQL", expanded=False):
                    st.code(sql_query.strip(), language="sql")

                df = conn.query(sql_query)
                st.dataframe(df, use_container_width=True)

                chart = auto_chart(df)
                if chart:
                    st.altair_chart(chart, use_container_width=True)

                suggestions = matched.get("suggestions", [])
                if suggestions:
                    st.caption("Suggested follow-ups:")
                    for s in suggestions:
                        st.markdown(f"- {s}")

                st.session_state.messages.append({
                    "role": "assistant",
                    "text": display_text,
                    "sql": sql_query.strip(),
                    "df": df,
                    "suggestions": suggestions,
                })
            except Exception as e:
                error_msg = f"Sorry, I encountered an error: {str(e)}"
                st.error(error_msg)
                st.session_state.messages.append({
                    "role": "assistant",
                    "text": error_msg,
                    "sql": None,
                    "df": None,
                    "suggestions": [],
                })
