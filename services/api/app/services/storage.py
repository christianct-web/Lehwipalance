"""Event flyer storage: Supabase Storage when configured, local disk otherwise."""

import secrets
from pathlib import Path

import httpx

from app.core.config import get_settings

# Recognise images by their first bytes rather than trusting the upload's type.
_SIGNATURES = {
    b"\xff\xd8\xff": ("jpg", "image/jpeg"),
    b"\x89PNG\r\n\x1a\n": ("png", "image/png"),
}


class StorageError(Exception):
    pass


def sniff_image(data: bytes) -> tuple[str, str] | None:
    for magic, kind in _SIGNATURES.items():
        if data.startswith(magic):
            return kind
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "webp", "image/webp"
    return None


def save_image(data: bytes, prefix: str) -> str:
    """Store an image and return its public URL."""
    kind = sniff_image(data)
    if kind is None:
        raise StorageError("Upload a JPEG, PNG or WebP image")
    ext, content_type = kind
    key = f"{prefix}/{secrets.token_hex(8)}.{ext}"
    settings = get_settings()

    if settings.supabase_url and settings.supabase_service_key:
        base = settings.supabase_url.rstrip("/")
        bucket = settings.supabase_bucket
        r = httpx.post(
            f"{base}/storage/v1/object/{bucket}/{key}",
            content=data,
            headers={
                "Authorization": f"Bearer {settings.supabase_service_key}",
                "apikey": settings.supabase_service_key,
                "Content-Type": content_type,
                "x-upsert": "true",
            },
            timeout=30,
        )
        if r.status_code >= 300:
            raise StorageError(f"Supabase Storage refused the upload ({r.status_code})")
        return f"{base}/storage/v1/object/public/{bucket}/{key}"

    path = Path(settings.upload_dir) / key
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return f"{settings.public_base_url.rstrip('/')}/api/uploads/{key}"
