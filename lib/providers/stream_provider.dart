import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum ConnectionStatus { disconnected, connecting, connected }

class StreamStats {
  int frameCount = 0;
  int fps = 0;
  int latency = 0;
  double videoRate = 0.0;
  double audioRate = 0.0;
}

class VideoStreamProvider extends ChangeNotifier {
  IO.Socket? _socket;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Uint8List? _currentFrame;
  final StreamStats _stats = StreamStats();

  // Stats tracking
  int _frameCounter = 0;
  int _totalVideoBytes = 0;
  int _totalAudioBytes = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  DateTime _lastDataUpdate = DateTime.now();
  DateTime _lastFrameTime = DateTime.now();

  Timer? _statsTimer;

  // Audio
  final StreamController<Uint8List> _audioStreamController =
  StreamController<Uint8List>.broadcast();

  // Getters
  ConnectionStatus get status => _status;
  Uint8List? get currentFrame => _currentFrame;
  StreamStats get stats => _stats;
  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  bool get isConnected => _status == ConnectionStatus.connected;

  // Connect to server
  void connect(String serverUrl) {
    if (_status != ConnectionStatus.disconnected) return;

    _status = ConnectionStatus.connecting;
    notifyListeners();

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('✓ Connected to server');
      _status = ConnectionStatus.connected;
      _startStatsTimer();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      debugPrint('✗ Disconnected from server');
      _status = ConnectionStatus.disconnected;
      _currentFrame = null;
      _stopStatsTimer();
      notifyListeners();
    });

    _socket!.onConnectError((data) {
      debugPrint('Connection error: $data');
      _status = ConnectionStatus.disconnected;
      notifyListeners();
    });

    // Video frames
    _socket!.on('video-frame', (data) {
      if (data is List<int>) {
        _handleVideoFrame(Uint8List.fromList(data));
      } else if (data is Uint8List) {
        _handleVideoFrame(data);
      }
    });

    // Audio data
    _socket!.on('audio-data', (data) {
      if (data is List<int>) {
        _handleAudioData(Uint8List.fromList(data));
      } else if (data is Uint8List) {
        _handleAudioData(data);
      }
    });

    _socket!.connect();
  }

  void _handleVideoFrame(Uint8List frameData) {
    _currentFrame = frameData;
    _stats.frameCount++;
    _frameCounter++;
    _totalVideoBytes += frameData.length;

    final now = DateTime.now();
    _stats.latency = now.difference(_lastFrameTime).inMilliseconds;
    _lastFrameTime = now;

    notifyListeners();
  }

  void _handleAudioData(Uint8List audioData) {
    _totalAudioBytes += audioData.length;
    _audioStreamController.add(audioData);
  }

  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();

      // Update FPS
      _stats.fps = _frameCounter;
      _frameCounter = 0;

      // Update data rates
      _stats.videoRate = _totalVideoBytes / 1024;
      _stats.audioRate = _totalAudioBytes / 1024;
      _totalVideoBytes = 0;
      _totalAudioBytes = 0;

      notifyListeners();
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _status = ConnectionStatus.disconnected;
    _currentFrame = null;
    _stopStatsTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _audioStreamController.close();
    super.dispose();
  }
}







