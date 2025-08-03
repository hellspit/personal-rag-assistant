# Personal Assistant RAG - Flutter Frontend

A professional Flutter application for voice interaction with a personal assistant using RAG (Retrieval-Augmented Generation).

## Project Structure

The codebase has been refactored into a professional, modular structure:

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # Main app configuration
├── providers/
│   └── voice_provider.dart   # Audio recording and monitoring logic
├── screens/
│   └── voice_assistant_screen.dart  # Main voice assistant screen
├── widgets/
│   ├── voice_circle.dart     # Animated voice circle with neon effects
│   └── audio_level_indicator.dart   # Audio level visualization
└── theme/
    └── app_theme.dart        # Theme configuration and color constants
```

## Architecture Overview

### 1. **Providers** (`providers/`)
- **VoiceProvider**: Manages audio recording, permissions, and real-time audio monitoring
- Handles microphone permissions and continuous audio level detection
- Provides reactive state management for the UI

### 2. **Screens** (`screens/`)
- **VoiceAssistantScreen**: Main application screen
- Orchestrates the overall UI layout and manages screen-level state
- Handles permission requests and initial setup

### 3. **Widgets** (`widgets/`)
- **VoiceCircle**: Complex animated circle with neon effects and gesture handling
- **AudioLevelIndicator**: Visual feedback for audio levels and recording status
- Each widget is self-contained with its own animation controllers

### 4. **Theme** (`theme/`)
- **AppTheme**: Centralized theme configuration
- Color constants for consistent styling across the app
- Dark theme with red accent colors

### 5. **App Configuration** (`app.dart`)
- **MyApp**: Main app widget with theme and routing configuration
- Clean separation of app-level concerns

## Key Features

- **Real-time Audio Monitoring**: Continuous background audio level detection
- **Responsive Animations**: Dynamic neon effects that respond to voice input
- **Professional UI**: Modern dark theme with sophisticated visual effects
- **Modular Architecture**: Clean separation of concerns for maintainability
- **State Management**: Provider pattern for reactive UI updates

## Dependencies

- `flutter/material.dart` - Core Flutter framework
- `provider` - State management
- `permission_handler` - Microphone permissions
- `record` - Audio recording functionality
- `path_provider` - File system access

## Getting Started

1. Ensure all dependencies are installed
2. Run `flutter pub get` to install packages
3. Ensure microphone permissions are granted
4. Run the application with `flutter run`

## Code Quality

- **Separation of Concerns**: Each file has a single responsibility
- **Reusable Components**: Widgets are modular and reusable
- **Consistent Styling**: Centralized theme and color management
- **Clean Architecture**: Professional file organization
- **Documentation**: Clear code structure and comments
