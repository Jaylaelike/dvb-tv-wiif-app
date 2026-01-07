import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioServiceAlternative {
  static const platform = MethodChannel('audio_player');
  StreamSubscription<Uint8List>? _audioSubscription;
  bool _isMuted = false;
  bool _isInitialized = false;

  Future<void> initialize(Stream<Uint8List> audioStream) async {
    if (_isInitialized) return;

    try {
      // Initialize native audio player
      await platform.invokeMethod('initialize', {
        'sampleRate': 48000,
        'channels': 2,
        'encoding': 'pcm16',
      });

      // Listen to audio stream
      _audioSubscription = audioStream.listen((chunk) {
        if (!_isMuted) {
          _playAudioChunk(chunk);
        }
      });

      _isInitialized = true;
      debugPrint('✓ Native audio initialized');
    } catch (e) {
      debugPrint('❌ Native audio error: $e');
    }
  }

  Future<void> _playAudioChunk(Uint8List data) async {
    try {
      await platform.invokeMethod('playAudio', data);
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  Future<void> dispose() async {
    _audioSubscription?.cancel();
    try {
      await platform.invokeMethod('dispose');
    } catch (e) {}
    _isInitialized = false;
  }
}