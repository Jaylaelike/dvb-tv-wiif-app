import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stream_provider.dart' as stream_provider;

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<stream_provider.VideoStreamProvider>(
      builder: (context, provider, child) {
        if (provider.currentFrame == null) {
          return _buildPlaceholder();
        }

        return Image.memory(
          provider.currentFrame!,
          gaplessPlayback: true,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            size: 100,
            color: Colors.grey[800],
          ),
          const SizedBox(height: 20),
          Text(
            'Waiting for stream...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
          ),
        ],
      ),
    );
  }
}