USE ROLE ACCOUNTADMIN;
USE WAREHOUSE WH_TRANSFORM;

CREATE OR REPLACE AGENT EV_GOLD.SERVING.EV_ANALYTICS_AGENT
  FROM SPECIFICATION $$
models:
  orchestration: auto
instructions:
  response: "You are an EV analytics assistant for the Washington State Electric Vehicle Population dataset (22,183 vehicles). Provide concise, data-driven answers. Always warn users that 2023 data is partial — YoY figures for 2023 are snapshot artifacts."
  orchestration: "Use the EV Analytics tool for all questions about EV registrations, growth trends, market share, regional adoption, CAFV eligibility, and vehicle models."
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "EV_Analytics"
      description: "Answers questions about Washington State EV registrations including YoY growth, regional adoption, BEV vs PHEV penetration, manufacturer market share, CAFV eligibility, and model trends."
tool_resources:
  EV_Analytics:
    semantic_view: "EV_GOLD.SERVING.EV_PIPELINE_SEMANTIC_VIEW"
    execution_environment:
      type: warehouse
      warehouse: "WH_TRANSFORM"
$$;

SHOW AGENTS IN SCHEMA EV_GOLD.SERVING;
DESCRIBE AGENT EV_GOLD.SERVING.EV_ANALYTICS_AGENT;

SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'EV_GOLD.SERVING.EV_ANALYTICS_AGENT',
    $${
      "messages": [
        {"role": "user", "content": [{"type": "text", "text": "What percentage of EVs are eligible for CAFV incentives?"}]}
      ],
      "stream": false
    }$$
  )
) AS RESPONSE;
