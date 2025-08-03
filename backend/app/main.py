"""
Main FastAPI application
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import API_TITLE, API_DESCRIPTION, API_VERSION
from .routers import apps
from .middleware import log_requests

# Create FastAPI app instance
app = FastAPI(
    title=API_TITLE,
    description=API_DESCRIPTION,
    version=API_VERSION
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add custom middleware
app.middleware("http")(log_requests)

# Include routers
app.include_router(apps.router, tags=["apps"]) 