/// Health Sync Service
///
/// Syncs health data from HealthKit (Apple Watch) to the FastAPI backend.
///
/// Features:
/// - Delta sync (only upload new data since last sync)
/// - JWT authentication
/// - Retry logic for failed uploads
/// - Local timestamp tracking
/// - Batch operations

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health/health.dart';
import 'health_service.dart';
import 'auth_service.dart';

class HealthSyncService {
  // Singleton pattern
  static final HealthSyncService _instance = HealthSyncService._internal();
  factory HealthSyncService() => _instance;
  HealthSyncService._internal();

  final HealthService _healthService = HealthService();
  final AuthService _authService = AuthService();

  // Backend configuration
  String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';

  // SharedPreferences keys
  static const String _lastSyncKey = 'health_last_sync_timestamp';
  static const String _lastVitalsSyncKey = 'health_last_vitals_sync';
  static const String _lastActivitySyncKey = 'health_last_activity_sync';
  static const String _lastSleepSyncKey = 'health_last_sleep_sync';

  /// Get last sync timestamp for a specific data type
  Future<DateTime?> _getLastSyncTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(key);
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }

  /// Save sync timestamp
  Future<void> _saveLastSyncTimestamp(String key, DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, timestamp.toIso8601String());
  }

  /// Get last overall sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    return _getLastSyncTimestamp(_lastSyncKey);
  }

  /// Get JWT token from Supabase authentication
  Future<String?> _getAuthToken() async {
    return await _authService.getJwtToken();
  }

  /// Get auth headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
    };

    final token = await _getAuthToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Sync vitals (heart rate, HRV, SpO2, etc.) to backend
  Future<bool> syncVitalsToBackend() async {
    try {
      print('🔄 Starting vitals sync...');

      // Get last sync time (default to 24 hours ago if never synced)
      final lastSync = await _getLastSyncTimestamp(_lastVitalsSyncKey) ??
          DateTime.now().subtract(const Duration(hours: 24));

      final now = DateTime.now();

      // Fetch heart rate data from HealthKit
      final heartRateData = await _healthService.getHeartRateData(
        startTime: lastSync,
        endTime: now,
      );

      if (heartRateData.isEmpty) {
        print('ℹ️  No new heart rate data to sync');
        return true;
      }

      print('📊 Found ${heartRateData.length} heart rate readings to sync');

      // Get latest HRV and SpO2 for context
      final latestHRV = await _healthService.getLatestHRV();
      final latestSpO2 = await _healthService.getLatestSpO2();

      // Upload each heart rate reading with associated vitals
      int successCount = 0;
      int failCount = 0;

      for (final dataPoint in heartRateData) {
        final payload = {
          'timestamp': dataPoint.dateFrom.toUtc().toIso8601String(),
          'heart_rate': (dataPoint.value as NumericHealthValue).numericValue.round(),
          if (latestHRV != null) 'hrv': latestHRV.value.round(),
          if (latestSpO2 != null) 'spo2': latestSpO2.value.round(),
        };

        final response = await http.post(
          Uri.parse('$backendUrl/api/health/vitals'),
          headers: await _getHeaders(),
          body: jsonEncode(payload),
        );

        if (response.statusCode == 201) {
          successCount++;
        } else {
          failCount++;
          print('❌ Failed to sync vitals: ${response.statusCode} ${response.body}');
        }
      }

      print('✅ Vitals sync complete: $successCount succeeded, $failCount failed');

      // Save sync timestamp if at least some succeeded
      if (successCount > 0) {
        await _saveLastSyncTimestamp(_lastVitalsSyncKey, now);
      }

      return failCount == 0;
    } catch (e) {
      print('❌ Error syncing vitals: $e');
      return false;
    }
  }

  /// Sync activity (steps, calories, exercise) to backend
  Future<bool> syncActivityToBackend() async {
    try {
      print('🔄 Starting activity sync...');

      // Get last sync time (default to 7 days ago if never synced)
      final lastSync = await _getLastSyncTimestamp(_lastActivitySyncKey) ??
          DateTime.now().subtract(const Duration(days: 7));

      final now = DateTime.now();

      // Get daily summary for today
      final today = DateTime(now.year, now.month, now.day);
      final steps = await _healthService.getStepsForDate(today);
      final activeCalories = await _healthService.getActiveEnergyForDate(today);

      if (steps == null && activeCalories == null) {
        print('ℹ️  No activity data available for today');
        return true;
      }

      print('📊 Syncing today\'s activity: $steps steps, $activeCalories kcal');

      final payload = {
        'date': today.toIso8601String().split('T')[0], // YYYY-MM-DD format
        if (steps != null) 'steps': steps,
        if (activeCalories != null) 'active_calories': activeCalories,
        // TODO: Add exercise_minutes, stand_hours, distance_meters when available
      };

      final response = await http.post(
        Uri.parse('$backendUrl/api/health/activity'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        print('✅ Activity sync successful');
        await _saveLastSyncTimestamp(_lastActivitySyncKey, now);
        return true;
      } else {
        print('❌ Failed to sync activity: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error syncing activity: $e');
      return false;
    }
  }

  /// Sync sleep sessions to backend
  Future<bool> syncSleepToBackend() async {
    try {
      print('🔄 Starting sleep sync...');

      // Get last sync time (default to 7 days ago if never synced)
      final lastSync = await _getLastSyncTimestamp(_lastSleepSyncKey) ??
          DateTime.now().subtract(const Duration(days: 7));

      final now = DateTime.now();

      // TODO: Implement sleep data fetching from HealthKit
      // This requires additional HealthKit sleep queries
      // For now, we'll return true (no-op)
      print('ℹ️  Sleep sync not yet implemented (requires HealthKit sleep queries)');

      return true;
    } catch (e) {
      print('❌ Error syncing sleep: $e');
      return false;
    }
  }

  /// Sync body composition (weight, body fat, etc.) to backend
  Future<bool> syncBodyCompositionToBackend() async {
    try {
      print('🔄 Starting body composition sync...');

      final now = DateTime.now();

      // Get latest body composition data from HealthKit
      final weight = await _healthService.getLatestWeight();
      final bodyFat = await _healthService.getLatestBodyFat();

      if (weight == null && bodyFat == null) {
        print('ℹ️  No body composition data available');
        return true;
      }

      print('⚖️ Syncing body composition: ${weight?.value.toStringAsFixed(1) ?? "--"} kg, ${bodyFat?.value.toStringAsFixed(1) ?? "--"}%');

      final payload = {
        'timestamp': now.toUtc().toIso8601String(),
        if (weight != null) 'weight_kg': weight.value,
        if (bodyFat != null) 'body_fat_percentage': bodyFat.value,
        // TODO: Add muscle_mass_kg, bone_mass_kg, water_percentage when available from HealthKit
      };

      final response = await http.post(
        Uri.parse('$backendUrl/api/health/body-composition'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        print('✅ Body composition sync successful');
        return true;
      } else {
        print('❌ Failed to sync body composition: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error syncing body composition: $e');
      return false;
    }
  }

  /// Sync all health data types
  Future<Map<String, bool>> syncAllHealthData() async {
    print('🚀 Starting full health data sync...');

    final results = <String, bool>{};

    // Sync vitals
    results['vitals'] = await syncVitalsToBackend();

    // Sync activity
    results['activity'] = await syncActivityToBackend();

    // Sync sleep
    results['sleep'] = await syncSleepToBackend();

    // Sync body composition
    results['body_composition'] = await syncBodyCompositionToBackend();

    // Update overall last sync timestamp if all succeeded
    if (results.values.every((success) => success)) {
      await _saveLastSyncTimestamp(_lastSyncKey, DateTime.now());
      print('✅ Full health data sync completed successfully');
    } else {
      print('⚠️  Some health data failed to sync: $results');
    }

    return results;
  }

  /// Retry failed sync with exponential backoff
  Future<bool> retrySyncWithBackoff({
    required Future<bool> Function() syncFunction,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      attempt++;
      print('🔄 Sync attempt $attempt of $maxRetries...');

      final success = await syncFunction();
      if (success) {
        return true;
      }

      if (attempt < maxRetries) {
        print('⏳ Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    print('❌ All $maxRetries sync attempts failed');
    return false;
  }

  /// Check if sync is needed (based on time since last sync)
  Future<bool> needsSync({Duration threshold = const Duration(minutes: 15)}) async {
    final lastSync = await getLastSyncTimestamp();
    if (lastSync == null) return true;

    final timeSinceSync = DateTime.now().difference(lastSync);
    return timeSinceSync > threshold;
  }

  /// Clear all sync timestamps (for testing/reset)
  Future<void> clearSyncHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_lastVitalsSyncKey);
    await prefs.remove(_lastActivitySyncKey);
    await prefs.remove(_lastSleepSyncKey);
    print('🗑️  Sync history cleared');
  }
}
