USE ROLE ACCOUNTADMIN;

-- ============================================================
-- DATA CLEAN ROOM SIMULATION
-- Use Case: EV Market Overlap Analysis
-- Provider: EV registration data (22,193 vehicles)
-- Partner: Tesla VIN list (5,000 vehicles from campaign)
-- Output: Aggregate overlap stats only — no raw data exposed
-- ============================================================

-- ============================================================
-- STEP 1: Infrastructure
-- ============================================================
CREATE DATABASE IF NOT EXISTS EV_CLEANROOM
  COMMENT = 'Data Clean Room for secure multi-party analytics without raw data exposure';

CREATE SCHEMA IF NOT EXISTS EV_CLEANROOM.PARTNER
  COMMENT = 'Partner-contributed data — restricted access';

CREATE SCHEMA IF NOT EXISTS EV_CLEANROOM.ANALYSIS
  COMMENT = 'Clean room functions — returns aggregates only';

-- ============================================================
-- STEP 2: Partner data (simulated Tesla VIN list)
-- ============================================================
CREATE OR REPLACE TABLE EV_CLEANROOM.PARTNER.PARTNER_VEHICLE_LIST (
    VIN_PARTIAL     VARCHAR(10)   NOT NULL,
    CAMPAIGN_ID     VARCHAR(50),
    PARTNER_MAKE    VARCHAR(50)
)
COMMENT = 'Simulated partner (Tesla) VIN list — represents data partner brings to the clean room';

INSERT INTO EV_CLEANROOM.PARTNER.PARTNER_VEHICLE_LIST (VIN_PARTIAL, CAMPAIGN_ID, PARTNER_MAKE)
SELECT VIN_PARTIAL, 'CAMPAIGN_2024_Q1', 'TESLA'
FROM EV_SILVER.CLEAN.EV_REGISTRATIONS_STAGE
WHERE MAKE = 'TESLA'
ORDER BY RANDOM()
LIMIT 5000;

-- ============================================================
-- STEP 3: Secure functions (aggregate-only output)
-- ============================================================

-- Function 1: Total overlap count
CREATE OR REPLACE SECURE FUNCTION EV_CLEANROOM.ANALYSIS.OVERLAP_COUNT()
RETURNS TABLE (OVERLAP_VEHICLES INT, PARTNER_TOTAL INT, PROVIDER_TOTAL INT, OVERLAP_PCT FLOAT)
AS
$$
    SELECT
        COUNT(DISTINCT p.VIN_PARTIAL) AS OVERLAP_VEHICLES,
        (SELECT COUNT(*) FROM EV_CLEANROOM.PARTNER.PARTNER_VEHICLE_LIST) AS PARTNER_TOTAL,
        (SELECT COUNT(*) FROM EV_GOLD.SERVING.FACT_EV_REGISTRATIONS) AS PROVIDER_TOTAL,
        ROUND(COUNT(DISTINCT p.VIN_PARTIAL) * 100.0 /
          (SELECT COUNT(*) FROM EV_CLEANROOM.PARTNER.PARTNER_VEHICLE_LIST), 2) AS OVERLAP_PCT
    FROM EV_CLEANROOM.PARTNER.PARTNER_VEHICLE_LIST p
    INNER JOIN EV_SILVER.CLEAN.EV_REGISTRATIONS_STAGE s
      ON p.VIN_PARTIAL = s.VIN_PARTIAL
$$;

-- Function 2: Overlap by county (k-anonymity: min group size = 5)
CREATE OR REPLACE SECURE FUNCTION EV_CLEANROOM.ANALYSIS.OVERLAP_BY_COUNTY()
RETURNS TABLE (COUNTY VARCHAR, REGION_GROUP VARCHAR, OVERLAP_COUNT INT, PCT_OF_OVERLAP FLOAT)
AS
$$
    SELECT
        s.COUNTY,
        g.REGION_GROUP,
        COUNT(*) AS OVERLAP_COUNT,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS PCT_OF_OVERLAP
    FROM EV_CLEANROOM.PARTNER.PARTNER_VEHICLE_LIST p
    INNER JOIN EV_SILVER.CLEAN.EV_REGISTRATIONS_STAGE s
      ON p.VIN_PARTIAL = s.VIN_PARTIAL
    LEFT JOIN EV_GOLD.SERVING.DIM_GEOGRAPHY g
      ON s.STATE_CODE = g.STATE_CODE AND s.COUNTY = g.COUNTY
    GROUP BY s.COUNTY, g.REGION_GROUP
    HAVING COUNT(*) >= 5
    ORDER BY OVERLAP_COUNT DESC
$$;

-- Function 3: Overlap by model year (k-anonymity: min group size = 5)
CREATE OR REPLACE SECURE FUNCTION EV_CLEANROOM.ANALYSIS.OVERLAP_BY_YEAR()
RETURNS TABLE (MODEL_YEAR INT, MODEL VARCHAR, OVERLAP_COUNT INT, PCT_OF_OVERLAP FLOAT)
AS
$$
    SELECT
        s.MODEL_YEAR,
        s.MODEL,
        COUNT(*) AS OVERLAP_COUNT,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS PCT_OF_OVERLAP
    FROM EV_CLEANROOM.PARTNER.PARTNER_VEHICLE_LIST p
    INNER JOIN EV_SILVER.CLEAN.EV_REGISTRATIONS_STAGE s
      ON p.VIN_PARTIAL = s.VIN_PARTIAL
    GROUP BY s.MODEL_YEAR, s.MODEL
    HAVING COUNT(*) >= 5
    ORDER BY s.MODEL_YEAR DESC, OVERLAP_COUNT DESC
$$;

-- ============================================================
-- STEP 4: Restricted role and user
-- ============================================================
CREATE ROLE IF NOT EXISTS CLEANROOM_ANALYST
  COMMENT = 'Restricted role — can only call clean room aggregate functions, no raw data access';

CREATE USER IF NOT EXISTS CLEANROOM_USER
  PASSWORD = '********'
  DEFAULT_WAREHOUSE = WH_CONSUMER
  DEFAULT_ROLE = CLEANROOM_ANALYST
  DEFAULT_SECONDARY_ROLES = ()
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Simulated partner analyst for data clean room testing';

GRANT ROLE CLEANROOM_ANALYST TO USER CLEANROOM_USER;
GRANT USAGE ON WAREHOUSE WH_CONSUMER TO ROLE CLEANROOM_ANALYST;
GRANT USAGE ON DATABASE EV_CLEANROOM TO ROLE CLEANROOM_ANALYST;
GRANT USAGE ON SCHEMA EV_CLEANROOM.ANALYSIS TO ROLE CLEANROOM_ANALYST;
GRANT USAGE ON ALL FUNCTIONS IN SCHEMA EV_CLEANROOM.ANALYSIS TO ROLE CLEANROOM_ANALYST;

-- NOTE: NO grants on EV_CLEANROOM.PARTNER or EV_GOLD — analyst cannot see raw data

-- ============================================================
-- STEP 5: Validation (run as CLEANROOM_ANALYST)
-- ============================================================

-- USE ROLE CLEANROOM_ANALYST;
-- USE SECONDARY ROLES NONE;
-- USE WAREHOUSE WH_CONSUMER;

-- Should PASS (aggregates only):
-- SELECT * FROM TABLE(EV_CLEANROOM.ANALYSIS.OVERLAP_COUNT());
-- SELECT * FROM TABLE(EV_CLEANROOM.ANALYSIS.OVERLAP_BY_COUNTY());
-- SELECT * FROM TABLE(EV_CLEANROOM.ANALYSIS.OVERLAP_BY_YEAR());

-- Should FAIL (raw data blocked):
-- SELECT * FROM EV_CLEANROOM.PARTNER.PARTNER_VEHICLE_LIST;
-- SELECT * FROM EV_GOLD.SERVING.FACT_EV_REGISTRATIONS LIMIT 5;

-- ============================================================
-- CLEAN ROOM RULES ENFORCED
-- ============================================================
-- 1. No raw VINs exposed — functions return aggregates only
-- 2. K-anonymity (min group >= 5) — small groups suppressed
-- 3. Partner data hidden — analyst has no PARTNER schema access
-- 4. Provider data hidden — analyst has no EV_GOLD access
-- 5. Audit trail — all queries logged in QUERY_HISTORY
-- ============================================================
