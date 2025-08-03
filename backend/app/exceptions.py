"""
Custom exceptions for the App Launcher API
"""

from fastapi import HTTPException


class AppNotFoundError(HTTPException):
    """Raised when an app is not found"""
    def __init__(self, app_name: str):
        super().__init__(
            status_code=404,
            detail=f"Application '{app_name}' not found"
        )


class AppLaunchError(HTTPException):
    """Raised when there's an error launching an app"""
    def __init__(self, app_name: str, error: str):
        super().__init__(
            status_code=500,
            detail=f"Error launching '{app_name}': {error}"
        ) 