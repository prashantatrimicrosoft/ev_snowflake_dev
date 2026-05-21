
---

# `docs/gold-layer.md`

```markdown id="34kzcs"
# Gold Layer

# Purpose

The Gold layer provides business-ready analytical models optimized for:
- BI reporting
- AI agents
- Semantic querying
- Executive dashboards
- Data sharing

---

# Gold Layer Design

The Gold layer follows a dimensional modeling approach using:
- Fact tables
- Dimension tables
- Aggregated marts

---

# Star Schema

## Fact Table

| Table | Purpose |
|---|---|
| FACT_EV_REGISTRATIONS | Core vehicle registration facts |

---

## Dimension Tables

| Table | Purpose |
|---|---|
| DIM_VEHICLE | Vehicle metadata |
| DIM_GEOGRAPHY | Geographic hierarchy |
| DIM_DATE | Time intelligence |
| DIM_UTILITY | Utility provider metadata |

---

## Aggregated Marts

| Table | Purpose |
|---|---|
| AGG_YOY_GROWTH | Trend analysis |
| AGG_REGIONAL_ADOPTION | Regional adoption |
| AGG_MARKET_SHARE | OEM market share |
| AGG_CAFV_ELIGIBILITY | Incentive analytics |
| AGG_MODEL_TRENDS | Vehicle trends |

---

# Why Dimensional Modeling?

Benefits:
- Faster analytics
- Better semantic modeling
- Easier BI integration
- AI-friendly structure
- Simplified business consumption

---

# Business Metrics Generated

## EV Growth Trends
- YoY growth analysis
- Cumulative registrations

---

## Market Share
- Tesla vs competitors
- Regional OEM distribution

---

## Regional Adoption
- County-level adoption
- Geographic penetration

---

## Incentive Analysis
- CAFV eligibility
- Incentive adoption patterns

---

# Gold Layer Optimization

Implemented:
- Pre-aggregated marts
- Analytics-friendly models
- Reduced join complexity
- AI semantic alignment

---

# Why Aggregated Marts?

Benefits:
- Faster dashboard performance
- Simplified AI querying
- Reduced compute usage
- Lower BI latency

---

# Iceberg Considerations

Gold layer tables were identified as ideal Iceberg candidates because they are:
- Stable
- Widely consumed
- Shared externally
- Analytics optimized

---

# Key Learnings

- Gold layer should prioritize business usability
- Semantic alignment matters for AI
- Aggregates improve both cost and performance
- Star schema still works extremely well for AI analytics