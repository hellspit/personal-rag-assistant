"""
Business logic services for the App Launcher API
"""

import os
import subprocess
import webbrowser
import time
from typing import Dict, Optional

from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from dotenv import load_dotenv

from .config import COMMON_APPS, LLM_SYSTEM_PROMPT

# Load environment variables
load_dotenv()

# Set up environment variables for LangChain
os.environ["LANGCHAIN_API_KEY"] = os.getenv("LANGCHAIN_API_KEY", "")
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_PROJECT"] = os.getenv("LANGCHAIN_PROJECT", "app-launcher")

# Initialize LangChain components
llm = OllamaLLM(model="gemma3")
output_parser = StrOutputParser()

# Create the prompt template
prompt = ChatPromptTemplate.from_messages([
    ("system", LLM_SYSTEM_PROMPT),
    ("user", "Previous conversation:\n{chat_history}\n\nCurrent question: {question}"),
])

# Create the chain
chain = prompt | llm | output_parser


def expand_user_path(path: str) -> str:
    """Expand %USERNAME% in paths"""
    return path.replace('%USERNAME%', os.getenv('USERNAME', ''))


def find_app_in_path(app_name: str) -> Optional[str]:
    """Try to find an app in the system PATH"""
    try:
        result = subprocess.run(['where', app_name], 
                              capture_output=True, text=True, shell=True)
        if result.returncode == 0:
            return result.stdout.strip().split('\n')[0]
    except:
        pass
    return None


def open_app(app_name: str) -> Dict:
    """Open an application by name and return result"""
    app_name_lower = app_name.lower().strip()
    
    # Check if it's a common app
    if app_name_lower in COMMON_APPS:
        app_path = COMMON_APPS[app_name_lower]
        app_path = expand_user_path(app_path)
        
        # Check if the file exists
        if os.path.exists(app_path):
            try:
                subprocess.Popen([app_path])
                return {
                    "success": True,
                    "message": f"Successfully opened {app_name}",
                    "app_name": app_name,
                    "app_path": app_path
                }
            except Exception as e:
                return {
                    "success": False,
                    "message": f"Error opening {app_name}: {str(e)}",
                    "app_name": app_name,
                    "app_path": app_path
                }
        else:
            return {
                "success": False,
                "message": f"{app_name} not found at: {app_path}",
                "app_name": app_name,
                "app_path": app_path
            }
    
    # Try to find the app in PATH
    app_path = find_app_in_path(app_name)
    if app_path:
        try:
            subprocess.Popen([app_path])
            return {
                "success": True,
                "message": f"Successfully opened {app_name}",
                "app_name": app_name,
                "app_path": app_path
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Error opening {app_name}: {str(e)}",
                "app_name": app_name,
                "app_path": app_path
            }
    
    # Try to open as a web URL
    if app_name_lower.startswith(('http://', 'https://')):
        try:
            webbrowser.open(app_name)
            return {
                "success": True,
                "message": f"Successfully opened URL: {app_name}",
                "app_name": app_name,
                "app_path": None
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Error opening URL: {str(e)}",
                "app_name": app_name,
                "app_path": None
            }
    
    # Try to open with default program
    try:
        subprocess.Popen(['start', app_name], shell=True)
        return {
            "success": True,
            "message": f"Attempted to open {app_name} with default program",
            "app_name": app_name,
            "app_path": None
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error opening {app_name}: {str(e)}",
            "app_name": app_name,
            "app_path": None
        }


def get_available_apps() -> Dict:
    """Get list of available apps"""
    return {
        "available_apps": sorted(COMMON_APPS.keys()),
        "total_count": len(COMMON_APPS),
        "note": "You can also try any executable name in PATH, full path to an executable, or URLs (http:// or https://)"
    }


def get_health_status() -> Dict:
    """Get health status information"""
    return {
        "status": "healthy",
        "platform": "Windows",
        "available_apps_count": len(COMMON_APPS)
    }


def process_with_llm(question: str, model: str = "gemma3", chat_history: str = "") -> Dict:
    """Process text through LLM and return response"""
    
    start_time = time.time()
    
    try:
        # Use the LangChain chain to get response from real LLM
        response = chain.invoke({
            "question": question,
            "chat_history": chat_history
        })
        
        # Clean up excessive newlines in the response
        cleaned_response = clean_response_formatting(response)
        
        processing_time = time.time() - start_time
        
        return {
            "success": True,
            "response": cleaned_response,
            "model": model,
            "prompt": question,
            "processing_time": round(processing_time, 3)
        }
        
    except Exception as e:
        processing_time = time.time() - start_time
        return {
            "success": False,
            "response": f"Error processing with {model}: {str(e)}",
            "model": model,
            "prompt": question,
            "processing_time": round(processing_time, 3)
        }


def clean_response_formatting(response: str) -> str:
    """Clean up excessive newlines and formatting issues in LLM responses"""
    if not response:
        return response
    
    # Replace multiple consecutive newlines with at most 2 newlines
    import re
    cleaned = re.sub(r'\n{3,}', '\n\n', response)
    
    # Remove leading/trailing whitespace
    cleaned = cleaned.strip()
    
    # Replace multiple spaces with single space
    cleaned = re.sub(r' +', ' ', cleaned)
    
    # Ensure proper paragraph breaks (single newline between paragraphs)
    cleaned = re.sub(r'\n\s*\n\s*\n', '\n\n', cleaned)
    
    return cleaned


 