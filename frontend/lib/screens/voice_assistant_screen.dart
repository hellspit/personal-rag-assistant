import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../providers/stt_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_circle.dart';
import '../widgets/audio_level_indicator.dart';
import '../widgets/transcription_display.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final voiceProvider = context.read<VoiceProvider>();
    final sttProvider = context.read<STTProvider>();

    await voiceProvider.requestPermissions();

    // Connect voice provider with STT provider
    voiceProvider.setSTTProvider(sttProvider);

    // Connect STT provider with voice provider for audio session management
    sttProvider.setVoiceProvider(voiceProvider);

    // Initialize STT server connection
    await sttProvider.initializeServer();

    // Start continuous audio monitoring immediately
    await voiceProvider.startContinuousMonitoring();

    // Start STT listening
    sttProvider.startListening();
  }

  @override
  void dispose() {
    // Clean up resources
    final voiceProvider = context.read<VoiceProvider>();
    final sttProvider = context.read<STTProvider>();

    sttProvider.stopListening();
    voiceProvider.stopContinuousMonitoring();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground,
              AppTheme.mediumBackground,
              AppTheme.lightBackground,
            ],
          ),
        ),
        child: const Stack(
          children: [
            VoiceCircle(),
            AudioLevelIndicator(),
            TranscriptionDisplay(),
          ],
        ),
      ),
    );
  }
}
