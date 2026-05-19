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
    f.DATE_KEY                                          AS MODEL_YEAR,
    v.EV_TYPE_SHORT,
    COUNT(*)                                            AS REGISTRATIONS,
    SUM(COUNT(*)) OVER (
        PARTITION BY v.EV_TYPE_SHORT
        ORDER BY f.DATE_KEY
    )                                                   AS CUMULATIVE_REGISTRATIONS,
    LAG(COUNT(*)) OVER (
        PARTITION BY v.EV_TYPE_SHORT
        ORDER BY f.DATE_KEY
    )                                                   AS PREV_YEAR_REGISTRATIONS,
    CASE
        WHEN LAG(COUNT(*)) OVER (
            PARTITION BY v.EV_TYPE_SHORT
            ORDER BY f.DATE_KEY
        ) > 0
        THEN ROUND(
            (COUNT(*) - LAG(COUNT(*)) OVER (
                PARTITION BY v.EV_TYPE_SHORT
                ORDER BY f.DATE_KEY
            )) * 100.0
            / LAG(COUNT(*)) OVER (
                PARTITION BY v.EV_TYPE_SHORT
                ORDER BY f.DATE_KEY
            ), 2)
        ELSE NULL
    END                                                 AS YOY_GROWTH_PCT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY f.DATE_KEY), 2) AS PCT_OF_YEAR_TOTAL
FROM fact f
LEFT JOIN dim_v v ON f.VEHICLE_KEY = v.VEHICLE_KEY
GROUP BY f.DATE_KEY, v.EV_TYPE_SHORT
