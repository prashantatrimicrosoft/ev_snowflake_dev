USE ROLE SYSADMIN;
USE WAREHOUSE WH_INGEST;

-- CHECK 1: Confirm exactly 1 row loaded (the whole JSON = 1 VARIANT row)
SELECT
    'CHECK 1: Row count = 1'           AS CHECK_NAME,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END AS STATUS,
    COUNT(*)::STRING                   AS ACTUAL_VALUE,
    '1'                                AS EXPECTED_VALUE
FROM EV_BRONZE.RAW.EV_POPULATION_RAW

UNION ALL

-- CHECK 2: Confirm RAW_DATA is not NULL
SELECT
    'CHECK 2: RAW_DATA not NULL',
    CASE WHEN COUNT_IF(RAW_DATA IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END,
    COUNT_IF(RAW_DATA IS NULL)::STRING,
    '0'
FROM EV_BRONZE.RAW.EV_POPULATION_RAW

UNION ALL

-- CHECK 3: Confirm ARRAY_SIZE(RAW_DATA:data) = 22183 records
SELECT
    'CHECK 3: Data array = 22183',
    CASE WHEN MAX(ARRAY_SIZE(RAW_DATA:data)) = 22183 THEN 'PASS' ELSE 'FAIL' END,
    MAX(ARRAY_SIZE(RAW_DATA:data))::STRING,
    '22183'
FROM EV_BRONZE.RAW.EV_POPULATION_RAW

UNION ALL

-- CHECK 4: Confirm meta.view.columns array exists and has 28 entries
SELECT
    'CHECK 4: Meta columns = 28',
    CASE WHEN MAX(ARRAY_SIZE(RAW_DATA:meta:view:columns)) = 28 THEN 'PASS' ELSE 'FAIL' END,
    MAX(ARRAY_SIZE(RAW_DATA:meta:view:columns))::STRING,
    '28'
FROM EV_BRONZE.RAW.EV_POPULATION_RAW

UNION ALL

-- CHECK 5: Confirm the dataset name is 'Electric Vehicle Population Data'
SELECT
    'CHECK 5: Dataset name match',
    CASE WHEN MAX(RAW_DATA:meta:view:name::STRING) = 'Electric Vehicle Population Data' THEN 'PASS' ELSE 'FAIL' END,
    MAX(RAW_DATA:meta:view:name::STRING),
    'Electric Vehicle Population Data'
FROM EV_BRONZE.RAW.EV_POPULATION_RAW

UNION ALL

-- CHECK 6: Confirm load happened within the last 24 hours
SELECT
    'CHECK 6: Load within 24hrs',
    CASE WHEN MAX(LOAD_TIMESTAMP) >= DATEADD('hour', -24, CURRENT_TIMESTAMP()) THEN 'PASS' ELSE 'FAIL' END,
    MAX(LOAD_TIMESTAMP)::STRING,
    'Within last 24 hours'
FROM EV_BRONZE.RAW.EV_POPULATION_RAW;
