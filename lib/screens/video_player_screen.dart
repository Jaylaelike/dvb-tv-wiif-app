import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/srt_stream_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Keep screen on
    WakelockPlus.enable();

    _initializePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    WakelockPlus.disable();

    // Restore orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      final provider = Provider.of<SRTStreamProvider>(context, listen: false);
      final hlsUrl = provider.hlsUrl;

      debugPrint('🎥 Loading HLS stream: $hlsUrl');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(hlsUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller!.initialize();

      // Set volume
      await _controller!.setVolume(1.0);

      // Start playing
      await _controller!.play();

      // Listen to player state
      _controller!.addListener(_onPlayerStateChanged);

      setState(() {
        _isLoading = false;
        _hasError = false;
      });

      debugPrint('✅ Video player initialized successfully');
    } catch (e) {
      debugPrint('❌ Video player error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onPlayerStateChanged() {
    if (_controller == null || !mounted) return;

    // Check for errors
    if (_controller!.value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = _controller!.value.errorDescription ?? 'Unknown error';
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null) return;

    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _reload() {
    _controller?.dispose();
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    _initializePlayer();
  }

  void _disconnect() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        title: const Text(
          'Disconnect?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to disconnect and return to connection screen?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _performDisconnect();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _performDisconnect() {
    debugPrint('🔙 Performing disconnect...');

    // Stop polling
    final provider = Provider.of<SRTStreamProvider>(context, listen: false);
    provider.stopPolling();
    debugPrint('✓ Stopped polling');

    // Dispose controller
    _controller?.dispose();
    debugPrint('✓ Disposed video controller');

    // Pop back to main screen
    // This will trigger the connection dialog to show again
    Navigator.of(context).pop();
    debugPrint('✓ Navigated back to main screen');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _disconnect();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
          },
          child: Stack(
            children: [
              // Video player
              Center(
                child: _buildVideoPlayer(),
              ),

              // Controls overlay
              if (_showControls)
                _buildControlsOverlay(),

              // Loading indicator
              if (_isLoading)
                _buildLoadingOverlay(),

              // Error overlay
              if (_hasError)
                _buildErrorOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller != null && _controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.videocam_off,
          size: 100,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading stream...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Consumer<SRTStreamProvider>(
              builder: (context, provider, _) {
                return Text(
                  provider.stats.isLive ? 'Stream is LIVE' : 'Waiting for stream...',
                  style: TextStyle(
                    color: provider.stats.isLive ? Colors.green : Colors.grey,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Playback Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Consumer<SRTStreamProvider>(
                builder: (context, provider, _) {
                  if (!provider.stats.isLive) {
                    return const Text(
                      'Stream is offline. Start streaming from OBS or FFmpeg.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 30),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 15,
                runSpacing: 15,
                children: [
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Change Server'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0, 0.2, 0.8, 1],
        ),
      ),
      child: Stack(
        children: [
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      color: Colors.white,
                      onPressed: _disconnect,
                      tooltip: 'Disconnect',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Stream',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Consumer<SRTStreamProvider>(
                            builder: (context, provider, _) {
                              if (provider.stats.isLive) {
                                return const Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: Color(0xFFE50914),
                                      size: 12,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return const Row(
                                  children: [
                                    Icon(
                                      Icons.circle_outlined,
                                      color: Colors.grey,
                                      size: 12,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'OFFLINE',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        size: 28,
                      ),
                      color: Colors.white,
                      onPressed: _toggleMute,
                      tooltip: _isMuted ? 'Unmute' : 'Mute',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center play/pause
          Center(
            child: IconButton(
              icon: Icon(
                _controller?.value.isPlaying == true
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 80,
              ),
              color: Colors.white.withOpacity(0.8),
              onPressed: _togglePlayPause,
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Server info
                    Consumer<SRTStreamProvider>(
                      builder: (context, provider, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.dns,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _extractHost(provider.serverUrl),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              if (provider.stats.isLive) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    provider.stats.formatUptime(),
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 28),
                          color: Colors.white,
                          onPressed: _reload,
                          tooltip: 'Reload',
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: Icon(
                            _controller?.value.isPlaying == true
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 32,
                          ),
                          color: Colors.white,
                          onPressed: _togglePlayPause,
                          tooltip: _controller?.value.isPlaying == true
                              ? 'Pause'
                              : 'Play',
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.fullscreen, size: 28),
                          color: Colors.white,
                          onPressed: () {
                            // Already in fullscreen
                          },
                          tooltip: 'Fullscreen',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractHost(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host + (uri.port != 80 && uri.port != 443 ? ':${uri.port}' : '');
    } catch (e) {
      return url;
    }
  }
}