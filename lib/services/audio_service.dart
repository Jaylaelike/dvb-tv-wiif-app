import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  FlutterSoundPlayer? _audioPlayer;
  StreamSubscription<Uint8List>? _audioSubscription;
  bool _isMuted = false;
  bool _isInitialized = false;

  // Audio buffering
  final List<Uint8List> _audioBuffer = [];
  final int _minBufferChunks = 2; // Reduced for Android
  Timer? _bufferTimer;
  bool _isPlaying = false;

  // Statistics
  int _chunksReceived = 0;
  int _chunksSent = 0;

  Future<void> initialize(Stream<Uint8List> audioStream) async {
    if (_isInitialized) return;

    try {
      // Request audio permissions (critical for Android!)
      await _requestPermissions();

      _audioPlayer = FlutterSoundPlayer();

      // Open audio session with logging
      debugPrint('🎵 Opening audio player...');
      await _audioPlayer!.openPlayer();
      debugPrint('✓ Audio player opened');

      // Set subscription duration
      await _audioPlayer!.setSubscriptionDuration(
          const Duration(milliseconds: 50)
      );

      // Listen to audio stream with detailed logging
      _audioSubscription = audioStream.listen((chunk) {
        _chunksReceived++;
        if (_chunksReceived % 10 == 0) {
          debugPrint('📥 Received $_chunksReceived audio chunks');
        }

        if (!_isMuted && _audioPlayer != null) {
          _bufferAudioChunk(chunk);
        }
      }, onError: (error) {
        debugPrint('❌ Audio stream error: $error');
      });

      // Start player with Android-optimized settings
      await _audioPlayer!.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 2,
        sampleRate: 48000,
        bufferSize: kReleaseMode ? 32768 : 16384,  // Larger for Android
        interleaved: true,
      );

      debugPrint('🎵 Audio player started (Buffer: ${kReleaseMode ? 32768 : 16384})');

      // Start aggressive buffer processing for Android
      _startBufferProcessing();

      await _audioPlayer!.setVolume(1.0);

      _isInitialized = true;
      debugPrint('✓ Audio service initialized successfully');

      // Test audio after 2 seconds
      if (kDebugMode) {
        Future.delayed(const Duration(seconds: 2), () {
          _testAudio();
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize audio: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      debugPrint('📱 Requesting audio permissions...');

      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      debugPrint('Microphone permission: $micStatus');

      if (micStatus.isDenied) {
        debugPrint('⚠️ Microphone permission denied');
      } else if (micStatus.isPermanentlyDenied) {
        debugPrint('⚠️ Microphone permission permanently denied');
        await openAppSettings();
      } else {
        debugPrint('✓ Microphone permission granted');
      }

      // Request audio permission (Android 12+)
      if (await Permission.audio.isRestricted) {
        final audioStatus = await Permission.audio.request();
        debugPrint('Audio permission: $audioStatus');
      }
    } catch (e) {
      debugPrint('⚠️ Permission request error: $e');
    }
  }

  void _bufferAudioChunk(Uint8List chunk) {
    _audioBuffer.add(chunk);

    // Limit buffer size
    if (_audioBuffer.length > 30) {
      _audioBuffer.removeRange(0, 10);
      debugPrint('⚠️ Buffer overflow, cleared old data');
    }

    // Start playing when buffer is ready
    if (!_isPlaying && _audioBuffer.length >= _minBufferChunks) {
      _isPlaying = true;
      debugPrint('🎵 Buffer ready (${_audioBuffer.length} chunks), starting playback');
    }
  }

  void _startBufferProcessing() {
    // Aggressive processing for Android (30ms intervals)
    _bufferTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (_isPlaying && _audioBuffer.isNotEmpty && _audioPlayer != null) {
        try {
          // Send multiple chunks at once for smoother playback
          final chunksToSend = _audioBuffer.length >= 4 ? 4 : _audioBuffer.length;

          for (int i = 0; i < chunksToSend && _audioBuffer.isNotEmpty; i++) {
            final chunk = _audioBuffer.removeAt(0);
            _audioPlayer?.foodSink?.add(FoodData(chunk));
            _chunksSent++;
          }

          // Log every 100 chunks
          if (_chunksSent % 100 == 0) {
            debugPrint('📤 Sent $_chunksSent chunks (buffer: ${_audioBuffer.length})');
          }
        } catch (e) {
          debugPrint('❌ Audio feed error: $e');
        }
      }

      // Buffer health monitoring
      if (_audioBuffer.length > 20) {
        debugPrint('⚠️ Buffer high: ${_audioBuffer.length} chunks');
      } else if (_audioBuffer.length < 2 && _isPlaying) {
        debugPrint('⚠️ Buffer low: ${_audioBuffer.length} chunks');
      }
    });
  }

  // Test audio generation
  Future<void> _testAudio() async {
    if (!_isInitialized || _audioPlayer == null) return;

    debugPrint('🧪 Testing audio with 440Hz sine wave...');

    try {
      final testData = Uint8List(8192);
      for (int i = 0; i < testData.length; i += 2) {
        // Generate 440Hz sine wave (A note)
        final sample = (sin(2 * pi * 440 * i / 48000) * 32767).toInt();
        testData[i] = sample & 0xFF;
        testData[i + 1] = (sample >> 8) & 0xFF;
      }

      // Send test tone multiple times
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        _audioPlayer?.foodSink?.add(FoodData(testData));
      }

      debugPrint('🧪 Test tone sent (440Hz beep)');
    } catch (e) {
      debugPrint('❌ Test audio error: $e');
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;

    if (_audioPlayer != null && _isInitialized) {
      _audioPlayer!.setVolume(_isMuted ? 0.0 : 1.0);
    }

    if (_isMuted) {
      _audioBuffer.clear();
      _isPlaying = false;
    }

    debugPrint(_isMuted ? '🔇 Audio muted' : '🔊 Audio unmuted');
  }

  bool get isMuted => _isMuted;

  Future<void> dispose() async {
    debugPrint('🛑 Disposing audio service...');

    _bufferTimer?.cancel();
    _audioSubscription?.cancel();
    _audioBuffer.clear();

    try {
      await _audioPlayer?.stopPlayer();
      await _audioPlayer?.closePlayer();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }

    _audioPlayer = null;
    _isInitialized = false;
    _isPlaying = false;

    debugPrint('✓ Audio service disposed (Received: $_chunksReceived, Sent: $_chunksSent)');
  }
}