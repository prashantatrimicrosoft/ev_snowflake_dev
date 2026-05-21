
---

# `docs/bronze-layer.md`

```markdown id="u6kdn0"
# Bronze Layer

# Purpose

The Bronze layer stores raw source data exactly as received from upstream systems.

This layer prioritizes:
- Raw fidelity
- Replayability
- Auditability
- Low transformation overhead

---

# Dataset Characteristics

| Property | Value |
|---|---|
| Format | JSON |
| Records | ~22,183 |
| Source | Washington EV Population Dataset |
| Structure | Semi-structured |

---

# Bronze Layer Objects

| Object | Description |
|---|---|
| WH_INGEST | Ingestion warehouse |
| EV_BRONZE | Bronze database |
| RAW schema | Raw ingestion schema |
| EV_POPULATION_RAW | Raw landing table |
| STG_EV_JSON | Internal stage |
| LOAD_AUDIT | Audit tracking table |

---

# Warehouse Configuration

```sql
CREATE WAREHOUSE WH_INGEST
WITH
WAREHOUSE_SIZE = 'XSMALL'
AUTO_SUSPEND = 60
AUTO_RESUME = TRUE;