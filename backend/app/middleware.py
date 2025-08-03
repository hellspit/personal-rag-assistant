"""
Middleware for the FastAPI application
"""

from fastapi import Request
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def log_requests(request: Request, call_next):
    """Middleware to log all requests"""
    start_time = time.time()
    
    # Log the request
    logger.info(f"Request: {request.method} {request.url}")
    
    # Process the request
    response = await call_next(request)
    
    # Calculate processing time
    process_time = time.time() - start_time
    
    # Log the response
    logger.info(f"Response: {response.status_code} - {process_time:.4f}s")
    
    return response 