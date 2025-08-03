import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_circle.dart';
import '../widgets/audio_level_indicator.dart';

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
    final provider = context.read<VoiceProvider>();
    await provider.requestPermissions();
    // Start continuous audio monitoring immediately
    await provider.startContinuousMonitoring();
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
        child: const Stack(children: [VoiceCircle(), AudioLevelIndicator()]),
      ),
    );
  }
}
