import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:async';
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
  bool _isMonitoring = false;

  bool get isRecording => _isRecording;
  double get audioLevel => _audioLevel;

  Future<void> requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> startContinuousMonitoring() async {
    if (await _audioRecorder.hasPermission() && !_isMonitoring) {
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/ambient_audio.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: audioPath,
      );
      _isMonitoring = true;
      _startRealTimeAudioMonitoring();
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      _isRecording = true;
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    _isRecording = false;
    notifyListeners();
  }

  void _startRealTimeAudioMonitoring() {
    _levelTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) async {
      if (_isMonitoring) {
        try {
          final level = await _audioRecorder.getAmplitude();
          // Convert amplitude to a normalized value (0.0 to 1.0)
          // The amplitude.current typically ranges from 0 to 100
          double normalizedLevel = (level.current / 100).clamp(0.0, 1.0);

          // Apply smoothing to avoid jarring changes
          _audioLevel = (_audioLevel * 0.6) + (normalizedLevel * 0.4);
          notifyListeners();
        } catch (error) {
          debugPrint('Error getting amplitude: $error');
        }
      }
    });
  }

  void _stopRealTimeAudioMonitoring() {
    _levelTimer?.cancel();
    _levelTimer = null;
  }

  @override
  void dispose() {
    _stopRealTimeAudioMonitoring();
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
    // Start continuous audio monitoring immediately
    await provider.startContinuousMonitoring();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<VoiceProvider>();

    // Always animate based on real-time audio level
    double audioIntensity = provider.audioLevel.clamp(0.0, 1.0);

    // Make animations more responsive to voice input
    if (audioIntensity > 0.05) {
      // Use the audio level to control animation intensity with more dynamic response
      double pulseIntensity = 0.8 + (audioIntensity * 0.4); // Range: 0.8 to 1.2
      double glowIntensity =
          audioIntensity; // Direct mapping for more responsive glow

      // Animate the controllers to the target values
      _pulseController.animateTo(
        pulseIntensity,
        duration: const Duration(milliseconds: 100),
      );
      _glowController.animateTo(
        glowIntensity,
        duration: const Duration(milliseconds: 50),
      );
    } else {
      // Gentle pulsing when no significant audio
      _pulseController.animateTo(
        0.9,
        duration: const Duration(milliseconds: 200),
      );
      _glowController.animateTo(
        0.1,
        duration: const Duration(milliseconds: 200),
      );
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
        child: Consumer<VoiceProvider>(
          builder: (context, voiceProvider, child) {
            return AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
              builder: (context, child) {
                return Stack(
                  children: [
                    // Outer neon glow effect - positioned to allow full screen glow
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 100,
                      top: MediaQuery.of(context).size.height / 2 - 100,
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF00FF,
                                ).withValues(alpha: _glowAnimation.value * 1.2),
                                blurRadius: 80 + (_glowAnimation.value * 100),
                                spreadRadius: 20 + (_glowAnimation.value * 50),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFF00FFFF,
                                ).withValues(alpha: _glowAnimation.value * 0.8),
                                blurRadius: 60 + (_glowAnimation.value * 80),
                                spreadRadius: 15 + (_glowAnimation.value * 40),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFFFF00FF,
                                ).withValues(alpha: _glowAnimation.value * 0.9),
                                blurRadius: 40 + (_glowAnimation.value * 60),
                                spreadRadius: 10 + (_glowAnimation.value * 30),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFFFF00FF,
                                ).withValues(alpha: _glowAnimation.value * 0.6),
                                blurRadius: 25 + (_glowAnimation.value * 40),
                                spreadRadius: 5 + (_glowAnimation.value * 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Main circle with logo and touch area - positioned to allow full screen glow
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 75,
                      top: MediaQuery.of(context).size.height / 2 - 75,
                      child: GestureDetector(
                        onTapDown: (_) => voiceProvider.startRecording(),
                        onTapUp: (_) => voiceProvider.stopRecording(),
                        onTapCancel: () => voiceProvider.stopRecording(),
                        child: Transform.scale(
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
                                  color: const Color(0xFFFF00FF).withValues(
                                    alpha: 0.9 * _glowAnimation.value,
                                  ),
                                  blurRadius: 25 + (_glowAnimation.value * 30),
                                  spreadRadius: 8 + (_glowAnimation.value * 15),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00FFFF).withValues(
                                    alpha: 0.7 * _glowAnimation.value,
                                  ),
                                  blurRadius: 15 + (_glowAnimation.value * 25),
                                  spreadRadius: 4 + (_glowAnimation.value * 10),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFF00FF).withValues(
                                    alpha: 0.5 * _glowAnimation.value,
                                  ),
                                  blurRadius: 8 + (_glowAnimation.value * 15),
                                  spreadRadius: 2 + (_glowAnimation.value * 8),
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
                      ),
                    ),
                    // Audio level indicator - positioned at bottom center
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      bottom: MediaQuery.of(context).size.height * 0.2,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // LISTENING text (only when recording)
                              if (voiceProvider.isRecording)
                                Transform.scale(
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
                                ),
                              if (voiceProvider.isRecording)
                                const SizedBox(height: 8),
                              // Always visible audio level indicator
                              Container(
                                width: 100,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: voiceProvider.audioLevel,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF00FFFF),
                                          Color(0xFFFF00FF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
