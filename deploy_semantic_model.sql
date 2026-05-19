-- ============================================================
-- STEP 1.6a: Upload Semantic Model to Stage
-- ============================================================
USE ROLE SYSADMIN;
USE WAREHOUSE WH_TRANSFORM;
USE DATABASE EV_GOLD;
USE SCHEMA SERVING;

CREATE STAGE IF NOT EXISTS EV_GOLD.SERVING.STG_SEMANTIC_MODELS
    COMMENT = 'Cortex Analyst semantic model YAML files for EV pipeline';

-- Upload from workspace to stage
COPY FILES INTO @EV_GOLD.SERVING.STG_SEMANTIC_MODELS
  FROM 'snow://workspace/USER$.PUBLIC.DEFAULT$/versions/live'
  FILES = ('ev_gold_semantic.yaml');

-- Verify upload
LIST @EV_GOLD.SERVING.STG_SEMANTIC_MODELS;

-- ============================================================
-- STEP 1.7: Validate Semantic Model (no Cortex AI needed)
-- ============================================================
-- Run each VQR directly to confirm data correctness:

-- VQR1: YoY growth trend
SELECT MODEL_YEAR, EV_TYPE_SHORT, REGISTRATIONS AS REGISTRATION_COUNT,
       YOY_GROWTH_PCT, CUMULATIVE_REGISTRATIONS, PCT_OF_YEAR_TOTAL
FROM EV_GOLD.SERVING.AGG_YOY_GROWTH
ORDER BY MODEL_YEAR, EV_TYPE_SHORT;

-- VQR2: Regional adoption (top 10 counties)
SELECT COUNTY, REGION_GROUP,
       SUM(REGISTRATIONS) AS TOTAL_EVS,
       ROUND(100.0 * SUM(REGISTRATIONS) / 22120, 2) AS WA_SHARE_PCT
FROM EV_GOLD.SERVING.AGG_REGIONAL_ADOPTION
GROUP BY COUNTY, REGION_GROUP
ORDER BY TOTAL_EVS DESC
LIMIT 10;

-- VQR3: BEV vs PHEV market penetration
SELECT EV_TYPE_SHORT,
       SUM(REGISTRATIONS) AS TOTAL,
       ROUND(100.0 * SUM(REGISTRATIONS) / 22183, 2) AS MARKET_SHARE_PCT
FROM EV_GOLD.SERVING.AGG_MARKET_SHARE
GROUP BY EV_TYPE_SHORT
ORDER BY TOTAL DESC;

-- VQR5: CAFV eligibility
SELECT EV_TYPE_SHORT, CAFV_ELIGIBILITY,
       REGISTRATIONS AS VEHICLE_COUNT,
       PCT_OF_TOTAL AS ELIGIBILITY_PCT
FROM EV_GOLD.SERVING.AGG_CAFV_ELIGIBILITY
ORDER BY REGISTRATIONS DESC;


-- NOTE: Cortex Analyst is accessed via REST API or Streamlit _snowflake module.
-- There is no SQL UDF for it. Use the Streamlit chat app (next step) to test interactively.
-- ============================================================
-- STEP 1.6b (ALTERNATIVE): Create Semantic View
-- ============================================================
-- Instead of stage-based YAML, register as a native Snowflake semantic view:
--
-- CREATE OR REPLACE SEMANTIC VIEW EV_GOLD.SERVING.EV_ANALYTICS_SEMANTIC
--   FROM @EV_GOLD.SERVING.STG_SEMANTIC_MODELS/ev_gold_semantic.yaml;
--
-- Then reference in Cortex Analyst as:
--   semantic_view: 'EV_GOLD.SERVING.EV_ANALYTICS_SEMANTIC'
-- ============================================================
