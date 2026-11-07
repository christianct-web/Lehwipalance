"""Serve flyers stored on local disk (when Supabase Storage isn't configured)."""

from pathlib import Path

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import FileResponse

from app.core.config import get_settings

router = APIRouter(tags=["uploads"])


@router.get("/uploads/{path:path}", include_in_schema=False)
def get_upload(path: str) -> FileResponse:
    root = Path(get_settings().upload_dir).resolve()
    target = (root / path).resolve()
    if not target.is_relative_to(root) or not target.is_file():
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    return FileResponse(target, headers={"Cache-Control": "public, max-age=31536000, immutable"})
