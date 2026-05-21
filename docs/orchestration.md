# Orchestration

# Purpose

The orchestration layer automates the end-to-end pipeline execution with:
- Scheduling
- Dependency management
- Event-driven execution
- Error handling

---

# Orchestration Options Evaluated

| Option | Use Case |
|---|---|
| Snowflake Tasks | Native orchestration |
| Dynamic Tables | Incremental refresh |
| Streams + Tasks | CDC/event-driven |
| Airflow | Enterprise orchestration |
| External event triggers | File-based automation |

---

# Implemented Pattern

The pipeline uses:
- Streams
- Tasks
- dbt execution
- Event-driven orchestration

---

# Pipeline Flow

```text
JSON Upload
    ↓
COPY INTO Bronze
    ↓
STREAM detects changes
    ↓
TASK triggers Silver Stored Procedure
    ↓
dbt Silver Build
    ↓
dbt Gold Build
    ↓
Audit Logging