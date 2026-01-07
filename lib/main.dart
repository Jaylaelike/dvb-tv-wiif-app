import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'screens/srt_stream_screen.dart';
import 'providers/srt_stream_provider.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FVP for enhanced video decoding
  // This will use hardware acceleration and optimal rendering
  fvp.registerWith(options: {
    // Enable for all platforms
    'platforms': ['windows', 'macos', 'linux', 'android', 'ios'],

    // Configure decoders (hardware first, then software fallback)
    'video.decoders': ['D3D11', 'NVDEC', 'VideoToolbox', 'MediaCodec', 'FFmpeg'],

    // Low latency mode for live streams
    'lowLatency': 1,

    // Buffer configuration for network streams
    'player': {
      'demux.buffer.ranges': '5',  // Cache 5 seconds
    }
  });

  // Initialize deep link service
  final deepLinkService = DeepLinkService();
  await deepLinkService.initialize();

  // Set fullscreen mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(MyApp(deepLinkService: deepLinkService));
}

class MyApp extends StatelessWidget {
  final DeepLinkService deepLinkService;

  const MyApp({super.key, required this.deepLinkService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SRTStreamProvider(),
      child: MaterialApp(
        title: 'SRT Live Stream',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF141414),
          primaryColor: const Color(0xFFE50914), // Netflix red
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE50914),
            secondary: Color(0xFFE50914),
          ),
        ),
        home: const SRTStreamScreen(),
      ),
    );
  }
}