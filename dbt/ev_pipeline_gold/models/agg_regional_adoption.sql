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
    g.STATE_CODE,
    g.COUNTY,
    g.REGION_GROUP,
    v.EV_TYPE_SHORT,
    COUNT(*)                                                            AS REGISTRATIONS,
    SUM(CASE WHEN v.IS_BEV THEN 1 ELSE 0 END)                         AS BEV_COUNT,
    SUM(CASE WHEN NOT v.IS_BEV THEN 1 ELSE 0 END)                     AS PHEV_COUNT,
    ROUND(SUM(CASE WHEN v.IS_BEV THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS BEV_PCT,
    RANK() OVER (PARTITION BY v.EV_TYPE_SHORT ORDER BY COUNT(*) DESC)  AS COUNTY_RANK
FROM fact f
LEFT JOIN dim_g g ON f.GEO_KEY = g.GEO_KEY
LEFT JOIN dim_v v ON f.VEHICLE_KEY = v.VEHICLE_KEY
WHERE f.IS_WA_RECORD = TRUE
GROUP BY g.STATE_CODE, g.COUNTY, g.REGION_GROUP, v.EV_TYPE_SHORT
