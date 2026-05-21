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

# Project Structure

```
ev_snowflake_dev/
├── README.md
├── docs/                          # Documentation (architecture, design decisions)
├── sql/
│   ├── bronze/                    # Bronze layer DDL and ingestion
│   │   ├── verify_stage_upload.sql
│   │   ├── load_bronze.sql
│   │   ├── preview_bronze_data.sql
│   │   ├── create_master_tables.sql
│   │   └── insert_load_audit.sql
│   ├── gold/                      # Gold layer utilities
│   │   └── convert_to_iceberg.sql
│   ├── semantic/                  # Cortex Analyst + Agent setup
│   │   ├── deploy_semantic_model.sql
│   │   └── create_cortex_agent.sql
│   └── sharing/                   # Data sharing simulation
│       └── data_sharing_simulation.sql
├── dbt/
│   ├── ev_pipeline_silver/        # Silver dbt project (Bronze → Silver)
│   │   ├── dbt_project.yml
│   │   ├── profiles.yml
│   │   └── models/
│   └── ev_pipeline_gold/          # Gold dbt project (Silver → Gold)
│       ├── dbt_project.yml
│       ├── profiles.yml
│       ├── models/
│       ├── macros/
│       └── tests/
├── streamlit/
│   └── ev-analytics-chat/         # Cortex Analyst chat interface
│       ├── streamlit_app.py
│       ├── snowflake.yml
│       └── pyproject.toml
├── semantic_models/
│   └── ev_gold_semantic.yaml      # Cortex Analyst semantic model (9 tables, 6 VQRs)
├── orchestration/
│   └── orchestration_task_dag.sql # Event-driven task DAG (Stream + 4 Tasks)
├── dq_checks/
│   └── bronze_quality_checks.sql  # Bronze layer DQ validation
└── datasets/                      # Sample test data
```

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
