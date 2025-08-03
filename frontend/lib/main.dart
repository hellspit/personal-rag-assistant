import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => VoiceProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Assistant RAG',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFFF),
          secondary: Color(0xFFFF00FF),
          surface: Color(0xFF111111),
          background: Color(0xFF000000),
        ),
      ),
      home: const VoiceAssistantScreen(),
    );
  }
}

class VoiceProvider extends ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  double _audioLevel = 0.0;
  Timer? _levelTimer;

  bool get isRecording => _isRecording;
  double get audioLevel => _audioLevel;

  Future<void> requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/audio_recording.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: audioPath,
      );
      _isRecording = true;
      _startLevelMonitoring();
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    await _audioRecorder.stop();
    _isRecording = false;
    _levelTimer?.cancel();
    _audioLevel = 0.0;
    notifyListeners();
  }

  void _startLevelMonitoring() {
    _levelTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      if (_isRecording) {
        final level = await _audioRecorder.getAmplitude();
        _audioLevel = (level.current / 100).clamp(0.0, 1.0);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _levelTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _requestPermissions();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _requestPermissions() async {
    final provider = context.read<VoiceProvider>();
    await provider.requestPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<VoiceProvider>();

    // Animate based on audio level
    if (provider.isRecording && provider.audioLevel > 0.1) {
      _pulseController.forward();
      _glowController.forward();
    } else {
      _pulseController.reverse();
      _glowController.reverse();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
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
            colors: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
          ),
        ),
        child: Center(
          child: Consumer<VoiceProvider>(
            builder: (context, voiceProvider, child) {
              return GestureDetector(
                onTapDown: (_) => voiceProvider.startRecording(),
                onTapUp: (_) => voiceProvider.stopRecording(),
                onTapCancel: () => voiceProvider.stopRecording(),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseAnimation,
                    _glowAnimation,
                  ]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer neon glow effect
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF00FF).withValues(
                                    alpha: _glowAnimation.value * 1.0,
                                  ),
                                  blurRadius: 50 + (_glowAnimation.value * 40),
                                  spreadRadius:
                                      12 + (_glowAnimation.value * 20),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFF00FF).withValues(
                                    alpha: _glowAnimation.value * 0.8,
                                  ),
                                  blurRadius: 35 + (_glowAnimation.value * 30),
                                  spreadRadius: 8 + (_glowAnimation.value * 15),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFF00FF).withValues(
                                    alpha: _glowAnimation.value * 0.6,
                                  ),
                                  blurRadius: 25 + (_glowAnimation.value * 25),
                                  spreadRadius: 5 + (_glowAnimation.value * 12),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFF00FF).withValues(
                                    alpha: _glowAnimation.value * 0.4,
                                  ),
                                  blurRadius: 15 + (_glowAnimation.value * 20),
                                  spreadRadius: 3 + (_glowAnimation.value * 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Main circle with logo
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(
                                    0xFFFF00FF,
                                  ).withValues(alpha: 0.4),
                                  const Color(
                                    0xFF000000,
                                  ).withValues(alpha: 0.8),
                                  const Color(
                                    0xFF000000,
                                  ).withValues(alpha: 0.95),
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF00FF,
                                  ).withValues(alpha: 0.9),
                                  blurRadius: 25,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF00FF,
                                  ).withValues(alpha: 0.7),
                                  blurRadius: 15,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF00FF,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/img/tanjiro.png',
                                fit: BoxFit.cover,
                                width: 150,
                                height: 150,
                              ),
                            ),
                          ),
                        ),
                        // LISTENING text below logo
                        if (voiceProvider.isRecording)
                          Positioned(
                            bottom: -80,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF00FF,
                                      ).withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF00FF,
                                          ).withValues(alpha: 0.7),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'LISTENING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
