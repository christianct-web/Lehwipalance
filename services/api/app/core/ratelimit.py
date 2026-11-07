"""A small in-process rate limiter for login, sign-up and checkout.

The API runs as one process behind Caddy, so memory is enough. If it ever runs
as several workers or machines, move this to Redis or the proxy.
"""

import time
from collections import defaultdict, deque
from collections.abc import Callable
from threading import Lock

from fastapi import HTTPException, Request, status

from app.core.config import get_settings

_hits: dict[str, deque[float]] = defaultdict(deque)
_lock = Lock()


def reset() -> None:
    with _lock:
        _hits.clear()


def rate_limit(name: str, limit: int, window_seconds: int) -> Callable[[Request], None]:
    def dependency(request: Request) -> None:
        if not get_settings().rate_limits_enabled:
            return
        ip = request.client.host if request.client else "unknown"
        key = f"{name}:{ip}"
        now = time.monotonic()
        with _lock:
            hits = _hits[key]
            while hits and hits[0] <= now - window_seconds:
                hits.popleft()
            if len(hits) >= limit:
                raise HTTPException(
                    status.HTTP_429_TOO_MANY_REQUESTS,
                    "Too many attempts, try again in a minute",
                )
            hits.append(now)

    return dependency
