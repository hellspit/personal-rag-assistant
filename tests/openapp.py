#!/usr/bin/env python3
"""
App Launcher Script
Opens applications by name on Windows
Supports both text and voice input
"""

import os
import sys
import subprocess
import webbrowser
from pathlib import Path

# Try to import speech recognition
try:
    import speech_recognition as sr
    VOICE_AVAILABLE = True
except ImportError:
    VOICE_AVAILABLE = False
    print("⚠️  Voice mode not available. Install with: pip install SpeechRecognition pyaudio")

# Dictionary of common app names and their executable paths
COMMON_APPS = {
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

def expand_user_path(path):
    """Expand %USERNAME% in paths"""
    return path.replace('%USERNAME%', os.getenv('USERNAME', ''))

def find_app_in_path(app_name):
    """Try to find an app in the system PATH"""
    try:
        result = subprocess.run(['where', app_name], 
                              capture_output=True, text=True, shell=True)
        if result.returncode == 0:
            return result.stdout.strip().split('\n')[0]
    except:
        pass
    return None

def listen_for_voice():
    """Listen for voice input and return the recognized text"""
    if not VOICE_AVAILABLE:
        print("❌ Voice recognition not available")
        return None
    
    recognizer = sr.Recognizer()
    
    try:
        with sr.Microphone() as source:
            print("🎤 Listening... Speak now!")
            print("(Say 'cancel' to go back to text mode)")
            
            # Adjust for ambient noise
            recognizer.adjust_for_ambient_noise(source, duration=0.5)
            
            # Listen for audio
            audio = recognizer.listen(source, timeout=5, phrase_time_limit=5)
            
            print("🔄 Processing speech...")
            
            # Recognize speech
            text = recognizer.recognize_google(audio).lower().strip()
            print(f"🎯 You said: '{text}'")
            return text
            
    except sr.WaitTimeoutError:
        print("⏰ No speech detected within timeout")
        return None
    except sr.UnknownValueError:
        print("❓ Could not understand what you said")
        return None
    except sr.RequestError as e:
        print(f"❌ Speech recognition error: {e}")
        return None
    except Exception as e:
        print(f"❌ Error with voice recognition: {e}")
        return None

def open_app(app_name):
    """Open an application by name"""
    app_name_lower = app_name.lower().strip()
    
    # Check if it's a common app
    if app_name_lower in COMMON_APPS:
        app_path = COMMON_APPS[app_name_lower]
        app_path = expand_user_path(app_path)
        
        # Check if the file exists
        if os.path.exists(app_path):
            try:
                subprocess.Popen([app_path])
                print(f"✅ Opened {app_name}")
                return True
            except Exception as e:
                print(f"❌ Error opening {app_name}: {e}")
                return False
        else:
            print(f"❌ {app_name} not found at: {app_path}")
    
    # Try to find the app in PATH
    app_path = find_app_in_path(app_name)
    if app_path:
        try:
            subprocess.Popen([app_path])
            print(f"✅ Opened {app_name}")
            return True
        except Exception as e:
            print(f"❌ Error opening {app_name}: {e}")
            return False
    
    # Try to open as a web URL
    if app_name_lower.startswith(('http://', 'https://')):
        try:
            webbrowser.open(app_name)
            print(f"✅ Opened URL: {app_name}")
            return True
        except Exception as e:
            print(f"❌ Error opening URL: {e}")
            return False
    
    # Try to open with default program
    try:
        subprocess.Popen(['start', app_name], shell=True)
        print(f"✅ Attempted to open {app_name} with default program")
        return True
    except Exception as e:
        print(f"❌ Error opening {app_name}: {e}")
        return False

def list_available_apps():
    """List all available apps"""
    print("📱 Available apps:")
    for app_name in sorted(COMMON_APPS.keys()):
        print(f"  - {app_name}")
    print("\n💡 You can also try:")
    print("  - Any executable name in PATH")
    print("  - Full path to an executable")
    print("  - URLs (http:// or https://)")

def main():
    """Main function"""
    print("🚀 App Launcher")
    print("=" * 50)
    
    # Check for command line arguments first
    if len(sys.argv) > 1:
        if sys.argv[1] in ['--list', '-l', '--help', '-h']:
            list_available_apps()
            return
        else:
            app_name = ' '.join(sys.argv[1:])
            open_app(app_name)
            return
    
    # Interactive mode - ask once and exit
    print("\n📱 What app would you like to open?")
    print("Type 'list' to see available apps")
    if VOICE_AVAILABLE:
        print("Type 'voice' or 'v' to use voice mode")
    print("-" * 30)
    
    try:
        user_input = input("Enter app name: ").strip()
        
        if user_input.lower() in ['list', 'l', '--list', '-l']:
            list_available_apps()
        elif user_input.lower() in ['voice', 'v'] and VOICE_AVAILABLE:
            # Voice mode
            voice_text = listen_for_voice()
            if voice_text:
                if voice_text.lower() in ['cancel', 'exit', 'quit']:
                    print("🔄 Switching back to text mode...")
                    main()  # Restart main function
                    return
                open_app(voice_text)
        elif user_input:
            open_app(user_input)
        else:
            print("❌ Please enter an app name")
            
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except EOFError:
        print("\n👋 Goodbye!")

if __name__ == "__main__":
    main()
