USE ROLE SYSADMIN;
USE WAREHOUSE WH_INGEST;

-- ============================================================
-- MST_VEHICLE_MAKE_MODEL
-- ============================================================
CREATE OR REPLACE TABLE EV_BRONZE.RAW.MST_VEHICLE_MAKE_MODEL (
    MAKE_MODEL_ID   NUMBER AUTOINCREMENT START 1 INCREMENT 1 COMMENT 'Surrogate key',
    MAKE            VARCHAR(100) NOT NULL COMMENT 'Vehicle manufacturer name',
    MODEL           VARCHAR(100) NOT NULL COMMENT 'Vehicle model name',
    CREATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Record creation timestamp'
)
COMMENT = 'Master table of distinct vehicle make and model combinations from the WA EV Population dataset';

INSERT INTO EV_BRONZE.RAW.MST_VEHICLE_MAKE_MODEL (MAKE, MODEL)
SELECT DISTINCT
    f.VALUE[14]::STRING AS MAKE,
    f.VALUE[15]::STRING AS MODEL
FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
    LATERAL FLATTEN(INPUT => r.RAW_DATA:data) f
WHERE f.VALUE[14]::STRING IS NOT NULL
  AND f.VALUE[15]::STRING IS NOT NULL
ORDER BY MAKE, MODEL;

-- ============================================================
-- MST_GEOGRAPHY
-- ============================================================
CREATE OR REPLACE TABLE EV_BRONZE.RAW.MST_GEOGRAPHY (
    GEO_ID              NUMBER AUTOINCREMENT START 1 INCREMENT 1 COMMENT 'Surrogate key',
    STATE               VARCHAR(50) COMMENT 'US state abbreviation',
    COUNTY              VARCHAR(100) COMMENT 'County name',
    CITY                VARCHAR(100) COMMENT 'City name',
    ZIP_CODE            VARCHAR(10) COMMENT 'ZIP code',
    CENSUS_TRACT_2020   VARCHAR(20) COMMENT '2020 Census tract identifier',
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Record creation timestamp'
)
COMMENT = 'Master geography dimension table with location hierarchy from WA EV Population dataset';

INSERT INTO EV_BRONZE.RAW.MST_GEOGRAPHY (STATE, COUNTY, CITY, ZIP_CODE, CENSUS_TRACT_2020)
SELECT DISTINCT
    f.VALUE[11]::STRING AS STATE,
    f.VALUE[9]::STRING  AS COUNTY,
    f.VALUE[10]::STRING AS CITY,
    f.VALUE[12]::STRING AS ZIP_CODE,
    f.VALUE[24]::STRING AS CENSUS_TRACT_2020
FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
    LATERAL FLATTEN(INPUT => r.RAW_DATA:data) f
WHERE f.VALUE[12]::STRING IS NOT NULL
ORDER BY STATE, COUNTY, CITY, ZIP_CODE;

-- ============================================================
-- MST_EV_TYPE
-- ============================================================
CREATE OR REPLACE TABLE EV_BRONZE.RAW.MST_EV_TYPE (
    EV_TYPE_ID              NUMBER AUTOINCREMENT START 1 INCREMENT 1 COMMENT 'Surrogate key',
    EV_TYPE                 VARCHAR(100) NOT NULL COMMENT 'Electric vehicle type: BEV or PHEV',
    CAFV_ELIGIBILITY        VARCHAR(200) NOT NULL COMMENT 'Clean Alternative Fuel Vehicle eligibility status',
    CREATED_AT              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Record creation timestamp'
)
COMMENT = 'Master lookup for EV type and CAFV eligibility combinations from WA EV Population dataset';

INSERT INTO EV_BRONZE.RAW.MST_EV_TYPE (EV_TYPE, CAFV_ELIGIBILITY)
SELECT DISTINCT
    f.VALUE[16]::STRING AS EV_TYPE,
    f.VALUE[17]::STRING AS CAFV_ELIGIBILITY
FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
    LATERAL FLATTEN(INPUT => r.RAW_DATA:data) f
WHERE f.VALUE[16]::STRING IS NOT NULL
  AND f.VALUE[17]::STRING IS NOT NULL
ORDER BY EV_TYPE, CAFV_ELIGIBILITY;

-- ============================================================
-- MST_ELECTRIC_UTILITY
-- ============================================================
CREATE OR REPLACE TABLE EV_BRONZE.RAW.MST_ELECTRIC_UTILITY (
    UTILITY_ID      NUMBER AUTOINCREMENT START 1 INCREMENT 1 COMMENT 'Surrogate key',
    UTILITY_NAME    VARCHAR(200) NOT NULL COMMENT 'Electric utility provider name',
    CREATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Record creation timestamp'
)
COMMENT = 'Master table of distinct electric utility providers from WA EV Population dataset';

INSERT INTO EV_BRONZE.RAW.MST_ELECTRIC_UTILITY (UTILITY_NAME)
SELECT DISTINCT
    f.VALUE[23]::STRING AS UTILITY_NAME
FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
    LATERAL FLATTEN(INPUT => r.RAW_DATA:data) f
WHERE f.VALUE[23]::STRING IS NOT NULL
ORDER BY UTILITY_NAME;

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT 'MST_VEHICLE_MAKE_MODEL' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM EV_BRONZE.RAW.MST_VEHICLE_MAKE_MODEL
UNION ALL
SELECT 'MST_GEOGRAPHY', COUNT(*) FROM EV_BRONZE.RAW.MST_GEOGRAPHY
UNION ALL
SELECT 'MST_EV_TYPE', COUNT(*) FROM EV_BRONZE.RAW.MST_EV_TYPE
UNION ALL
SELECT 'MST_ELECTRIC_UTILITY', COUNT(*) FROM EV_BRONZE.RAW.MST_ELECTRIC_UTILITY;
