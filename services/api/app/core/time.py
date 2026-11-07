from datetime import UTC, datetime


def utcnow() -> datetime:
    return datetime.now(UTC)


def aware(dt: datetime | None) -> datetime | None:
    """SQLite hands back naive datetimes; everything is stored as UTC."""
    if dt is not None and dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt
