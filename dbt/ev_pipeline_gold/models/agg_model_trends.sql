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
    v.MAKE,
    v.MODEL,
    v.EV_TYPE_SHORT,
    v.MAKE_TIER,
    f.DATE_KEY                                                      AS MODEL_YEAR,
    COUNT(*)                                                        AS REGISTRATIONS,
    LAG(COUNT(*)) OVER (
        PARTITION BY v.MAKE, v.MODEL, v.EV_TYPE_SHORT
        ORDER BY f.DATE_KEY
    )                                                               AS PREV_YEAR_REGISTRATIONS,
    CASE
        WHEN LAG(COUNT(*)) OVER (
            PARTITION BY v.MAKE, v.MODEL, v.EV_TYPE_SHORT
            ORDER BY f.DATE_KEY
        ) > 0
        THEN ROUND(
            (COUNT(*) - LAG(COUNT(*)) OVER (
                PARTITION BY v.MAKE, v.MODEL, v.EV_TYPE_SHORT
                ORDER BY f.DATE_KEY
            )) * 100.0
            / LAG(COUNT(*)) OVER (
                PARTITION BY v.MAKE, v.MODEL, v.EV_TYPE_SHORT
                ORDER BY f.DATE_KEY
            ), 2)
        ELSE NULL
    END                                                             AS YOY_MOMENTUM_PCT,
    RANK() OVER (PARTITION BY f.DATE_KEY ORDER BY COUNT(*) DESC)    AS RANK_IN_YEAR
FROM fact f
LEFT JOIN dim_v v ON f.VEHICLE_KEY = v.VEHICLE_KEY
GROUP BY v.MAKE, v.MODEL, v.EV_TYPE_SHORT, v.MAKE_TIER, f.DATE_KEY
