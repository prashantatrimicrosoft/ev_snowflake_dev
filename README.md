# EV Snowflake Data Engineering & AI Analytics Platform

An end-to-end modern Data Engineering and AI Analytics implementation built on Snowflake.

This project demonstrates how to design and operationalize a scalable Medallion Architecture pipeline with:

- Bronze / Silver / Gold data layers
- dbt transformations
- Snowpark transformation considerations
- Event-driven orchestration
- Data Quality validation framework
- Apache Iceberg interoperability strategy
- Cortex Analyst semantic modeling
- AI Agent integration patterns
- Streamlit conversational analytics
- Secure data sharing
- Cost optimization practices
- Git-integrated development workflows

---

# Repository

https://github.com/prashantatrimicrosoft/ev_snowflake_dev

---

# Solution Architecture

```text
                ┌──────────────────────────┐
                │ EV JSON Dataset          │
                │ Washington EV Population │
                └────────────┬─────────────┘
                             │
                             ▼
                 ┌────────────────────┐
                 │ Bronze Layer       │
                 │ Raw JSON Landing   │
                 │ VARIANT Storage    │
                 └─────────┬──────────┘
                           │
                           ▼
                 ┌────────────────────┐
                 │ Silver Layer       │
                 │ Cleansing          │
                 │ Validation         │
                 │ Deduplication      │
                 │ dbt Models         │
                 └─────────┬──────────┘
                           │
                           ▼
                 ┌────────────────────┐
                 │ Gold Layer         │
                 │ Star Schema        │
                 │ Aggregates         │
                 │ Semantic Models    │
                 └─────────┬──────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   Streamlit UI     Cortex Analyst     Data Sharing
   Conversational   Semantic Layer     Cross Account
   Analytics        AI Queries         Marketplace
