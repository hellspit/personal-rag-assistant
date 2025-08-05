import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'stt_provider.dart';

class VoiceProvider extends ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  double _audioLevel = 0.0;
  Timer? _levelTimer;
  bool _isMonitoring = false;
  STTProvider? _sttProvider;
  DateTime? _lastAudioSend;

  bool get isRecording => _isRecording;
  double get audioLevel => _audioLevel;

  // Method to set STT provider for integration
  void setSTTProvider(STTProvider sttProvider) {
    _sttProvider = sttProvider;
  }

  Future<void> requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> startContinuousMonitoring() async {
    if (await _audioRecorder.hasPermission() && !_isMonitoring) {
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/ambient_audio.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 32000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: audioPath,
      );
      _isMonitoring = true;
      _startRealTimeAudioMonitoring();
      notifyListeners();
    }
  }

  Future<void> stopContinuousMonitoring() async {
    if (_isMonitoring) {
      _isMonitoring = false;
      _stopRealTimeAudioMonitoring();
      await _audioRecorder.stop();
      notifyListeners();
    }
  }

  Future<void> resetAudioSession() async {
    if (_isMonitoring) {
      // Stop current recording
      await _audioRecorder.stop();

      // Start fresh recording with new file
      final tempDir = await getTemporaryDirectory();
      final audioPath =
          '${tempDir.path}/ambient_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 32000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: audioPath,
      );

      print('DEBUG: Audio session reset with new file: $audioPath');
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
          _audioLevel =
              (_audioLevel * 0.2) + (normalizedLevel * 0.8); // More responsive

          // Notify STT provider about audio level changes
          _sttProvider?.onAudioLevelChanged(_audioLevel);

          // Send audio data to STT when there's significant audio (more frequently)
          // Only send if STT provider is listening and hasn't transcribed a line yet
          if (normalizedLevel >
                  0.05 && // Lower threshold for more sensitive detection
              _sttProvider != null &&
              _sttProvider!.isListening &&
              !_sttProvider!.hasTranscribedLine) {
            final now = DateTime.now();
            if (_lastAudioSend == null ||
                now.difference(_lastAudioSend!).inMilliseconds > 500) {
              // Send every 500ms instead of 1 second
              print(
                'DEBUG: Sending audio data to STT - level: $normalizedLevel, isListening: ${_sttProvider!.isListening}, hasTranscribedLine: ${_sttProvider!.hasTranscribedLine}',
              );
              _captureAndSendAudio();
              _lastAudioSend = now;
            }
          }

          notifyListeners();
        } catch (error) {
          // Silent error handling
        }
      }
    });
  }

  Future<void> _captureAndSendAudio() async {
    try {
      // Get the current audio file path
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/ambient_audio.wav';

      // Read the audio file
      final audioFile = File(audioPath);
      if (await audioFile.exists()) {
        final audioData = await audioFile.readAsBytes();

        // Send to STT provider for processing
        await _sttProvider?.processAudioData(audioData);
      }
    } catch (e) {
      // Silent error handling
    }
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
