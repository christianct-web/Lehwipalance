import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import (
    auth,
    events,
    filter_profiles,
    health,
    listings,
    orders,
    promoter,
    reviews,
    sales,
    social,
    uploads,
)
from app.core.config import get_settings
from app.services import payments


def create_app() -> FastAPI:
    settings = get_settings()
    settings.check_production()
    payments.check_configured()
    logging.basicConfig(level=logging.INFO)

    app = FastAPI(
        title="Lehwi Palance API",
        version="0.2.0",
        # Interactive docs stay on in development; in production they'd only map the API for others.
        docs_url=None if settings.is_production else "/docs",
        redoc_url=None,
        openapi_url=None if settings.is_production else "/openapi.json",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(events.router)
    app.include_router(listings.router)
    app.include_router(filter_profiles.router)
    app.include_router(filter_profiles.feed_router)
    app.include_router(social.router)
    app.include_router(social.public)
    app.include_router(reviews.router)
    app.include_router(orders.router)
    app.include_router(promoter.router)
    app.include_router(sales.router)
    app.include_router(uploads.router)
    return app


app = create_app()
