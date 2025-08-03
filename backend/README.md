# App Launcher API

A FastAPI-based REST API for launching applications on Windows systems.

## Project Structure

```
backend/
├── app/                    # Main application package
│   ├── __init__.py
│   ├── main.py            # FastAPI app instance
│   ├── config.py          # Configuration and constants
│   ├── models.py          # Pydantic models
│   ├── services.py        # Business logic
│   ├── dependencies.py    # Dependency injection
│   ├── exceptions.py      # Custom exceptions
│   ├── middleware.py      # Custom middleware
│   └── routers/           # API route handlers
│       ├── __init__.py
│       └── apps.py        # App-related endpoints
├── tests/                 # Test files
│   ├── __init__.py
│   └── test_apps.py       # Tests for apps router
├── alembic.ini           # Database migration config (future use)
├── pytest.ini           # Pytest configuration
├── env.example           # Environment variables template
├── requirements.txt      # Python dependencies
├── run.py               # Application entry point
└── README.md            # This file
```

## Features

- **Application Launching**: Open applications by name, path, or URL
- **Common Apps Support**: Pre-configured paths for popular applications
- **PATH Integration**: Automatically find executables in system PATH
- **Web URL Support**: Open URLs in default browser
- **LLM Integration**: Language Model processing with Gemma 3 via Ollama
- **Health Monitoring**: Health check endpoint
- **Comprehensive Logging**: Request/response logging middleware
- **CORS Support**: Cross-origin resource sharing enabled
- **Type Safety**: Full Pydantic model validation

## Installation

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repository-url>
   cd backend
   ```

2. **Create and activate virtual environment**:
   ```bash
   python -m venv venv
   # On Windows:
   venv\Scripts\activate
   # On Unix/MacOS:
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables** (optional):
   ```bash
   cp env.example .env
   # Edit .env with your configuration
   ```

5. **Set up Ollama for LLM integration** (optional):
   ```bash
   # Install Ollama from https://ollama.ai/
   # Pull the Gemma 3 model
   ollama pull gemma3
   # Start Ollama service
   ollama serve
   ```

## Running the Application

### Development Mode
```bash
python run.py
```

### Production Mode
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

## API Endpoints

### Root
- `GET /` - API information and available endpoints

### Applications
- `GET /open-app/{app_name}` - Open an application (GET method)
- `POST /open-app/{app_name}` - Open an application (POST method)
- `GET /list-apps` - List all available applications

### System
- `GET /health` - Health check endpoint

### LLM Integration
- `POST /llm` - Process text through Language Model (Gemma 3 via Ollama)

## API Documentation

Once the server is running, you can access:
- **Interactive API docs**: `http://localhost:8000/docs`
- **ReDoc documentation**: `http://localhost:8000/redoc`

## Testing

Run the test suite:
```bash
pytest
```

Run tests with coverage:
```bash
pytest --cov=app
```

### Testing LLM Integration

Test the LLM integration separately:
```bash
python test_llm.py
```

This will test the LangChain and Ollama integration with sample questions.

## Supported Applications

The API includes pre-configured paths for common applications:

### Web Browsers
- Chrome, Firefox, Edge

### Office Applications
- Microsoft Word, Excel, PowerPoint, Outlook

### Development Tools
- VS Code, Notepad++, Sublime Text, Flutter, Dart, Git

### Media Players
- VLC, Spotify

### System Tools
- Calculator, Notepad, Paint, Command Prompt, PowerShell, File Explorer

### Custom Applications
You can also:
- Use any executable name that's in your system PATH
- Provide full paths to executables
- Open URLs (http:// or https://)

## Configuration

### Environment Variables
- `API_HOST`: Server host (default: 0.0.0.0)
- `API_PORT`: Server port (default: 8000)
- `DEBUG`: Debug mode (default: True)
- `LOG_LEVEL`: Logging level (default: INFO)
- `LANGCHAIN_API_KEY`: LangChain API key (optional)
- `LANGCHAIN_PROJECT`: LangChain project name (default: app-launcher)
- `OLLAMA_BASE_URL`: Ollama service URL (default: http://localhost:11434)

### Adding Custom Applications
Edit `app/config.py` to add more applications to the `COMMON_APPS` dictionary:

```python
COMMON_APPS = {
    # ... existing apps ...
    'myapp': r'C:\Path\To\MyApp.exe',
}
```

## Development

### Project Structure Benefits

1. **Separation of Concerns**: Each module has a specific responsibility
2. **Maintainability**: Easy to locate and modify specific functionality
3. **Testability**: Business logic is separated from API endpoints
4. **Scalability**: Easy to add new features and endpoints
5. **Type Safety**: Pydantic models ensure data validation

### Adding New Features

1. **New Endpoints**: Add to `app/routers/` directory
2. **New Models**: Add to `app/models.py`
3. **New Services**: Add to `app/services.py`
4. **New Dependencies**: Add to `app/dependencies.py`

### Code Style

The project follows PEP 8 guidelines. Consider using:
- `black` for code formatting
- `flake8` for linting
- `mypy` for type checking

## Deployment

### Docker (Recommended)
```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Production Considerations
- Set `DEBUG=False`
- Configure proper CORS origins
- Use environment variables for sensitive data
- Set up proper logging
- Consider using a reverse proxy (nginx)
- Use a production ASGI server (Gunicorn + Uvicorn)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## License

This project is licensed under the MIT License. 