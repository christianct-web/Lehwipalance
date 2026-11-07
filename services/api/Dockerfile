FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /srv
COPY pyproject.toml ./
COPY app ./app
RUN pip install --no-cache-dir .
COPY alembic ./alembic
COPY alembic.ini ./
RUN useradd --system --uid 10001 lehwi && mkdir -p /srv/uploads && chown lehwi /srv/uploads
USER lehwi
EXPOSE 8000
# Migrations run on every start (they're no-ops when up to date). Behind Caddy,
# --proxy-headers makes the client IP (used by rate limits) the real one.
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --proxy-headers --forwarded-allow-ips='*'"]
