{{
    config(
        materialized='table'
    )
}}

WITH silver AS (
    SELECT * FROM {{ source('silver', 'SILVER_EV_REGISTRATIONS') }}
),

dim_v AS (
    SELECT * FROM {{ ref('dim_vehicle') }}
),

dim_g AS (
    SELECT * FROM {{ ref('dim_geography') }}
),

dim_u AS (
    SELECT * FROM {{ ref('dim_utility') }}
)

SELECT
    s.DOL_VEHICLE_ID,
    s.VIN_PARTIAL,
    s.MODEL_YEAR                    AS DATE_KEY,
    v.VEHICLE_KEY,
    g.GEO_KEY,
    u.UTILITY_KEY,
    s.ELECTRIC_RANGE_MILES,
    s.IS_RANGE_UNKNOWN,
    s.BASE_MSRP_USD,
    s.IS_MSRP_UNKNOWN,
    s.IS_WA_RECORD,
    s.VEHICLE_LATITUDE,
    s.VEHICLE_LONGITUDE,
    s.LEGISLATIVE_DISTRICT,
    s.BRONZE_ROW_HASH,
    s.SOURCE_FILE,
    s.SILVER_LOAD_TS,
    CURRENT_TIMESTAMP()             AS GOLD_LOADED_AT
FROM silver s
LEFT JOIN dim_v v
    ON s.MAKE = v.MAKE
    AND s.MODEL = v.MODEL
    AND s.EV_TYPE_FULL = v.EV_TYPE_FULL
    AND s.CAFV_ELIGIBILITY = v.CAFV_ELIGIBILITY
LEFT JOIN dim_g g
    ON s.STATE_CODE = g.STATE_CODE
    AND s.COUNTY = g.COUNTY
    AND s.CITY = g.CITY
    AND s.ZIP_CODE = g.ZIP_CODE
    AND COALESCE(s.CENSUS_TRACT_2020, '') = COALESCE(g.CENSUS_TRACT_2020, '')
LEFT JOIN dim_u u
    ON s.ELECTRIC_UTILITY = u.UTILITY_NAME
