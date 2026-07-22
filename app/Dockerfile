FROM python:3.12-slim AS base
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS test
COPY requirements-test.txt .
RUN pip install --no-cache-dir -r requirements-test.txt
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
