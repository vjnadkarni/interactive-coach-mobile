import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for interacting with Apple HealthKit
/// Fetches health data from Apple Watch Series 9 and iPhone sensors
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();

  /// All health data types we want to access from Apple Watch
  static const List<HealthDataType> _healthDataTypes = [
    // Vitals
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.WALKING_HEART_RATE,
    HealthDataType.RESPIRATORY_RATE,

    // Activity
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.MOVE_MINUTES, // Stand time equivalent
    HealthDataType.DISTANCE_WALKING_RUNNING,

    // Sleep
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,

    // Fitness
    HealthDataType.WORKOUT,
    HealthDataType.HIGH_HEART_RATE_EVENT,
    HealthDataType.LOW_HEART_RATE_EVENT,
    HealthDataType.IRREGULAR_HEART_RATE_EVENT,
  ];

  /// Request permissions for all health data types
  /// Must be called before attempting to fetch data
  /// Returns true if all permissions granted
  Future<bool> requestPermissions() async {
    print('🔐 [HealthService] Requesting HealthKit permissions...');

    try {
      // Request authorization for all data types
      final bool authorized = await _health.requestAuthorization(
        _healthDataTypes,
        permissions: [
          HealthDataAccess.READ, // We only need READ access, not WRITE
        ],
      );

      if (authorized) {
        print('✅ [HealthService] HealthKit permissions granted');
      } else {
        print('❌ [HealthService] HealthKit permissions denied');
      }

      return authorized;
    } catch (e) {
      print('❌ [HealthService] Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if we have HealthKit permissions
  /// Returns true if authorized
  Future<bool> hasPermissions() async {
    try {
      // hasPermissions() method will check if authorization was granted
      final bool hasPermissions = await _health.hasPermissions(
        _healthDataTypes,
        permissions: [HealthDataAccess.READ],
      ) ?? false;

      return hasPermissions;
    } catch (e) {
      print('❌ [HealthService] Error checking permissions: $e');
      return false;
    }
  }

  /// Fetch heart rate data for a specific time range
  /// Returns list of heart rate readings (in BPM)
  Future<List<HealthDataPoint>> getHeartRateData({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    print('❤️ [HealthService] Fetching heart rate data from ${startTime.toIso8601String()} to ${endTime.toIso8601String()}');

    try {
      final List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startTime,
        endTime: endTime,
      );

      print('✅ [HealthService] Retrieved ${healthData.length} heart rate readings');
      return healthData;
    } catch (e) {
      print('❌ [HealthService] Error fetching heart rate: $e');
      return [];
    }
  }

  /// Get latest heart rate reading
  /// Returns BPM value or null if no data
  Future<double?> getLatestHeartRate() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    final data = await getHeartRateData(
      startTime: yesterday,
      endTime: now,
    );

    if (data.isEmpty) return null;

    // Sort by date descending and get most recent
    data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));

    final latestReading = data.first;
    return latestReading.value.toDouble();
  }

  /// Fetch heart rate variability (HRV) data
  /// Returns list of HRV readings (SDNN in milliseconds)
  Future<List<HealthDataPoint>> getHRVData({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    print('📊 [HealthService] Fetching HRV data from ${startTime.toIso8601String()} to ${endTime.toIso8601String()}');

    try {
      final List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
        startTime: startTime,
        endTime: endTime,
      );

      print('✅ [HealthService] Retrieved ${healthData.length} HRV readings');
      return healthData;
    } catch (e) {
      print('❌ [HealthService] Error fetching HRV: $e');
      return [];
    }
  }

  /// Get latest HRV reading
  /// Returns SDNN in milliseconds or null if no data
  Future<double?> getLatestHRV() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final data = await getHRVData(
      startTime: yesterday,
      endTime: now,
    );

    if (data.isEmpty) return null;

    // Sort by date descending and get most recent
    data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));

    final latestReading = data.first;
    return latestReading.value.toDouble();
  }

  /// Fetch blood oxygen (SpO2) data
  /// Returns list of SpO2 readings (percentage 0-100)
  Future<List<HealthDataPoint>> getSpO2Data({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    print('🫁 [HealthService] Fetching SpO2 data from ${startTime.toIso8601String()} to ${endTime.toIso8601String()}');

    try {
      final List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_OXYGEN],
        startTime: startTime,
        endTime: endTime,
      );

      print('✅ [HealthService] Retrieved ${healthData.length} SpO2 readings');
      return healthData;
    } catch (e) {
      print('❌ [HealthService] Error fetching SpO2: $e');
      return [];
    }
  }

  /// Get latest SpO2 reading
  /// Returns percentage (0-100) or null if no data
  Future<double?> getLatestSpO2() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final data = await getSpO2Data(
      startTime: yesterday,
      endTime: now,
    );

    if (data.isEmpty) return null;

    // Sort by date descending and get most recent
    data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));

    final latestReading = data.first;
    // Convert from 0-1 scale to 0-100 percentage
    return latestReading.value.toDouble() * 100;
  }

  /// Fetch step count for a specific date
  /// Returns total steps or null if no data
  Future<int?> getStepsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    print('👣 [HealthService] Fetching steps for ${date.toIso8601String()}');

    try {
      final List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      if (healthData.isEmpty) return null;

      // Sum all step readings for the day
      int totalSteps = 0;
      for (final dataPoint in healthData) {
        totalSteps += dataPoint.value.toInt();
      }

      print('✅ [HealthService] Total steps: $totalSteps');
      return totalSteps;
    } catch (e) {
      print('❌ [HealthService] Error fetching steps: $e');
      return null;
    }
  }

  /// Fetch active energy burned for a specific date
  /// Returns total calories (kcal) or null if no data
  Future<double?> getActiveEnergyForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    print('🔥 [HealthService] Fetching active energy for ${date.toIso8601String()}');

    try {
      final List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      if (healthData.isEmpty) return null;

      // Sum all energy readings for the day
      double totalEnergy = 0.0;
      for (final dataPoint in healthData) {
        totalEnergy += dataPoint.value.toDouble();
      }

      print('✅ [HealthService] Total active energy: $totalEnergy kcal');
      return totalEnergy;
    } catch (e) {
      print('❌ [HealthService] Error fetching active energy: $e');
      return null;
    }
  }

  /// Get a comprehensive daily summary of all health metrics
  /// Returns map with all available data for the specified date
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    print('📋 [HealthService] Fetching daily summary for ${date.toIso8601String()}');

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final Map<String, dynamic> summary = {
      'date': date.toIso8601String(),
      'vitals': {},
      'activity': {},
      'sleep': {},
    };

    try {
      // Fetch all health data for the day
      final List<HealthDataPoint> allData = await _health.getHealthDataFromTypes(
        types: _healthDataTypes,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      // Process vitals
      final heartRateData = allData.where((d) => d.type == HealthDataType.HEART_RATE).toList();
      if (heartRateData.isNotEmpty) {
        final avgHR = heartRateData.map((d) => d.value.toDouble()).reduce((a, b) => a + b) / heartRateData.length;
        summary['vitals']['avgHeartRate'] = avgHR.round();
        summary['vitals']['minHeartRate'] = heartRateData.map((d) => d.value.toDouble()).reduce((a, b) => a < b ? a : b).round();
        summary['vitals']['maxHeartRate'] = heartRateData.map((d) => d.value.toDouble()).reduce((a, b) => a > b ? a : b).round();
      }

      final hrvData = allData.where((d) => d.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN).toList();
      if (hrvData.isNotEmpty) {
        final avgHRV = hrvData.map((d) => d.value.toDouble()).reduce((a, b) => a + b) / hrvData.length;
        summary['vitals']['avgHRV'] = avgHRV.round();
      }

      final spo2Data = allData.where((d) => d.type == HealthDataType.BLOOD_OXYGEN).toList();
      if (spo2Data.isNotEmpty) {
        final avgSpO2 = spo2Data.map((d) => d.value.toDouble()).reduce((a, b) => a + b) / spo2Data.length;
        summary['vitals']['avgSpO2'] = (avgSpO2 * 100).round(); // Convert to percentage
      }

      // Process activity
      final stepsData = allData.where((d) => d.type == HealthDataType.STEPS).toList();
      if (stepsData.isNotEmpty) {
        summary['activity']['steps'] = stepsData.map((d) => d.value.toInt()).reduce((a, b) => a + b);
      }

      final energyData = allData.where((d) => d.type == HealthDataType.ACTIVE_ENERGY_BURNED).toList();
      if (energyData.isNotEmpty) {
        summary['activity']['activeCalories'] = energyData.map((d) => d.value.toDouble()).reduce((a, b) => a + b).round();
      }

      final exerciseData = allData.where((d) => d.type == HealthDataType.EXERCISE_TIME).toList();
      if (exerciseData.isNotEmpty) {
        summary['activity']['exerciseMinutes'] = exerciseData.map((d) => d.value.toInt()).reduce((a, b) => a + b);
      }

      print('✅ [HealthService] Daily summary complete');
      return summary;
    } catch (e) {
      print('❌ [HealthService] Error fetching daily summary: $e');
      return summary;
    }
  }

  /// Test connection to HealthKit and print sample data
  /// Useful for debugging and verification
  Future<void> testHealthKitConnection() async {
    print('🧪 [HealthService] Testing HealthKit connection...');

    // Check permissions
    final hasPerms = await hasPermissions();
    print('Permissions status: ${hasPerms ? "✅ Granted" : "❌ Not granted"}');

    if (!hasPerms) {
      print('⚠️ Requesting permissions...');
      await requestPermissions();
    }

    // Try to fetch latest readings
    print('\n--- Latest Readings ---');

    final hr = await getLatestHeartRate();
    print('Heart Rate: ${hr != null ? "$hr BPM" : "No data"}');

    final hrv = await getLatestHRV();
    print('HRV (SDNN): ${hrv != null ? "$hrv ms" : "No data"}');

    final spo2 = await getLatestSpO2();
    print('SpO2: ${spo2 != null ? "${spo2.round()}%" : "No data"}');

    final steps = await getStepsForDate(DateTime.now());
    print('Steps today: ${steps ?? "No data"}');

    final energy = await getActiveEnergyForDate(DateTime.now());
    print('Active energy today: ${energy != null ? "${energy.round()} kcal" : "No data"}');

    print('\n✅ [HealthService] Test complete');
  }
}
