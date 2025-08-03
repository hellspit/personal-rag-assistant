"""
Pydantic models for the App Launcher API
"""

from typing import Optional
from pydantic import BaseModel


class AppResponse(BaseModel):
    """Response model for app operations"""
    success: bool
    message: str
    app_name: str
    app_path: Optional[str] = None


class HealthResponse(BaseModel):
    """Response model for health check"""
    status: str
    platform: str
    available_apps_count: int


class AppsListResponse(BaseModel):
    """Response model for listing available apps"""
    available_apps: list[str]
    total_count: int
    note: str


class RootResponse(BaseModel):
    """Response model for root endpoint"""
    message: str
    version: str
    endpoints: dict[str, str]


class LLMRequest(BaseModel):
    """Request model for LLM operations"""
    prompt: str
    model: str = "gemma3"
    chat_history: str = ""


class LLMResponse(BaseModel):
    """Response model for LLM operations"""
    success: bool
    response: str
    model: str
    prompt: str
    processing_time: Optional[float] = None 