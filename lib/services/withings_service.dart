import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/body_composition.dart';

/// Withings OAuth2 and API Service
///
/// Handles:
/// - OAuth2 authorization flow
/// - Body composition measurement sync
/// - Connection status management
class WithingsService {
  final String _baseUrl;
  final SupabaseClient _supabase;

  WithingsService({String? baseUrl})
      : _baseUrl = baseUrl ?? dotenv.env['BACKEND_URL'] ?? 'http://192.168.6.234:8000',
        _supabase = Supabase.instance.client;

  /// Get JWT token from current Supabase session
  Future<String?> _getAuthToken() async {
    final session = _supabase.auth.currentSession;
    return session?.accessToken;
  }

  /// Get current user ID
  String? _getUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Check if user has connected Withings account
  ///
  /// Returns connection status and token details
  Future<Map<String, dynamic>> getConnectionStatus() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/withings/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get connection status: ${response.body}');
    }
  }

  /// Start Withings OAuth2 authorization flow
  ///
  /// Opens browser for user to authorize the app
  /// Returns the state token for verification
  Future<String> startAuthorization() async {
    final token = await _getAuthToken();
    final userId = _getUserId();

    if (token == null || userId == null) {
      throw Exception('User not authenticated');
    }

    // Request authorization URL from backend
    final response = await http.post(
      Uri.parse('$_baseUrl/api/withings/authorize'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'user_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start authorization: ${response.body}');
    }

    final data = json.decode(response.body);
    final authUrl = data['auth_url'] as String;
    final state = data['state'] as String;

    // Open browser for user to authorize
    final uri = Uri.parse(authUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch authorization URL');
    }

    return state;
  }

  /// Refresh access token
  ///
  /// Called automatically when token is about to expire
  Future<void> refreshToken() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/withings/refresh'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  /// Sync body composition measurements from Withings
  ///
  /// Fetches measurements within the specified date range
  /// If no dates provided, fetches recent measurements
  Future<List<BodyComposition>> syncMeasurements({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _getAuthToken();
    final userId = _getUserId();

    if (token == null || userId == null) {
      throw Exception('User not authenticated');
    }

    final body = <String, dynamic>{
      'user_id': userId,
    };

    if (startDate != null) {
      body['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      body['end_date'] = endDate.toIso8601String();
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/withings/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync measurements: ${response.body}');
    }

    final List<dynamic> measurements = json.decode(response.body);
    return measurements.map((m) => _parseBodyMeasurement(m)).toList();
  }

  /// Parse backend BodyMeasurement response to Flutter model
  BodyComposition _parseBodyMeasurement(Map<String, dynamic> json) {
    return BodyComposition(
      id: json['measurement_id'].toString(),
      userId: _getUserId() ?? 'unknown',
      measuredAt: DateTime.parse(json['measured_at']),
      weightKg: json['weight_kg']?.toDouble(),
      bodyFatPercent: json['body_fat_percent']?.toDouble(),
      visceralFat: null, // Withings Body Smart doesn't provide visceral fat
      waterPercent: json['water_percent']?.toDouble(),
      bmr: null, // Will calculate from weight and body composition
      metabolicAge: null, // Will calculate from BMR
      bmi: json['weight_kg'] != null ? _calculateBMI(json['weight_kg'].toDouble()) : null,
      heartRate: json['heart_rate']?.toInt(),
      source: 'withings',
      withingsMeasurementId: json['measurement_id'],
      createdAt: DateTime.now(),
    );
  }

  /// Calculate BMI from weight (requires user height)
  /// TODO: Get user height from profile
  double? _calculateBMI(double weightKg, {double heightM = 1.75}) {
    return weightKg / (heightM * heightM);
  }

  /// Disconnect Withings account
  ///
  /// Deletes stored tokens, user will need to re-authorize
  Future<void> disconnect() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/api/withings/disconnect'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to disconnect: ${response.body}');
    }
  }
}
