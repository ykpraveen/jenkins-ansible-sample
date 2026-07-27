FROM python:3.12-slim AS base
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /uvx /usr/local/bin/
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 \
    UV_PROJECT_ENVIRONMENT=/usr/local
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

FROM base AS test
RUN uv sync --frozen --group test --no-install-project
COPY app.py .
COPY tests/ tests/
RUN python -m pytest -q

FROM base AS final
COPY --from=test /app/app.py .
ARG APP_VERSION=dev
ARG GIT_SHA=unknown
ENV APP_VERSION=${APP_VERSION} \
    GIT_SHA=${GIT_SHA}
EXPOSE 8080
USER nobody
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"]
