import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/srt_stream_provider.dart';
import '../widgets/connection_dialog.dart';
import 'video_player_screen.dart';

class SRTStreamScreen extends StatefulWidget {
  const SRTStreamScreen({super.key});

  @override
  State<SRTStreamScreen> createState() => _SRTStreamScreenState();
}

class _SRTStreamScreenState extends State<SRTStreamScreen> {
  bool _shouldShowDialog = true;

  @override
  void initState() {
    super.initState();

    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    // Enable wakelock
    WakelockPlus.enable();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldShowDialog) {
        _showConnectionDialog();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we should show dialog when coming back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldShowDialog && mounted) {
        _showConnectionDialog();
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _showConnectionDialog() {
    // Prevent multiple dialogs
    if (!mounted) return;

    // Check if dialog is already showing
    if (ModalRoute.of(context)?.isCurrent == false) return;

    setState(() {
      _shouldShowDialog = false;
    });

    // Small delay to ensure screen is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ConnectionDialog(
          onConnect: (url) async {
            final provider = context.read<SRTStreamProvider>();
            provider.setServerUrl(url);

            Navigator.pop(ctx);

            // Show connecting dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(
                child: Card(
                  color: Color(0xFF2a2a2a),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Connecting to server...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            // Test connection
            final success = await provider.testConnection();

            if (mounted) {
              Navigator.pop(context);

              if (success) {
                // Start polling
                provider.startPolling();

                // Show success and go directly to video player
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

                // Navigate to video player immediately
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VideoPlayerScreen(),
                      ),
                    );
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text('Failed to connect to server'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );

                // Show dialog again
                setState(() {
                  _shouldShowDialog = true;
                });
                _showConnectionDialog();
              }
            }
          },
        ),
      ).then((_) {
        // Dialog dismissed, allow showing again
        if (mounted) {
          setState(() {
            _shouldShowDialog = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'SRT Live Stream',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ready to connect',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}