"""
Tests for the apps router
"""

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_root_endpoint():
    """Test the root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "App Launcher API"
    assert "endpoints" in data


def test_health_check():
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["platform"] == "Windows"


def test_list_apps():
    """Test the list apps endpoint"""
    response = client.get("/list-apps")
    assert response.status_code == 200
    data = response.json()
    assert "available_apps" in data
    assert "total_count" in data
    assert isinstance(data["available_apps"], list)


def test_open_app_get():
    """Test opening an app via GET"""
    response = client.get("/open-app/notepad")
    assert response.status_code == 200
    data = response.json()
    assert "success" in data
    assert "message" in data
    assert "app_name" in data


def test_open_app_post():
    """Test opening an app via POST"""
    response = client.post("/open-app/calculator")
    assert response.status_code == 200
    data = response.json()
    assert "success" in data
    assert "message" in data
    assert "app_name" in data


def test_llm_endpoint():
    """Test the LLM endpoint"""
    test_data = {
        "prompt": "Hello, how are you?",
        "model": "gemma3"
    }
    response = client.post("/llm", json=test_data)
    assert response.status_code == 200
    data = response.json()
    assert "success" in data
    assert "response" in data
    assert "model" in data
    assert "prompt" in data
    assert "processing_time" in data
    assert data["model"] == "gemma3"
    assert data["prompt"] == "Hello, how are you?"


def test_llm_endpoint_default_model():
    """Test the LLM endpoint with default model"""
    test_data = {
        "prompt": "What is Python?"
    }
    response = client.post("/llm", json=test_data)
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "gemma3"  # Default model 