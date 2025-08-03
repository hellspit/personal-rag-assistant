import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/voice_provider.dart';
import 'app.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => VoiceProvider(),
      child: const MyApp(),
    ),
  );
}
