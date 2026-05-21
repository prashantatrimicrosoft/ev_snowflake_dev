USE ROLE SYSADMIN;
USE WAREHOUSE WH_INGEST;

-- 1. Column definitions from meta:view:columns
SELECT
    f.INDEX                                AS COL_POSITION,
    f.VALUE:fieldName::STRING              AS FIELD_NAME,
    f.VALUE:dataTypeName::STRING           AS DATA_TYPE_NAME
FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
    LATERAL FLATTEN(INPUT => r.RAW_DATA:meta:view:columns) f
ORDER BY f.INDEX;

-- 2. First 3 data rows (raw arrays)
SELECT
    f.INDEX                                AS ROW_INDEX,
    f.VALUE                                AS RAW_ROW
FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
    LATERAL FLATTEN(INPUT => r.RAW_DATA:data) f
WHERE f.INDEX < 3
ORDER BY f.INDEX;

-- 3. Extract specific fields from row 0 by array position
SELECT
    f.VALUE[8]::STRING                     AS VIN_1_10,
    f.VALUE[14]::STRING                    AS MAKE,
    f.VALUE[16]::STRING                    AS EV_TYPE,
    f.VALUE[18]::STRING                    AS ELECTRIC_RANGE,
    f.VALUE[21]::STRING                    AS DOL_VEHICLE_ID
FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
    LATERAL FLATTEN(INPUT => r.RAW_DATA:data) f
WHERE f.INDEX = 0;
