{{
    config(
        materialized='table'
    )
}}

WITH silver AS (
    SELECT DISTINCT
        STATE_CODE,
        COUNTY,
        CITY,
        ZIP_CODE,
        CENSUS_TRACT_2020
    FROM {{ source('silver', 'SILVER_EV_REGISTRATIONS') }}
    WHERE ZIP_CODE IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY STATE_CODE, COUNTY, CITY, ZIP_CODE) AS GEO_KEY,
    STATE_CODE,
    COUNTY,
    CITY,
    ZIP_CODE,
    CENSUS_TRACT_2020,
    CASE
        WHEN STATE_CODE != 'WA' THEN 'Out-of-State'
        WHEN COUNTY IN ('King', 'Pierce', 'Snohomish', 'Kitsap', 'Thurston', 'Clark') THEN 'Western WA (Metro)'
        WHEN COUNTY IN ('Spokane', 'Yakima', 'Benton', 'Franklin') THEN 'Eastern WA'
        ELSE 'Western WA (Other)'
    END                                                             AS REGION_GROUP
FROM silver
