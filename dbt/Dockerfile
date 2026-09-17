FROM python:3.11-slim

RUN pip install --no-cache-dir --default-timeout=180 --retries 5 dbt-snowflake==1.8.4

WORKDIR /usr/app/dbt

ENTRYPOINT ["dbt"]