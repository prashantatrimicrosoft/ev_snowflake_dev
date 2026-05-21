# Architecture Overview

# Solution Summary

This project demonstrates an end-to-end modern Data Engineering and AI Analytics platform built on Snowflake using the Washington State Electric Vehicle Population dataset.

The implementation showcases:

- Medallion architecture
- Semi-structured JSON ingestion
- dbt-driven transformations
- Snowflake-native orchestration
- Data quality validation framework
- Open table format strategy
- Semantic modeling with Cortex Analyst
- AI Agent integration patterns
- Secure enterprise data sharing
- Conversational analytics using Streamlit

---

# High-Level Architecture

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