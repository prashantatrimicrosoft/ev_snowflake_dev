{{
    config(
        materialized='table'
    )
}}

WITH fact AS (
    SELECT * FROM {{ ref('fact_ev_registrations') }}
),

dim_v AS (
    SELECT * FROM {{ ref('dim_vehicle') }}
)

SELECT
    v.EV_TYPE_SHORT,
    v.EV_TYPE_FULL,
    v.CAFV_ELIGIBILITY,
    COUNT(*)                                                    AS REGISTRATIONS,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         AS PCT_OF_TOTAL,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY v.EV_TYPE_SHORT
    ), 2)                                                       AS PCT_WITHIN_EV_TYPE
FROM fact f
LEFT JOIN dim_v v ON f.VEHICLE_KEY = v.VEHICLE_KEY
GROUP BY v.EV_TYPE_SHORT, v.EV_TYPE_FULL, v.CAFV_ELIGIBILITY
