{{
    config(
        materialized='table'
    )
}}

WITH silver AS (
    SELECT DISTINCT ELECTRIC_UTILITY
    FROM {{ source('silver', 'SILVER_EV_REGISTRATIONS') }}
    WHERE ELECTRIC_UTILITY IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY ELECTRIC_UTILITY) AS UTILITY_KEY,
    ELECTRIC_UTILITY                               AS UTILITY_NAME
FROM silver
