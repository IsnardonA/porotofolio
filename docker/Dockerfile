FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       git \
       curl \
       gcc \
       libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip setuptools
RUN python -m pip install dlt dbt-duckdb google-auth requests

WORKDIR /app
COPY src/ ./src/

CMD ["bash"]
