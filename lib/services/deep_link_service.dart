import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callback when deep link is received
  Function(String serverUrl)? onServerUrlReceived;

  /// Initialize deep link listening
  Future<void> initialize() async {
    // Handle initial link (when app is launched via deep link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('❌ Failed to get initial link: $e');
    }

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) {
        debugPrint('📱 Deep link received: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('❌ Deep link error: $err');
      },
    );
  }

  /// Parse and handle deep link
  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Processing deep link: $uri');

    String? serverUrl;

    // Handle different deep link formats:
    // 1. livestream://connect?url=http://192.168.1.100:3000
    // 2. https://stream.yourapp.com/connect?url=http://192.168.1.100:3000
    // 3. livestream://connect?server=192.168.1.100&port=3000

    if (uri.queryParameters.containsKey('url')) {
      // Direct URL parameter
      serverUrl = uri.queryParameters['url'];
      debugPrint('✓ Found server URL: $serverUrl');
    }
    else if (uri.queryParameters.containsKey('server')) {
      // Server + port format
      final server = uri.queryParameters['server'];
      final port = uri.queryParameters['port'] ?? '3000';
      final protocol = uri.queryParameters['protocol'] ?? 'http';

      if (server != null) {
        serverUrl = '$protocol://$server:$port';
        debugPrint('✓ Constructed server URL: $serverUrl');
      }
    }

    // Validate and callback
    if (serverUrl != null && _isValidUrl(serverUrl)) {
      onServerUrlReceived?.call(serverUrl);
    } else {
      debugPrint('⚠️ Invalid server URL: $serverUrl');
    }
  }

  /// Validate URL format
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Generate deep link URL for QR code
  static String generateDeepLink(String serverUrl) {
    // URL encode the server URL
    final encodedUrl = Uri.encodeComponent(serverUrl);

    // Generate deep link
    return 'livestream://connect?url=$encodedUrl';
  }

  /// Generate universal link (https) for QR code
  static String generateUniversalLink(String serverUrl) {
    final encodedUrl = Uri.encodeComponent(serverUrl);
    return 'https://stream.yourapp.com/connect?url=$encodedUrl';
  }

  /// Generate link from server IP and port
  static String generateLinkFromServerInfo({
    required String server,
    int port = 3000,
    String protocol = 'http',
  }) {
    return 'livestream://connect?server=$server&port=$port&protocol=$protocol';
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}

/// QR Code data models
class StreamQRCode {
  final String serverUrl;
  final String deepLink;
  final String universalLink;
  final DateTime generatedAt;

  StreamQRCode({
    required this.serverUrl,
  })  : deepLink = DeepLinkService.generateDeepLink(serverUrl),
        universalLink = DeepLinkService.generateUniversalLink(serverUrl),
        generatedAt = DateTime.now();

  /// Get the best link for QR code (prefers universal link)
  String get qrCodeData => universalLink;

  /// Get deep link for direct app opening
  String get appLink => deepLink;

  @override
  String toString() {
    return 'StreamQRCode(\n'
        '  serverUrl: $serverUrl\n'
        '  deepLink: $deepLink\n'
        '  universalLink: $universalLink\n'
        '  generated: $generatedAt\n'
        ')';
  }
}