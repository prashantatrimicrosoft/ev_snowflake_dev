USE ROLE SYSADMIN;
USE WAREHOUSE WH_TRANSFORM;

CREATE OR REPLACE PROCEDURE EV_SILVER.CLEAN.SP_BRONZE_TO_SILVER_STAGE()
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_rows_inserted   NUMBER;
    v_rows_rejected   NUMBER;
    v_wa_records      NUMBER;
    v_non_wa_records  NUMBER;
    v_range_unknown   NUMBER;
    v_msrp_unknown    NUMBER;
    v_start_ts        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP();
BEGIN

    TRUNCATE TABLE EV_SILVER.CLEAN.EV_REGISTRATIONS_STAGE;
    TRUNCATE TABLE EV_SILVER.CLEAN.EV_REGISTRATIONS_REJECTED;

    INSERT INTO EV_SILVER.CLEAN.EV_REGISTRATIONS_STAGE (
        DOL_VEHICLE_ID,
        VIN_PARTIAL,
        MAKE,
        MODEL,
        MODEL_YEAR,
        EV_TYPE_FULL,
        CAFV_ELIGIBILITY,
        ELECTRIC_RANGE_MILES,
        IS_RANGE_UNKNOWN,
        BASE_MSRP_USD,
        IS_MSRP_UNKNOWN,
        COUNTY,
        CITY,
        STATE_CODE,
        ZIP_CODE,
        IS_WA_RECORD,
        VEHICLE_LATITUDE,
        VEHICLE_LONGITUDE,
        LEGISLATIVE_DISTRICT,
        ELECTRIC_UTILITY,
        CENSUS_TRACT_2020,
        SILVER_LOAD_TS,
        BRONZE_ROW_HASH,
        SOURCE_FILE
    )
    WITH flattened AS (
        SELECT
            f.VALUE[21]::STRING                                                         AS DOL_VEHICLE_ID,
            TRIM(UPPER(f.VALUE[8]::STRING))                                             AS VIN_PARTIAL,
            COALESCE(TRIM(UPPER(f.VALUE[14]::STRING)), 'UNKNOWN')                       AS MAKE,
            COALESCE(NULLIF(NULLIF(TRIM(UPPER(f.VALUE[15]::STRING)),'NONE'),''), 'UNKNOWN') AS MODEL,
            TRY_CAST(f.VALUE[13]::STRING AS INTEGER)                                    AS MODEL_YEAR,
            f.VALUE[16]::STRING                                                         AS EV_TYPE_FULL,
            f.VALUE[17]::STRING                                                         AS CAFV_ELIGIBILITY,
            TRY_CAST(f.VALUE[18]::STRING AS INTEGER)                                    AS ELECTRIC_RANGE_MILES,
            CASE WHEN TRY_CAST(f.VALUE[18]::STRING AS INTEGER) IS NULL
                  OR  TRY_CAST(f.VALUE[18]::STRING AS INTEGER) = 0 THEN TRUE ELSE FALSE END AS IS_RANGE_UNKNOWN,
            TRY_CAST(f.VALUE[19]::STRING AS FLOAT)                                      AS BASE_MSRP_USD,
            CASE WHEN TRY_CAST(f.VALUE[19]::STRING AS FLOAT) IS NULL
                  OR  TRY_CAST(f.VALUE[19]::STRING AS FLOAT) = 0 THEN TRUE ELSE FALSE END AS IS_MSRP_UNKNOWN,
            NULLIF(TRIM(INITCAP(f.VALUE[9]::STRING)),'None')                            AS COUNTY,
            TRIM(INITCAP(f.VALUE[10]::STRING))                                          AS CITY,
            TRIM(UPPER(f.VALUE[11]::STRING))                                            AS STATE_CODE,
            TRIM(f.VALUE[12]::STRING)                                                   AS ZIP_CODE,
            CASE WHEN TRIM(UPPER(f.VALUE[11]::STRING)) = 'WA' THEN TRUE ELSE FALSE END AS IS_WA_RECORD,
            TRY_CAST(SPLIT_PART(
                REGEXP_REPLACE(NULLIF(f.VALUE[22]::STRING,'None'), 'POINT \\(|\\)', ''),
                ' ', 2) AS FLOAT)                                                       AS VEHICLE_LATITUDE,
            TRY_CAST(SPLIT_PART(
                REGEXP_REPLACE(NULLIF(f.VALUE[22]::STRING,'None'), 'POINT \\(|\\)', ''),
                ' ', 1) AS FLOAT)                                                       AS VEHICLE_LONGITUDE,
            TRY_CAST(f.VALUE[20]::STRING AS INTEGER)                                    AS LEGISLATIVE_DISTRICT,
            NULLIF(NULLIF(TRIM(f.VALUE[23]::STRING),'None'),'')                         AS ELECTRIC_UTILITY,
            NULLIF(TRIM(f.VALUE[24]::STRING),'None')                                    AS CENSUS_TRACT_2020,
            SHA2(CONCAT_WS('|',
                NVL(f.VALUE[21]::STRING,''),
                NVL(f.VALUE[8]::STRING,''),
                NVL(f.VALUE[14]::STRING,''),
                NVL(f.VALUE[15]::STRING,''),
                NVL(f.VALUE[13]::STRING,''),
                NVL(f.VALUE[16]::STRING,''),
                NVL(f.VALUE[18]::STRING,''),
                NVL(f.VALUE[12]::STRING,'')
            ), 256)                                                                     AS BRONZE_ROW_HASH,
            r.FILE_NAME                                                                 AS SOURCE_FILE,
            ROW_NUMBER() OVER (PARTITION BY f.VALUE[21]::STRING ORDER BY f.INDEX)       AS RN
        FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
            LATERAL FLATTEN(INPUT => r.RAW_DATA:data) f
    )
    SELECT
        DOL_VEHICLE_ID,
        VIN_PARTIAL,
        MAKE,
        MODEL,
        MODEL_YEAR,
        EV_TYPE_FULL,
        CAFV_ELIGIBILITY,
        ELECTRIC_RANGE_MILES,
        IS_RANGE_UNKNOWN,
        BASE_MSRP_USD,
        IS_MSRP_UNKNOWN,
        COUNTY,
        CITY,
        STATE_CODE,
        ZIP_CODE,
        IS_WA_RECORD,
        VEHICLE_LATITUDE,
        VEHICLE_LONGITUDE,
        LEGISLATIVE_DISTRICT,
        ELECTRIC_UTILITY,
        CENSUS_TRACT_2020,
        CURRENT_TIMESTAMP(),
        BRONZE_ROW_HASH,
        SOURCE_FILE
    FROM flattened
    WHERE RN = 1
      AND DOL_VEHICLE_ID IS NOT NULL
      AND VIN_PARTIAL IS NOT NULL
      AND EV_TYPE_FULL IS NOT NULL;

    v_rows_inserted := SQLROWCOUNT;

    INSERT INTO EV_SILVER.CLEAN.EV_REGISTRATIONS_REJECTED (
        DOL_VEHICLE_ID,
        RAW_RECORD,
        REJECTION_REASON,
        REJECTED_AT
    )
    SELECT
        f.VALUE[21]::STRING,
        f.VALUE,
        CASE
            WHEN f.VALUE[21]::STRING IS NULL THEN 'NULL DOL_VEHICLE_ID'
            WHEN TRIM(UPPER(f.VALUE[8]::STRING)) IS NULL THEN 'NULL VIN'
            WHEN f.VALUE[16]::STRING IS NULL THEN 'NULL EV_TYPE'
            ELSE 'UNKNOWN'
        END,
        CURRENT_TIMESTAMP()
    FROM EV_BRONZE.RAW.EV_POPULATION_RAW r,
        LATERAL FLATTEN(INPUT => r.RAW_DATA:data) f
    WHERE f.VALUE[21]::STRING IS NULL
       OR TRIM(UPPER(f.VALUE[8]::STRING)) IS NULL
       OR f.VALUE[16]::STRING IS NULL;

    v_rows_rejected := SQLROWCOUNT;

    SELECT
        SUM(CASE WHEN IS_WA_RECORD THEN 1 ELSE 0 END),
        SUM(CASE WHEN NOT IS_WA_RECORD THEN 1 ELSE 0 END),
        SUM(CASE WHEN IS_RANGE_UNKNOWN THEN 1 ELSE 0 END),
        SUM(CASE WHEN IS_MSRP_UNKNOWN THEN 1 ELSE 0 END)
    INTO v_wa_records, v_non_wa_records, v_range_unknown, v_msrp_unknown
    FROM EV_SILVER.CLEAN.EV_REGISTRATIONS_STAGE;

    RETURN OBJECT_CONSTRUCT(
        'status',           'SUCCESS',
        'rows_inserted',    v_rows_inserted,
        'rows_rejected',    v_rows_rejected,
        'wa_records',       v_wa_records,
        'non_wa_records',   v_non_wa_records,
        'range_unknown',    v_range_unknown,
        'msrp_unknown',     v_msrp_unknown,
        'started_at',       v_start_ts,
        'completed_at',     CURRENT_TIMESTAMP()
    );
END;
$$;
