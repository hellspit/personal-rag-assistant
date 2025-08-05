import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/voice_provider.dart';
import 'providers/stt_provider.dart';
import 'theme/app_theme.dart';
import 'screens/voice_assistant_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => STTProvider()),
      ],
      child: MaterialApp(
        title: 'Personal Assistant RAG',
        theme: AppTheme.darkTheme,
        home: const VoiceAssistantScreen(),
      ),
    );
  }
}
