import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

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
