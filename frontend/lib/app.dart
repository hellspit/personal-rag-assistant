import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/voice_assistant_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Assistant RAG',
      theme: AppTheme.darkTheme,
      home: const VoiceAssistantScreen(),
    );
  }
}
