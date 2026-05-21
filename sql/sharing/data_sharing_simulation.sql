USE ROLE ACCOUNTADMIN;

-- ============================================================
-- END-TO-END DATA SHARING SIMULATION
-- Provider: BMR*****.CKB***** (Trial Account)
-- Consumer: BMR*****.EV_************* (Reader Account - XTB*****)
-- ============================================================

-- ============================================================
-- STEP 1: Create Reader Account (simulates external consumer)
-- ============================================================
CREATE MANAGED ACCOUNT EV_CONSUMER_ACCT
  ADMIN_NAME = 'ev_admin',
  ADMIN_PASSWORD = '********',  -- Replace with secure password
  TYPE = READER
  COMMENT = 'Reader account simulating data share consumer';

-- Verify reader account
SHOW MANAGED ACCOUNTS;

-- ============================================================
-- STEP 2: Create SHARE object (provider publishes Gold data)
-- ============================================================
CREATE OR REPLACE SHARE EV_GOLD_SHARE
  COMMENT = 'EV Analytics Gold layer — shared with consumer for dashboards and analytics';

-- Grant database and schema usage
GRANT USAGE ON DATABASE EV_GOLD TO SHARE EV_GOLD_SHARE;
GRANT USAGE ON SCHEMA EV_GOLD.SERVING TO SHARE EV_GOLD_SHARE;

-- Grant SELECT on 7 Gold tables
GRANT SELECT ON TABLE EV_GOLD.SERVING.FACT_EV_REGISTRATIONS TO SHARE EV_GOLD_SHARE;
GRANT SELECT ON TABLE EV_GOLD.SERVING.DIM_VEHICLE TO SHARE EV_GOLD_SHARE;
GRANT SELECT ON TABLE EV_GOLD.SERVING.DIM_GEOGRAPHY TO SHARE EV_GOLD_SHARE;
GRANT SELECT ON TABLE EV_GOLD.SERVING.DIM_DATE TO SHARE EV_GOLD_SHARE;
GRANT SELECT ON TABLE EV_GOLD.SERVING.AGG_YOY_GROWTH TO SHARE EV_GOLD_SHARE;
GRANT SELECT ON TABLE EV_GOLD.SERVING.AGG_REGIONAL_ADOPTION TO SHARE EV_GOLD_SHARE;
GRANT SELECT ON TABLE EV_GOLD.SERVING.AGG_MARKET_SHARE TO SHARE EV_GOLD_SHARE;

-- ============================================================
-- STEP 3: Add reader account to share
-- ============================================================
ALTER SHARE EV_GOLD_SHARE ADD ACCOUNTS = BMR*****.EV_*************;

-- Verify share configuration
SHOW GRANTS TO SHARE EV_GOLD_SHARE;
SHOW SHARES LIKE 'EV_GOLD_SHARE';

-- ============================================================
-- STEP 4: Consumer-side setup (run in READER ACCOUNT)
-- Login: https://bmr*****-ev_*************.snowflakecomputing.com
-- User: ev_admin | Password: (set during creation)
-- ============================================================

-- 4a. Create warehouse for consumer compute
-- CREATE WAREHOUSE WH_CONSUMER
--   WAREHOUSE_SIZE = 'XSMALL'
--   AUTO_SUSPEND = 60
--   AUTO_RESUME = TRUE;
-- USE WAREHOUSE WH_CONSUMER;

-- 4b. Create database from share
-- CREATE DATABASE EV_SHARED_DATA FROM SHARE BMR*****.CKB*****.EV_GOLD_SHARE;

-- ============================================================
-- STEP 5: Consumer validation queries (run in READER ACCOUNT)
-- ============================================================

-- 5a. Verify tables are visible
-- SHOW TABLES IN DATABASE EV_SHARED_DATA;

-- 5b. Count total vehicles (should = 22,193)
-- SELECT COUNT(*) AS TOTAL_VEHICLES FROM EV_SHARED_DATA.SERVING.FACT_EV_REGISTRATIONS;

-- 5c. YoY growth trend (executive dashboard query)
-- SELECT MODEL_YEAR, EV_TYPE_SHORT, REGISTRATIONS, YOY_GROWTH_PCT
-- FROM EV_SHARED_DATA.SERVING.AGG_YOY_GROWTH
-- WHERE MODEL_YEAR >= 2020
-- ORDER BY MODEL_YEAR, EV_TYPE_SHORT;

-- 5d. Top manufacturers by market share
-- SELECT MAKE, SUM(REGISTRATIONS) AS TOTAL, ROUND(AVG(MARKET_SHARE_PCT),2) AS SHARE_PCT
-- FROM EV_SHARED_DATA.SERVING.AGG_MARKET_SHARE
-- WHERE STATE_CODE = 'WA'
-- GROUP BY MAKE
-- ORDER BY TOTAL DESC
-- LIMIT 5;

-- 5e. Regional adoption (top counties)
-- SELECT COUNTY, REGION_GROUP, SUM(REGISTRATIONS) AS EVS
-- FROM EV_SHARED_DATA.SERVING.AGG_REGIONAL_ADOPTION
-- GROUP BY COUNTY, REGION_GROUP
-- ORDER BY EVS DESC
-- LIMIT 10;

-- 5f. Verify READ-ONLY enforcement (MUST FAIL)
-- INSERT INTO EV_SHARED_DATA.SERVING.FACT_EV_REGISTRATIONS (DOL_VEHICLE_ID) VALUES ('TEST');
-- Expected error: Cannot perform INSERT on a shared database

-- ============================================================
-- STEP 6: Live sync test (run in PROVIDER account)
-- After running pipeline, consumer sees updated data instantly
-- ============================================================

-- Provider: run pipeline to update Gold
-- EXECUTE TASK EV_SILVER.CLEAN.TSK_1_BRONZE_TO_SILVER_STAGE;

-- Consumer: re-query to see live changes (no ETL needed)
-- SELECT COUNT(*) FROM EV_SHARED_DATA.SERVING.FACT_EV_REGISTRATIONS;

-- ============================================================
-- ARCHITECTURE
-- ============================================================
--
-- ┌──────────────────────────────────┐       ┌──────────────────────────────────┐
-- │     PROVIDER ACCOUNT             │       │     READER ACCOUNT               │
-- │     (BMR*****.CKB*****)          │       │     (BMR*****.EV_*************)   │
-- │                                  │       │     (XTB*****)                   │
-- │  Role: ACCOUNTADMIN              │       │  Role: ACCOUNTADMIN              │
-- │  Warehouse: WH_TRANSFORM         │       │  Warehouse: WH_CONSUMER          │
-- │  User: PRA****                   │       │  User: ev_***in                  │
-- │                                  │       │                                  │
-- │  ┌────────────────────────┐      │ SHARE │  ┌────────────────────────┐      │
-- │  │  EV_GOLD.SERVING       │      │(zero- │  │  EV_SHARED_DATA        │      │
-- │  │                        │──────┼─copy)─┼─►│  .SERVING              │      │
-- │  │  7 tables (fact/dim/agg)│      │       │  │  7 tables (read-only)  │      │
-- │  └────────────────────────┘      │       │  └────────────────────────┘      │
-- │                                  │       │                                  │
-- │  Pays: storage + compute         │       │  Pays: WH_CONSUMER compute only  │
-- │  Controls: access, revocation    │       │  Gets: $0 storage, live data     │
-- └──────────────────────────────────┘       └──────────────────────────────────┘
--
-- ============================================================
-- CLEANUP (if needed)
-- ============================================================
-- DROP SHARE EV_GOLD_SHARE;
-- DROP MANAGED ACCOUNT EV_CONSUMER_ACCT;
