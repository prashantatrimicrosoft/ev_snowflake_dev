{{
    config(
        materialized='table'
    )
}}

WITH year_range AS (
    SELECT 1999 AS MODEL_YEAR
    UNION ALL
    SELECT MODEL_YEAR + 1
    FROM year_range
    WHERE MODEL_YEAR < 2026
)

SELECT
    MODEL_YEAR                                          AS DATE_KEY,
    MODEL_YEAR,
    FLOOR((MODEL_YEAR - 1) / 10) * 10 || 's'           AS DECADE,
    CASE
        WHEN MODEL_YEAR >= 2020 THEN '2020+'
        WHEN MODEL_YEAR >= 2015 THEN '2015-2019'
        WHEN MODEL_YEAR >= 2010 THEN '2010-2014'
        ELSE 'Pre-2010'
    END                                                 AS ERA,
    CASE WHEN MODEL_YEAR = YEAR(CURRENT_DATE()) THEN TRUE ELSE FALSE END AS IS_CURRENT_YEAR
FROM year_range
