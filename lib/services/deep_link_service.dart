import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart';

/// Deep Link Service
///
/// Handles incoming deep links from OAuth callbacks and other external sources.
/// Listens for URLs with the scheme: interactivecoach://
class DeepLinkService {
  StreamSubscription? _sub;

  /// Callback function when Withings OAuth succeeds
  Function(String userId)? onWithingsSuccess;

  /// Callback function when Withings OAuth fails
  Function(String error)? onWithingsError;

  /// Initialize the deep link listener
  ///
  /// This should be called once in main() or in a top-level stateful widget
  Future<void> initialize() async {
    // Handle deep link when app is already running
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('❌ Deep link error: $err');
    });

    // Handle deep link when app was closed and opened via deep link
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } on PlatformException {
      print('❌ Failed to get initial URI');
    }
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    print('🔗 Deep link received: $uri');

    // Parse the deep link
    if (uri.scheme == 'interactivecoach') {
      if (uri.host == 'withings') {
        _handleWithingsCallback(uri);
      }
    }
  }

  /// Handle Withings OAuth callback
  void _handleWithingsCallback(Uri uri) {
    final path = uri.path;

    if (path == '/success') {
      // OAuth success
      final userId = uri.queryParameters['user_id'];
      if (userId != null) {
        print('✅ Withings OAuth success for user: $userId');
        onWithingsSuccess?.call(userId);
      } else {
        print('⚠️ Withings success but no user_id in callback');
      }
    } else if (path == '/error') {
      // OAuth error
      final errorMessage = uri.queryParameters['message'] ?? 'Unknown error';
      print('❌ Withings OAuth error: $errorMessage');
      onWithingsError?.call(errorMessage);
    }
  }

  /// Clean up resources
  void dispose() {
    _sub?.cancel();
  }
}
