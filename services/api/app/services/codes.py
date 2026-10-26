"""Slugs for public URLs and short codes for committee sellers."""

import re
import secrets
import unicodedata

# No 0/O or 1/I/L, so codes survive being read aloud or written on a flyer.
_SELLER_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"


def slugify(text: str, max_length: int = 100) -> str:
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_text.lower()).strip("-")
    return slug[:max_length].rstrip("-") or "untitled"


def with_suffix(slug: str) -> str:
    """Make a taken slug unique by appending a short random suffix."""
    return f"{slug}-{secrets.token_hex(3)}"


def seller_code(length: int = 6) -> str:
    return "".join(secrets.choice(_SELLER_ALPHABET) for _ in range(length))
