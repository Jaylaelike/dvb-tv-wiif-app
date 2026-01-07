import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stream_provider.dart' as stream_provider;
import '../widgets/video_player_widget.dart';
import '../widgets/controls_overlay.dart';
import '../widgets/connection_dialog.dart';
import '../services/audio_service.dart';
import '../services/deep_link_service.dart';

class StreamScreen extends StatefulWidget {
  final DeepLinkService deepLinkService;

  const StreamScreen({super.key, required this.deepLinkService});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  bool _showControls = true;
  Timer? _hideTimer;
  AudioService? _audioService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();

    // Setup deep link callback
    widget.deepLinkService.onServerUrlReceived = _handleDeepLinkUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showConnectionDialog();
    });

    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _audioService?.dispose();
    super.dispose();
  }

  /// Handle deep link URL
  void _handleDeepLinkUrl(String serverUrl) {
    debugPrint('🔗 Connecting via deep link: $serverUrl');

    // Close connection dialog if open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Show connecting snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Connecting to $serverUrl...'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE50914),
        duration: const Duration(seconds: 3),
      ),
    );

    // Connect to server
    final provider = context.read<stream_provider.VideoStreamProvider>();
    _connectToServer(provider, serverUrl);
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConnectionDialog(
        onConnect: (url) {
          final provider = context.read<stream_provider.VideoStreamProvider>();
          _connectToServer(provider, url);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _connectToServer(stream_provider.VideoStreamProvider provider, String url) {
    provider.connect(url);

    // Initialize audio when connected (only once)
    if (!_isInitialized) {
      provider.addListener(() {
        if (provider.isConnected && _audioService != null && !_isInitialized) {
          _audioService!.initialize(provider.audioStream);
          _isInitialized = true;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 16),
                  Text('Connected successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideTimer();
      }
    });
  }

  void _toggleAudio() {
    _audioService?.toggleMute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _toggleControls,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Video player
              const Center(child: VideoPlayerWidget()),

              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: ControlsOverlay(
                  onBack: () {
                    final provider = context.read<stream_provider.VideoStreamProvider>();
                    provider.disconnect();
                    _isInitialized = false;
                    _showConnectionDialog();
                  },
                  onToggleAudio: _toggleAudio,
                ),
              ),

              // Connection status indicator
              Positioned(
                top: 50,
                right: 20,
                child: Consumer<stream_provider.VideoStreamProvider>(
                  builder: (ctx, provider, _) {
                    if (provider.status == stream_provider.ConnectionStatus.connecting) {
                      return _buildStatusBadge(
                        '🔄 Connecting...',
                        Colors.orange,
                      );
                    } else if (provider.status == stream_provider.ConnectionStatus.disconnected) {
                      return _buildStatusBadge(
                        '🔴 Disconnected',
                        Colors.red,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Stats overlay (only when controls visible)
              if (_showControls)
                Positioned(
                  bottom: 100,
                  left: 20,
                  child: Consumer<stream_provider.VideoStreamProvider>(
                    builder: (ctx, provider, _) {
                      if (!provider.isConnected) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatRow('FPS', '${provider.stats.fps}'),
                            _buildStatRow('Latency', '${provider.stats.latency}ms'),
                            _buildStatRow('Frames', '${provider.stats.frameCount}'),
                            _buildStatRow('Video', '${provider.stats.videoRate.toStringAsFixed(1)} KB/s'),
                            _buildStatRow('Audio', '${provider.stats.audioRate.toStringAsFixed(1)} KB/s'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}