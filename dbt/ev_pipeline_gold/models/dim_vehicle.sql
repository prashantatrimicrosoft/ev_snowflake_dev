{{
    config(
        materialized='table'
    )
}}

WITH silver AS (
    SELECT DISTINCT
        MAKE,
        MODEL,
        EV_TYPE_FULL,
        CAFV_ELIGIBILITY
    FROM {{ source('silver', 'SILVER_EV_REGISTRATIONS') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY MAKE, MODEL, EV_TYPE_FULL) AS VEHICLE_KEY,
    MAKE,
    MODEL,
    EV_TYPE_FULL,
    CASE
        WHEN EV_TYPE_FULL LIKE 'Battery%' THEN 'BEV'
        ELSE 'PHEV'
    END                                                     AS EV_TYPE_SHORT,
    CAFV_ELIGIBILITY,
    CASE WHEN MAKE = 'TESLA' THEN TRUE ELSE FALSE END       AS IS_TESLA,
    CASE WHEN EV_TYPE_FULL LIKE 'Battery%' THEN TRUE ELSE FALSE END AS IS_BEV,
    CASE
        WHEN MAKE = 'TESLA' THEN 'Tesla'
        WHEN MAKE IN ('RIVIAN', 'LUCID', 'POLESTAR', 'FISKER') THEN 'EV Startup'
        ELSE 'Legacy OEM'
    END                                                     AS MAKE_TIER
FROM silver
