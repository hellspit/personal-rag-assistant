"""
Configuration and constants for the App Launcher API
"""

import os
from typing import Dict

# API Configuration
API_TITLE = "App Launcher API"
API_DESCRIPTION = "API to open applications by name on Windows"
API_VERSION = "1.0.0"

# Dictionary of common app names and their executable paths
COMMON_APPS: Dict[str, str] = {
    # Web browsers
    'chrome': r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'firefox': r'C:\Program Files\Mozilla Firefox\firefox.exe',
    'edge': r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    
    # Office applications
    'word': r'C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE',
    'excel': r'C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE',
    'powerpoint': r'C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE',
    'outlook': r'C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE',
    
    # Development tools
    'vscode': r'C:\Users\%USERNAME%\AppData\Local\Programs\Microsoft VS Code\Code.exe',
    'notepad++': r'C:\Program Files\Notepad++\notepad++.exe',
    'sublime': r'C:\Program Files\Sublime Text\sublime_text.exe',
    
    # Media players
    'vlc': r'C:\Program Files\VideoLAN\VLC\vlc.exe',
    'spotify': r'C:\Users\%USERNAME%\AppData\Roaming\Spotify\Spotify.exe',
    
    # System tools
    'calculator': r'C:\Windows\System32\calc.exe',
    'notepad': r'C:\Windows\System32\notepad.exe',
    'paint': r'C:\Windows\System32\mspaint.exe',
    'cmd': r'C:\Windows\System32\cmd.exe',
    'powershell': r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe',
    'my pc': r'C:\Windows\explorer.exe',
    'file explorer': r'C:\Windows\explorer.exe',
    'explorer': r'C:\Windows\explorer.exe',
    
    # Flutter/Development
    'flutter': 'flutter',
    'dart': 'dart',
    'git': 'git',
}

# Server Configuration
HOST = "0.0.0.0"
PORT = 8000

# LLM Configuration
LLM_SYSTEM_PROMPT = "You are a my personal helpful assistant. Please respond to the question asked in simple and concise manner. Maintain context from previous messages. Use clear, concise formatting with proper paragraph breaks (single newline between paragraphs). Avoid excessive newlines or spacing." 