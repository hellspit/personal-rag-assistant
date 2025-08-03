import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_provider.dart';
import '../theme/app_theme.dart';

class VoiceCircle extends StatefulWidget {
  const VoiceCircle({super.key});

  @override
  State<VoiceCircle> createState() => _VoiceCircleState();
}

class _VoiceCircleState extends State<VoiceCircle>
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

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _updateAnimations(double audioIntensity) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceProvider>(
      builder: (context, voiceProvider, child) {
        // Update animations based on current audio level
        double audioIntensity = voiceProvider.audioLevel.clamp(0.0, 1.0);
        _updateAnimations(audioIntensity);

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
                          AppTheme.primaryRed.withValues(
                            alpha: 0.08 + (_ambientAnimation.value * 0.05),
                          ),
                          AppTheme.darkRed.withValues(
                            alpha: 0.05 + (_ambientAnimation.value * 0.03),
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
                            AppTheme.primaryRed.withValues(
                              alpha: _glowAnimation.value * 0.4,
                            ),
                            AppTheme.darkRed.withValues(
                              alpha: _glowAnimation.value * 0.3,
                            ),
                            AppTheme.crimsonRed.withValues(
                              alpha: _glowAnimation.value * 0.2,
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
                              AppTheme.primaryRed.withValues(alpha: 0.6),
                              AppTheme.darkRed.withValues(alpha: 0.4),
                              const Color(0xFF000000).withValues(alpha: 0.9),
                              const Color(0xFF000000).withValues(alpha: 0.95),
                            ],
                            stops: const [0.0, 0.3, 0.8, 1.0],
                          ),
                          boxShadow: _buildNeonShadows(),
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
              ],
            );
          },
        );
      },
    );
  }

  List<BoxShadow> _buildNeonShadows() {
    return [
      // Primary neon glow - much brighter and larger
      BoxShadow(
        color: AppTheme.primaryRed.withValues(
          alpha: 1.0 * _glowAnimation.value,
        ),
        blurRadius: 40 + (_glowAnimation.value * 60),
        spreadRadius: 8 + (_glowAnimation.value * 20),
      ),
      // Secondary neon glow - enhanced
      BoxShadow(
        color: AppTheme.primaryRed.withValues(
          alpha: 0.8 * _glowAnimation.value,
        ),
        blurRadius: 30 + (_glowAnimation.value * 45),
        spreadRadius: 5 + (_glowAnimation.value * 15),
      ),
      // Tertiary neon glow - more intense
      BoxShadow(
        color: AppTheme.darkRed.withValues(alpha: 0.7 * _glowAnimation.value),
        blurRadius: 25 + (_glowAnimation.value * 35),
        spreadRadius: 3 + (_glowAnimation.value * 12),
      ),
      // Fourth neon glow layer
      BoxShadow(
        color: AppTheme.crimsonRed.withValues(
          alpha: 0.6 * _glowAnimation.value,
        ),
        blurRadius: 20 + (_glowAnimation.value * 30),
        spreadRadius: 2 + (_glowAnimation.value * 10),
      ),
      // Ambient glow - much larger and brighter
      BoxShadow(
        color: AppTheme.primaryRed.withValues(
          alpha: 0.4 * _glowAnimation.value,
        ),
        blurRadius: 60 + (_glowAnimation.value * 80),
        spreadRadius: 10 + (_glowAnimation.value * 25),
      ),
      // Extra wide ambient glow
      BoxShadow(
        color: AppTheme.primaryRed.withValues(
          alpha: 0.2 * _glowAnimation.value,
        ),
        blurRadius: 100 + (_glowAnimation.value * 120),
        spreadRadius: 15 + (_glowAnimation.value * 35),
      ),
      // Drop shadow for depth
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.6),
        blurRadius: 15,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
