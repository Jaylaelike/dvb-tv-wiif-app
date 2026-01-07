import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StreamStats {
  final bool isLive;
  final int uptime;
  final String? currentFile;

  StreamStats({
    required this.isLive,
    required this.uptime,
    this.currentFile,
  });

  factory StreamStats.fromJson(Map<String, dynamic> json) {
    return StreamStats(
      isLive: json['isLive'] ?? false,
      uptime: json['uptime'] ?? 0,
      currentFile: json['currentFile'],
    );
  }

  String formatUptime() {
    final seconds = uptime ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;

    if (hours > 0) return '${hours}h ${minutes % 60}m';
    if (minutes > 0) return '${minutes}m ${seconds % 60}s';
    return '${seconds}s';
  }
}

class SRTStreamProvider extends ChangeNotifier {
  String _serverUrl = 'http://192.168.1.100:3000';
  StreamStats _stats = StreamStats(isLive: false, uptime: 0);
  Timer? _pollTimer;
  bool _isConnected = false;

  String get serverUrl => _serverUrl;
  StreamStats get stats => _stats;
  bool get isConnected => _isConnected;
  String get hlsUrl => '$_serverUrl/hls/stream.m3u8';

  void setServerUrl(String url) {
    _serverUrl = url.trim();
    if (_serverUrl.endsWith('/')) {
      _serverUrl = _serverUrl.substring(0, _serverUrl.length - 1);
    }
    notifyListeners();
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchStats();
    });
    _fetchStats();
  }

  void stopPolling() {
    _pollTimer?.cancel();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/api/stats'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _stats = StreamStats.fromJson(data);
        _isConnected = true;
        notifyListeners();
      } else {
        _isConnected = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/api/stats'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}