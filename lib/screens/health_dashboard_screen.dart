import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health/health.dart';
import '../services/health_sync_service.dart';
import '../services/health_service.dart';
import '../services/health_observer_service.dart';
import '../services/auth_service.dart';
import '../models/body_composition.dart';
import '../widgets/body_composition_card.dart';
import 'chat_screen.dart';
import 'body_composition_screen.dart';
import 'user_dashboard_screen.dart';

/// Health Dashboard Screen
///
/// Displays LIVE health data directly from HealthKit:
/// - Latest vitals (heart rate, HRV, SpO2, resting HR, walking HR, respiratory rate) from Apple Watch
/// - Activity summary (steps, calories, exercise time, distance) from iPhone/Watch
/// - Sleep data (total, deep, REM, core, awake) from Apple Watch
/// - Pull-to-refresh reads fresh data from HealthKit
/// - Background sync to backend for web dashboard
///
/// Data Flow: Apple Watch → HealthKit → iOS App Display
///            iOS App → Backend API → Web Dashboard
class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  final HealthSyncService _syncService = HealthSyncService();
  final HealthService _healthService = HealthService();
  final HealthObserverService _observerService = HealthObserverService();
  final AuthService _authService = AuthService();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';

  bool _isLoading = true;
  String _errorMessage = '';
  DateTime? _lastSync;

  // Vitals data (primary)
  int? _heartRate;
  int? _hrv;
  int? _spo2;
  DateTime? _vitalsTimestamp;

  // Vitals data (additional)
  int? _restingHeartRate;
  int? _walkingHeartRate;
  int? _respiratoryRate;

  // Activity data (primary)
  int? _steps;
  int? _activeCalories;
  DateTime? _activityDate;

  // Activity data (additional)
  int? _exerciseMinutes;
  double? _distanceMeters;

  // Sleep data
  int? _totalSleepMinutes;
  int? _deepSleepMinutes;
  int? _remSleepMinutes;
  int? _coreSleepMinutes;
  int? _awakeMinutes;
  DateTime? _sleepDate;

  // Body composition data
  BodyComposition? _latestBodyComposition;

  // Auto-refresh timer (temporary polling until entitlements are configured)
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    print('❤️ [HealthDashboard] Initializing...');

    // Wrap in try-catch to prevent crashes on standalone launch
    try {
      _loadDashboardData();
      _startAutoRefresh();
    } catch (e, stackTrace) {
      print('❌ [HealthDashboard] Error in initState: $e');
      print('Stack trace: $stackTrace');

      // Set error state instead of crashing
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// Start automatic refresh every 5 minutes
  /// TODO: Replace with observer-based updates once HealthKit entitlements are configured
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      print('🔄 Auto-refresh triggered (5-minute timer)');
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load last sync timestamp (from backend sync service)
      _lastSync = await _syncService.getLastSyncTimestamp();

      // Fetch vitals directly from HealthKit
      await _fetchLatestVitalsFromHealthKit();

      // Fetch activity directly from HealthKit
      await _fetchTodayActivityFromHealthKit();

      // Fetch sleep directly from HealthKit
      await _fetchLatestSleepFromHealthKit();

      // Fetch body composition directly from HealthKit
      await _fetchLatestBodyCompositionFromHealthKit();

      setState(() {
        _isLoading = false;
      });

      // Immediately sync fresh data to backend (for web dashboard)
      print('🔄 Auto-syncing fresh data to backend...');
      await _syncService.syncAllHealthData();
      setState(() {
        _lastSync = DateTime.now();
      });
      print('✅ Auto-sync to backend completed');

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading dashboard: $e';
      });
      print('❌ Error loading dashboard: $e');
    }
  }

  Future<void> _fetchLatestVitalsFromHealthKit() async {
    try {
      print('📱 Fetching vitals directly from HealthKit...');

      // Request permissions if needed
      await _healthService.requestPermissions();

      // Fetch latest heart rate with timestamp
      final hrReading = await _healthService.getLatestHeartRate();

      // Fetch latest HRV with timestamp
      final hrvReading = await _healthService.getLatestHRV();

      // Fetch latest SpO2 with timestamp
      final spo2Reading = await _healthService.getLatestSpO2();

      // Fetch additional vitals
      final restingHRReading = await _getLatestRestingHeartRate();
      final walkingHRReading = await _getLatestWalkingHeartRate();
      final respiratoryReading = await _getLatestRespiratoryRate();

      setState(() {
        _heartRate = hrReading?.value.round();
        _hrv = hrvReading?.value.round();
        _spo2 = spo2Reading?.value.round();
        _restingHeartRate = restingHRReading?.value.round();
        _walkingHeartRate = walkingHRReading?.value.round();
        _respiratoryRate = respiratoryReading?.value.round();
        // Use the actual timestamp from the heart rate reading (most frequently updated)
        _vitalsTimestamp = hrReading?.timestamp;
      });

      print('✅ Fetched vitals from HealthKit: HR=$_heartRate, HRV=$_hrv, SpO2=$_spo2, RestingHR=$_restingHeartRate, WalkingHR=$_walkingHeartRate, RespRate=$_respiratoryRate');
    } catch (e) {
      print('❌ Error fetching vitals from HealthKit: $e');
    }
  }

  Future<VitalReading?> _getLatestRestingHeartRate() async {
    try {
      final now = DateTime.now();
      final data = await _healthService.health.getHealthDataFromTypes(
        types: [HealthDataType.RESTING_HEART_RATE],
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = (data.first.value as NumericHealthValue).numericValue.toDouble();
      return VitalReading(value: value, timestamp: data.first.dateFrom);
    } catch (e) {
      print('❌ Error fetching resting HR: $e');
      return null;
    }
  }

  Future<VitalReading?> _getLatestWalkingHeartRate() async {
    try {
      final now = DateTime.now();
      final data = await _healthService.health.getHealthDataFromTypes(
        types: [HealthDataType.WALKING_HEART_RATE],
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = (data.first.value as NumericHealthValue).numericValue.toDouble();
      return VitalReading(value: value, timestamp: data.first.dateFrom);
    } catch (e) {
      print('❌ Error fetching walking HR: $e');
      return null;
    }
  }

  Future<VitalReading?> _getLatestRespiratoryRate() async {
    try {
      final now = DateTime.now();
      final data = await _healthService.health.getHealthDataFromTypes(
        types: [HealthDataType.RESPIRATORY_RATE],
        startTime: now.subtract(const Duration(days: 1)),
        endTime: now,
      );
      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final value = (data.first.value as NumericHealthValue).numericValue.toDouble();
      return VitalReading(value: value, timestamp: data.first.dateFrom);
    } catch (e) {
      print('❌ Error fetching respiratory rate: $e');
      return null;
    }
  }

  Future<void> _fetchTodayActivityFromHealthKit() async {
    try {
      print('📱 Fetching activity directly from HealthKit...');

      // Request permissions if needed
      await _healthService.requestPermissions();

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Fetch steps for today
      final steps = await _healthService.getStepsForDate(today);

      // Fetch active calories for today
      final calories = await _healthService.getActiveEnergyForDate(today);

      // Fetch exercise minutes for today
      final exerciseData = await _healthService.health.getHealthDataFromTypes(
        types: [HealthDataType.EXERCISE_TIME],
        startTime: startOfDay,
        endTime: endOfDay,
      );
      int? exerciseMinutes;
      if (exerciseData.isNotEmpty) {
        exerciseMinutes = exerciseData.map((d) => (d.value as NumericHealthValue).numericValue.toInt()).reduce((a, b) => a + b);
      }

      // Fetch distance for today
      final distanceData = await _healthService.health.getHealthDataFromTypes(
        types: [HealthDataType.DISTANCE_WALKING_RUNNING],
        startTime: startOfDay,
        endTime: endOfDay,
      );
      double? distance;
      if (distanceData.isNotEmpty) {
        distance = distanceData.map((d) => (d.value as NumericHealthValue).numericValue.toDouble()).reduce((a, b) => a + b);
      }

      setState(() {
        _steps = steps;
        _activeCalories = calories?.round();
        _exerciseMinutes = exerciseMinutes;
        _distanceMeters = distance;
        _activityDate = today;
      });

      print('✅ Fetched activity from HealthKit: Steps=$_steps, Calories=$_activeCalories, Exercise=$_exerciseMinutes min, Distance=$_distanceMeters m');
    } catch (e) {
      print('❌ Error fetching activity from HealthKit: $e');
    }
  }

  Future<void> _fetchLatestSleepFromHealthKit() async {
    try {
      print('😴 Fetching sleep data directly from HealthKit...');

      // Request permissions if needed
      await _healthService.requestPermissions();

      final now = DateTime.now();
      // Look back 24 hours for most recent sleep session
      final yesterday = now.subtract(const Duration(hours: 24));

      // Fetch all sleep data types
      final sleepData = await _healthService.health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_IN_BED,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
        ],
        startTime: yesterday,
        endTime: now,
      );

      if (sleepData.isEmpty) {
        print('⚠️ No sleep data found in HealthKit');
        return;
      }

      // Calculate sleep metrics
      int totalAsleep = 0;
      int awake = 0;
      int deep = 0;
      int rem = 0;
      int core = 0;

      for (final dataPoint in sleepData) {
        // Duration in minutes
        final duration = dataPoint.dateTo.difference(dataPoint.dateFrom).inMinutes;

        switch (dataPoint.type) {
          case HealthDataType.SLEEP_ASLEEP:
            totalAsleep += duration;
            // If we have SLEEP_ASLEEP without breakdown, treat as core sleep
            if (sleepData.where((d) => d.type == HealthDataType.SLEEP_DEEP || d.type == HealthDataType.SLEEP_REM).isEmpty) {
              core += duration;
            }
            break;
          case HealthDataType.SLEEP_AWAKE:
            awake += duration;
            break;
          case HealthDataType.SLEEP_DEEP:
            deep += duration;
            break;
          case HealthDataType.SLEEP_REM:
            rem += duration;
            break;
          case HealthDataType.SLEEP_IN_BED:
            // SLEEP_IN_BED includes everything, we'll use individual breakdowns
            break;
          default:
            break;
        }
      }

      // If we have deep and REM, calculate core as the remainder
      if (deep > 0 || rem > 0) {
        core = totalAsleep - deep - rem;
        if (core < 0) core = 0;
      }

      setState(() {
        _totalSleepMinutes = totalAsleep;
        _deepSleepMinutes = deep;
        _remSleepMinutes = rem;
        _coreSleepMinutes = core;
        _awakeMinutes = awake;
        _sleepDate = now;
      });

      print('✅ Fetched sleep from HealthKit: Total=$_totalSleepMinutes min, Deep=$_deepSleepMinutes, REM=$_remSleepMinutes, Core=$_coreSleepMinutes, Awake=$_awakeMinutes');
    } catch (e) {
      print('❌ Error fetching sleep from HealthKit: $e');
    }
  }

  Future<void> _fetchLatestBodyCompositionFromHealthKit() async {
    try {
      print('⚖️ Fetching body composition directly from HealthKit...');

      // Request permissions if needed
      await _healthService.requestPermissions();

      final weight = await _healthService.getLatestWeight();
      final bodyFat = await _healthService.getLatestBodyFat();
      final bmi = await _healthService.getLatestBMI();
      final leanMass = await _healthService.getLatestLeanBodyMass();

      if (weight != null) {
        // HealthKit returns weight in kg (no conversion needed)
        final weightInKg = weight.value;

        setState(() {
          _latestBodyComposition = BodyComposition(
            id: 'healthkit-${DateTime.now().millisecondsSinceEpoch}',
            userId: 'current-user',
            weightKg: weightInKg,
            bodyFatPercent: bodyFat?.value,
            bmi: bmi?.value,
            measuredAt: weight.timestamp,
            source: 'healthkit',
            createdAt: DateTime.now(),
          );
        });

        print('✅ Fetched body composition from HealthKit: Weight=$weightInKg kg, Body Fat=${bodyFat?.value}%');
      } else {
        print('⚠️ No body composition data found in HealthKit');
      }
    } catch (e) {
      print('❌ Error fetching body composition from HealthKit: $e');
    }
  }

  Future<void> _handleRefresh() async {
    print('🔄 Pull-to-refresh triggered - reading fresh data from HealthKit');

    // Reload data from HealthKit and auto-sync to backend
    // (backend sync happens automatically in _loadDashboardData)
    await _loadDashboardData();
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '--';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '--';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }

  /// Get freshness indicator color based on data age
  /// Green: < 5 minutes, Amber: 5-30 minutes, Red: > 30 minutes
  Color _getFreshnessColor(DateTime? timestamp) {
    if (timestamp == null) return Colors.grey;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 5) {
      return Colors.green.shade600; // Fresh data
    } else if (difference.inMinutes < 30) {
      return Colors.amber.shade700; // Aging data
    } else {
      return Colors.grey.shade600; // Stale data
    }
  }

  /// Get freshness indicator icon based on data age
  IconData _getFreshnessIcon(DateTime? timestamp) {
    if (timestamp == null) return Icons.help_outline;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 5) {
      return Icons.check_circle; // Fresh data
    } else if (difference.inMinutes < 30) {
      return Icons.warning_amber_rounded; // Aging data
    } else {
      return Icons.access_time; // Stale data
    }
  }

  void _showVitalsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red.shade400, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'All Vitals',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildVitalRow('Heart Rate', _heartRate != null ? '$_heartRate BPM' : '--', Icons.favorite, Colors.red),
                    _buildVitalRow('HRV (SDNN)', _hrv != null ? '$_hrv ms' : '--', Icons.show_chart, Colors.purple),
                    _buildVitalRow('SpO2', _spo2 != null ? '$_spo2%' : '--', Icons.air, Colors.blue),
                    _buildVitalRow('Resting HR', _restingHeartRate != null ? '$_restingHeartRate BPM' : '--', Icons.nightlight_round, Colors.indigo),
                    _buildVitalRow('Walking HR', _walkingHeartRate != null ? '$_walkingHeartRate BPM' : '--', Icons.directions_walk, Colors.orange),
                    _buildVitalRow('Respiratory Rate', _respiratoryRate != null ? '$_respiratoryRate /min' : '--', Icons.waves, Colors.teal),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.directions_run, color: Colors.orange.shade400, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'All Activity',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildVitalRow('Steps', _steps != null ? '$_steps' : '--', Icons.directions_walk, Colors.green),
                    _buildVitalRow('Active Calories', _activeCalories != null ? '$_activeCalories kcal' : '--', Icons.local_fire_department, Colors.orange),
                    _buildVitalRow('Exercise Time', _formatDuration(_exerciseMinutes), Icons.timer, Colors.red),
                    _buildVitalRow('Distance', _formatDistance(_distanceMeters), Icons.straighten, Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.bedtime, color: Colors.indigo.shade400, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Sleep Details',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildVitalRow('Total Sleep', _formatDuration(_totalSleepMinutes), Icons.bedtime, Colors.indigo),
                    _buildVitalRow('Deep Sleep', _formatDuration(_deepSleepMinutes), Icons.nights_stay, Colors.deepPurple),
                    _buildVitalRow('REM Sleep', _formatDuration(_remSleepMinutes), Icons.remove_red_eye, Colors.purple),
                    _buildVitalRow('Core Sleep', _formatDuration(_coreSleepMinutes), Icons.dark_mode, Colors.blue),
                    _buildVitalRow('Awake', _formatDuration(_awakeMinutes), Icons.wb_sunny, Colors.amber),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Last sync indicator
          if (_lastSync != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Synced ${_formatTimestamp(_lastSync)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboardData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Vitals Card
                        _buildVitalsCard(),
                        const SizedBox(height: 16),

                        // Activity Card
                        _buildActivityCard(),
                        const SizedBox(height: 16),

                        // Body Composition Card (third card - below Vitals and Activity)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BodyCompositionScreen(),
                              ),
                            );
                          },
                          child: BodyCompositionCard(
                            measurement: _latestBodyComposition ?? BodyComposition.mock(),
                            isLoading: _isLoading && _latestBodyComposition == null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sleep Card (fourth card - after Body Composition)
                        _buildSleepCard(),
                        const SizedBox(height: 16),

                        // Info Card
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Data auto-refreshes every 5 minutes. Pull down to refresh manually.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Health tab selected
        onTap: (index) {
          if (index == 1) {
            // Navigate to Chat Screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          } else if (index == 2) {
            // Navigate to User Dashboard
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const UserDashboardScreen()),
            );
          }
          // index == 0 is current screen (Health), do nothing
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red.shade400, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Vitals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_vitalsTimestamp != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFreshnessIcon(_vitalsTimestamp),
                        size: 16,
                        color: _getFreshnessColor(_vitalsTimestamp),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(_vitalsTimestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getFreshnessColor(_vitalsTimestamp),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalMetric(
                  icon: Icons.favorite,
                  label: 'Heart Rate',
                  value: _heartRate != null ? '$_heartRate' : '--',
                  unit: 'BPM',
                  color: Colors.red,
                ),
                _buildVitalMetric(
                  icon: Icons.show_chart,
                  label: 'HRV',
                  value: _hrv != null ? '$_hrv' : '--',
                  unit: 'ms',
                  color: Colors.purple,
                ),
                _buildVitalMetric(
                  icon: Icons.air,
                  label: 'SpO2',
                  value: _spo2 != null ? '$_spo2' : '--',
                  unit: '%',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showVitalsModal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'See more...',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.blue.shade600, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_run, color: Colors.orange.shade400, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_activityDate != null)
                  Text(
                    'Today',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActivityMetric(
                  icon: Icons.directions_walk,
                  label: 'Steps',
                  value: _steps != null ? _steps.toString() : '--',
                  color: Colors.green,
                ),
                _buildActivityMetric(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: _activeCalories != null ? '$_activeCalories kcal' : '--',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showActivityModal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'See more...',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.blue.shade600, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: Colors.indigo.shade400, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Sleep',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_sleepDate != null)
                  Text(
                    'Last night',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActivityMetric(
                  icon: Icons.bedtime,
                  label: 'Total',
                  value: _formatDuration(_totalSleepMinutes),
                  color: Colors.indigo,
                ),
                _buildActivityMetric(
                  icon: Icons.nights_stay,
                  label: 'Deep',
                  value: _formatDuration(_deepSleepMinutes),
                  color: Colors.deepPurple,
                ),
                _buildActivityMetric(
                  icon: Icons.remove_red_eye,
                  label: 'REM',
                  value: _formatDuration(_remSleepMinutes),
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showSleepModal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'See more...',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.blue.shade600, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalMetric({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildActivityMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
