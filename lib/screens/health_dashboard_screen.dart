import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/health_sync_service.dart';
import '../services/health_service.dart';
import '../services/health_observer_service.dart';
import '../services/auth_service.dart';
import '../models/body_composition.dart';
import '../widgets/body_composition_card.dart';
import 'chat_screen.dart';

/// Health Dashboard Screen
///
/// Displays LIVE health data directly from HealthKit:
/// - Latest vitals (heart rate, HRV, SpO2) from Apple Watch
/// - Activity summary (steps, calories) from iPhone/Watch
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

  // Vitals data
  int? _heartRate;
  int? _hrv;
  int? _spo2;
  DateTime? _vitalsTimestamp;

  // Activity data
  int? _steps;
  int? _activeCalories;
  DateTime? _activityDate;

  // Auto-refresh timer (temporary polling until entitlements are configured)
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startAutoRefresh();
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

      setState(() {
        _heartRate = hrReading?.value.round();
        _hrv = hrvReading?.value.round();
        _spo2 = spo2Reading?.value.round();
        // Use the actual timestamp from the heart rate reading (most frequently updated)
        _vitalsTimestamp = hrReading?.timestamp;
      });

      print('✅ Fetched vitals from HealthKit: HR=$_heartRate (at ${hrReading?.timestamp}), HRV=$_hrv (at ${hrvReading?.timestamp}), SpO2=$_spo2 (at ${spo2Reading?.timestamp})');
    } catch (e) {
      print('❌ Error fetching vitals from HealthKit: $e');
    }
  }

  Future<void> _fetchTodayActivityFromHealthKit() async {
    try {
      print('📱 Fetching activity directly from HealthKit...');

      // Request permissions if needed
      await _healthService.requestPermissions();

      final today = DateTime.now();

      // Fetch steps for today
      final steps = await _healthService.getStepsForDate(today);

      // Fetch active calories for today
      final calories = await _healthService.getActiveEnergyForDate(today);

      setState(() {
        _steps = steps;
        _activeCalories = calories?.round();
        _activityDate = today;
      });

      print('✅ Fetched activity from HealthKit: Steps=$_steps, Calories=$_activeCalories');
    } catch (e) {
      print('❌ Error fetching activity from HealthKit: $e');
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
                        BodyCompositionCard(
                          measurement: BodyComposition.mock(),
                          isLoading: false,
                        ),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User Dashboard - Coming Soon')),
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
