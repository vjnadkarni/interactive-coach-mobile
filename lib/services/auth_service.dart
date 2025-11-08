/// Authentication Service
///
/// Handles user authentication using Supabase Auth.
///
/// Features:
/// - Email/password login
/// - JWT token management
/// - Session persistence
/// - Logout
/// - Authentication state listening

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys for secure storage
  static const String _tokenKey = 'supabase_jwt_token';
  static const String _userIdKey = 'supabase_user_id';

  /// Get current Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentSession != null;

  /// Get current user
  User? get currentUser => client.auth.currentUser;

  /// Get current JWT token
  Future<String?> getJwtToken() async {
    final session = client.auth.currentSession;
    if (session == null) {
      // Try to restore from secure storage
      return await _secureStorage.read(key: _tokenKey);
    }

    final token = session.accessToken;

    // Cache token in secure storage for offline access
    await _secureStorage.write(key: _tokenKey, value: token);

    return token;
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    final user = currentUser;
    if (user == null) {
      // Try to restore from secure storage
      return await _secureStorage.read(key: _userIdKey);
    }

    final userId = user.id;

    // Cache user ID in secure storage
    await _secureStorage.write(key: _userIdKey, value: userId);

    return userId;
  }

  /// Login with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login for: $email');

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        // Cache credentials in secure storage
        await _secureStorage.write(key: _tokenKey, value: response.session!.accessToken);
        await _secureStorage.write(key: _userIdKey, value: response.user!.id);

        print('✅ Login successful: ${response.user!.email}');
      }

      return response;
    } catch (e) {
      print('❌ Login failed: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> signOut() async {
    try {
      print('🔓 Logging out...');

      await client.auth.signOut();

      // Clear secure storage
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userIdKey);

      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout failed: $e');
      rethrow;
    }
  }

  /// Listen to authentication state changes
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Refresh session if needed
  Future<void> refreshSessionIfNeeded() async {
    final session = client.auth.currentSession;
    if (session == null) return;

    // Check if token is about to expire (within 5 minutes)
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt! * 1000,
    );
    final now = DateTime.now();
    final timeUntilExpiry = expiresAt.difference(now);

    if (timeUntilExpiry.inMinutes < 5) {
      print('🔄 Refreshing session token...');
      try {
        final response = await client.auth.refreshSession();
        if (response.session != null) {
          await _secureStorage.write(
            key: _tokenKey,
            value: response.session!.accessToken,
          );
          print('✅ Session refreshed successfully');
        }
      } catch (e) {
        print('❌ Failed to refresh session: $e');
      }
    }
  }

  /// Auto-login using stored credentials
  Future<bool> tryAutoLogin() async {
    try {
      // Check if we have a valid session
      final session = client.auth.currentSession;
      if (session != null) {
        print('✅ Found existing session for: ${currentUser?.email}');
        return true;
      }

      // Try to restore session from secure storage
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null) {
        print('🔄 Attempting to restore session from stored token...');
        // Supabase Flutter SDK handles session restoration automatically
        // Just check if it worked
        await Future.delayed(const Duration(milliseconds: 500));
        if (client.auth.currentSession != null) {
          print('✅ Session restored successfully');
          return true;
        }
      }

      print('ℹ️  No valid session found - user needs to login');
      return false;
    } catch (e) {
      print('❌ Auto-login failed: $e');
      return false;
    }
  }
}
