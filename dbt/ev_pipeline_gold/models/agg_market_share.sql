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
),

dim_g AS (
    SELECT * FROM {{ ref('dim_geography') }}
)

SELECT
    v.MAKE,
    v.MAKE_TIER,
    v.IS_TESLA,
    g.STATE_CODE,
    g.REGION_GROUP,
    v.EV_TYPE_SHORT,
    COUNT(*)                                                                    AS REGISTRATIONS,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY g.STATE_CODE, v.EV_TYPE_SHORT
    ), 2)                                                                       AS MARKET_SHARE_PCT,
    RANK() OVER (
        PARTITION BY g.STATE_CODE, v.EV_TYPE_SHORT
        ORDER BY COUNT(*) DESC
    )                                                                           AS MAKE_RANK
FROM fact f
LEFT JOIN dim_v v ON f.VEHICLE_KEY = v.VEHICLE_KEY
LEFT JOIN dim_g g ON f.GEO_KEY = g.GEO_KEY
GROUP BY v.MAKE, v.MAKE_TIER, v.IS_TESLA, g.STATE_CODE, g.REGION_GROUP, v.EV_TYPE_SHORT
