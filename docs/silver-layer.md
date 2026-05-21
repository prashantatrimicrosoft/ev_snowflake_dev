
---

# `docs/silver-layer.md`

```markdown id="e9x5di"
# Silver Layer

# Purpose

The Silver layer transforms raw semi-structured data into clean, validated, standardized datasets.

This layer handles:
- Cleansing
- Parsing
- Validation
- Deduplication
- Standardization
- Enrichment

---

# Transformation Strategy

The Silver layer primarily uses:
- dbt
- SQL transformations
- Stored procedures
- Snowpark considerations

---

# Why dbt?

dbt was selected because it provides:
- SQL-first workflows
- Dependency management
- Built-in testing
- DAG visibility
- Documentation generation

---

# Silver Layer Processing Steps

## 1. JSON Flattening

Raw VARIANT payloads are flattened into relational rows.

---

## 2. Type Casting

Data types standardized:
- Integer
- Timestamp
- String
- Boolean

---

## 3. Cleansing

Implemented:
- Null handling
- Standardization
- Duplicate removal

---

## 4. Enrichment

Derived fields added:
- Vehicle category
- MSRP tier
- Range category
- Geography enrichment

---

# Snowpark vs dbt Tradeoffs

## dbt Strengths

Best for:
- Standard SQL transformations
- Dimensional modeling
- Testing
- Governance

---

## Snowpark Strengths

Best for:
- Complex procedural logic
- Python-heavy parsing
- AI/ML enrichment
- Geospatial transformations

---

# Recommended Enterprise Pattern

```text
dbt
 ├── SQL transformations
 ├── Testing
 ├── Modeling
 └── Documentation

Snowpark
 ├── Complex parsing
 ├── Python enrichment
 ├── ML preprocessing
 └── Advanced business logic