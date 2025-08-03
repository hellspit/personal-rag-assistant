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
        primarySwatch: Colors.pink,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF69B4), // Hot pink
          secondary: Color(0xFFFF1493), // Deep pink
          surface: Color(0xFF1A1A1A),
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
    debugPrint('Starting continuous monitoring...');
    if (await _audioRecorder.hasPermission() && !_isMonitoring) {
      debugPrint('Permission granted, starting recording...');
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
      debugPrint('Recording started successfully!');
      _startRealTimeAudioMonitoring();
      notifyListeners();
    } else {
      debugPrint('Permission denied or already monitoring');
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
    _levelTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) async {
      if (_isMonitoring) {
        try {
          final level = await _audioRecorder.getAmplitude();

          // Use real audio input
          double normalizedLevel = 0.0;

          // Convert negative amplitude values to positive levels
          if (level.current > -50) {
            // Only react to significant audio
            // Convert negative amplitude to positive level (0-1)
            // -50 to 0 range becomes 0 to 1
            normalizedLevel = ((-level.current) / 50.0).clamp(0.0, 1.0);
          }

          // Responsive smoothing - less smoothing for immediate response
          _audioLevel = (_audioLevel * 0.3) + (normalizedLevel * 0.7);

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
  late AnimationController _ambientController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _ambientAnimation;

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

    _ambientController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _ambientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut),
    );

    // Set initial resting state
    _pulseController.value = 1.0;
    _glowController.value = 0.0;

    // Start ambient animation for natural breathing effect
    _ambientController.repeat(reverse: true);
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
    // Remove the animation logic from here - it will be handled in the build method
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _ambientController.dispose();
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
              Color(0xFF0A0A0A), // Darker background
              Color(0xFF1A1A1A),
              Color(0xFF2A2A2A),
            ],
          ),
        ),
        child: Consumer<VoiceProvider>(
          builder: (context, voiceProvider, child) {
            // Update animations based on current audio level
            double audioIntensity = voiceProvider.audioLevel.clamp(0.0, 1.0);

            // Only react to voice input, no continuous animation
            if (audioIntensity > 0.01) {
              // Voice detected - animate based on intensity
              double pulseIntensity = 1.0 + (audioIntensity * 0.3);
              double glowIntensity = audioIntensity;

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
              // No voice detected - return to resting state immediately
              _pulseController.animateTo(
                1.0,
                duration: const Duration(milliseconds: 200),
              );
              _glowController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 200),
              );
            }

            return AnimatedBuilder(
              animation: Listenable.merge([
                _pulseAnimation,
                _glowAnimation,
                _ambientAnimation,
              ]),
              builder: (context, child) {
                return Stack(
                  children: [
                    // Ambient background glow for natural atmosphere
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.2,
                            colors: [
                              const Color(0xFFFF69B4).withValues(
                                alpha: 0.03 + (_ambientAnimation.value * 0.02),
                              ),
                              const Color(0xFFFF1493).withValues(
                                alpha: 0.02 + (_ambientAnimation.value * 0.01),
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Dynamic background glow based on voice input
                    if (_glowAnimation.value > 0.05)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.0,
                              colors: [
                                const Color(0xFFFF69B4).withValues(
                                  alpha: _glowAnimation.value * 0.15,
                                ),
                                const Color(
                                  0xFFFF1493,
                                ).withValues(alpha: _glowAnimation.value * 0.1),
                                const Color(0xFFFFB6C1).withValues(
                                  alpha: _glowAnimation.value * 0.05,
                                ),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),

                    // Main circle with enhanced neon effects
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
                                    0xFFFF69B4,
                                  ).withValues(alpha: 0.6),
                                  const Color(
                                    0xFFFF1493,
                                  ).withValues(alpha: 0.4),
                                  const Color(
                                    0xFF000000,
                                  ).withValues(alpha: 0.9),
                                  const Color(
                                    0xFF000000,
                                  ).withValues(alpha: 0.95),
                                ],
                                stops: const [0.0, 0.3, 0.8, 1.0],
                              ),
                              boxShadow: [
                                // Primary neon glow
                                BoxShadow(
                                  color: const Color(0xFFFF69B4).withValues(
                                    alpha: 0.8 * _glowAnimation.value,
                                  ),
                                  blurRadius: 20 + (_glowAnimation.value * 25),
                                  spreadRadius: 3 + (_glowAnimation.value * 8),
                                ),
                                // Secondary neon glow
                                BoxShadow(
                                  color: const Color(0xFFFF1493).withValues(
                                    alpha: 0.6 * _glowAnimation.value,
                                  ),
                                  blurRadius: 15 + (_glowAnimation.value * 20),
                                  spreadRadius: 2 + (_glowAnimation.value * 6),
                                ),
                                // Tertiary neon glow
                                BoxShadow(
                                  color: const Color(0xFFFFB6C1).withValues(
                                    alpha: 0.4 * _glowAnimation.value,
                                  ),
                                  blurRadius: 10 + (_glowAnimation.value * 15),
                                  spreadRadius: 1 + (_glowAnimation.value * 4),
                                ),
                                // Ambient glow
                                BoxShadow(
                                  color: const Color(0xFFFF69B4).withValues(
                                    alpha: 0.2 * _glowAnimation.value,
                                  ),
                                  blurRadius: 30 + (_glowAnimation.value * 40),
                                  spreadRadius: 5 + (_glowAnimation.value * 10),
                                ),
                                // Drop shadow for depth
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
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

                    // Audio level indicator with neon styling
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      bottom: MediaQuery.of(context).size.height * 0.2,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // LISTENING text with neon effect
                              if (voiceProvider.isRecording)
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF69B4,
                                      ).withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: const Color(0xFFFF1493),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF69B4,
                                          ).withValues(alpha: 0.8),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF1493,
                                          ).withValues(alpha: 0.6),
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
                                        shadows: [
                                          Shadow(
                                            color: Color(0xFFFF1493),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (voiceProvider.isRecording)
                                const SizedBox(height: 12),

                              // Enhanced audio level indicator
                              Container(
                                width: 120,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF69B4,
                                    ).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: voiceProvider.audioLevel,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF69B4),
                                          Color(0xFFFF1493),
                                          Color(0xFFFFB6C1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF69B4,
                                          ).withValues(alpha: 0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
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
