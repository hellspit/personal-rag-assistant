"""
Router for app-related endpoints
"""

from fastapi import APIRouter

from ..models import AppResponse, AppsListResponse, HealthResponse, RootResponse, LLMRequest, LLMResponse
from ..services import open_app, get_available_apps, get_health_status, process_with_llm
from ..config import API_VERSION

router = APIRouter()


@router.get("/", response_model=RootResponse)
async def root():
    """Root endpoint"""
    return RootResponse(
        message="App Launcher API",
        version=API_VERSION,
        endpoints={
            "open_app_post": "/open-app/{app_name} (POST)",
            "open_app_get": "/open-app/{app_name} (GET)",
            "list_apps": "/list-apps",
            "health": "/health",
            "llm": "/llm (POST)"
        }
    )


@router.post("/open-app/{app_name}", response_model=AppResponse)
async def open_application(app_name: str):
    """Open an application by name"""
    result = open_app(app_name)
    return AppResponse(**result)


@router.get("/open-app/{app_name}", response_model=AppResponse)
async def open_application_get(app_name: str):
    """Open an application by name (GET method)"""
    result = open_app(app_name)
    return AppResponse(**result)


@router.get("/list-apps", response_model=AppsListResponse)
async def list_available_apps():
    """List all available apps"""
    result = get_available_apps()
    return AppsListResponse(**result)


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    result = get_health_status()
    return HealthResponse(**result)


@router.post("/llm", response_model=LLMResponse)
async def process_llm_request(request: LLMRequest):
    """Process text through LLM and return response"""
    print(f"Received LLM request: {request.prompt} with model: {request.model}")
    result = process_with_llm(request.prompt, request.model, request.chat_history)
    print(f"LLM result: {result}")
    return LLMResponse(**result) 