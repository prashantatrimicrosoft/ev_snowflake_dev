WITH stg AS (
    SELECT * FROM {{ ref('stg_ev_registrations') }}
),

make_model AS (
    SELECT * FROM {{ source('bronze_master', 'MST_VEHICLE_MAKE_MODEL') }}
),

geography AS (
    SELECT * FROM {{ source('bronze_master', 'MST_GEOGRAPHY') }}
),

ev_type AS (
    SELECT * FROM {{ source('bronze_master', 'MST_EV_TYPE') }}
),

utility AS (
    SELECT * FROM {{ source('bronze_master', 'MST_ELECTRIC_UTILITY') }}
)

SELECT
    stg.DOL_VEHICLE_ID,
    stg.VIN_PARTIAL,
    stg.MAKE,
    stg.MODEL,
    stg.MODEL_YEAR,
    stg.EV_TYPE_FULL,
    stg.CAFV_ELIGIBILITY,
    stg.ELECTRIC_RANGE_MILES,
    stg.IS_RANGE_UNKNOWN,
    stg.BASE_MSRP_USD,
    stg.IS_MSRP_UNKNOWN,
    stg.COUNTY,
    stg.CITY,
    stg.STATE_CODE,
    stg.ZIP_CODE,
    stg.IS_WA_RECORD,
    stg.VEHICLE_LATITUDE,
    stg.VEHICLE_LONGITUDE,
    stg.LEGISLATIVE_DISTRICT,
    stg.ELECTRIC_UTILITY,
    stg.CENSUS_TRACT_2020,
    stg.SILVER_LOAD_TS,
    stg.BRONZE_ROW_HASH,
    stg.SOURCE_FILE,
    mm.MAKE_MODEL_ID,
    geo.GEO_ID,
    et.EV_TYPE_ID,
    ut.UTILITY_ID
FROM stg
LEFT JOIN make_model mm
    ON UPPER(stg.MAKE) = UPPER(mm.MAKE)
    AND UPPER(stg.MODEL) = UPPER(mm.MODEL)
LEFT JOIN geography geo
    ON stg.STATE_CODE = geo.STATE
    AND stg.COUNTY = geo.COUNTY
    AND stg.CITY = geo.CITY
    AND stg.ZIP_CODE = geo.ZIP_CODE
    AND COALESCE(stg.CENSUS_TRACT_2020, '') = COALESCE(geo.CENSUS_TRACT_2020, '')
LEFT JOIN ev_type et
    ON stg.EV_TYPE_FULL = et.EV_TYPE
    AND stg.CAFV_ELIGIBILITY = et.CAFV_ELIGIBILITY
LEFT JOIN utility ut
    ON stg.ELECTRIC_UTILITY = ut.UTILITY_NAME
