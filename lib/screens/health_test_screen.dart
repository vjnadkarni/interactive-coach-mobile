import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../services/health_sync_service.dart';

/// Test screen for verifying HealthKit integration
/// Use this to test permissions and data fetching before building the full dashboard
class HealthTestScreen extends StatefulWidget {
  const HealthTestScreen({super.key});

  @override
  State<HealthTestScreen> createState() => _HealthTestScreenState();
}

class _HealthTestScreenState extends State<HealthTestScreen> {
  final HealthService _healthService = HealthService();
  final HealthSyncService _syncService = HealthSyncService();

  bool _isLoading = false;
  bool _isSyncing = false;
  bool _hasPermissions = false;
  String _testResults = 'Tap "Request Permissions" to begin';
  String _syncResults = 'Sync status will appear here';
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final lastSync = await _syncService.getLastSyncTimestamp();
    setState(() {
      _lastSync = lastSync;
    });
  }

  Future<void> _checkPermissions() async {
    final hasPerms = await _healthService.hasPermissions();
    setState(() {
      _hasPermissions = hasPerms;
      if (hasPerms) {
        _testResults = '✅ HealthKit permissions granted!\nTap "Test Connection" to fetch data.';
      } else {
        _testResults = '⚠️ HealthKit permissions not granted.\nTap "Request Permissions" to authorize.';
      }
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Requesting HealthKit permissions...';
    });

    final granted = await _healthService.requestPermissions();

    setState(() {
      _isLoading = false;
      _hasPermissions = granted;
      if (granted) {
        _testResults = '✅ Permissions granted successfully!\nYou can now access health data from your Apple Watch.';
      } else {
        _testResults = '❌ Permissions denied.\nPlease enable Health permissions in Settings → Health → Data Access & Devices → Interactive Coach Mobile.';
      }
    });
  }

  Future<void> _testConnection() async {
    if (!_hasPermissions) {
      setState(() {
        _testResults = '❌ No permissions. Request permissions first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults = 'Fetching health data from Apple Watch...';
    });

    try {
      final StringBuffer results = StringBuffer();
      results.writeln('=== HEALTH DATA TEST ===\n');

      // Fetch latest readings
      final hr = await _healthService.getLatestHeartRate();
      results.writeln('❤️ Heart Rate: ${hr != null ? "${hr.round()} BPM" : "No data available"}');

      final hrv = await _healthService.getLatestHRV();
      results.writeln('📊 HRV (SDNN): ${hrv != null ? "${hrv.round()} ms" : "No data available"}');

      final spo2 = await _healthService.getLatestSpO2();
      results.writeln('🫁 SpO2: ${spo2 != null ? "${spo2.round()}%" : "No data available"}');

      final steps = await _healthService.getStepsForDate(DateTime.now());
      results.writeln('👣 Steps Today: ${steps ?? "No data available"}');

      final energy = await _healthService.getActiveEnergyForDate(DateTime.now());
      results.writeln('🔥 Active Energy Today: ${energy != null ? "${energy.round()} kcal" : "No data available"}');

      results.writeln('\n--- Daily Summary ---');
      final summary = await _healthService.getDailySummary(DateTime.now());

      if (summary['vitals'].isNotEmpty) {
        results.writeln('\nVitals:');
        summary['vitals'].forEach((key, value) {
          results.writeln('  $key: $value');
        });
      }

      if (summary['activity'].isNotEmpty) {
        results.writeln('\nActivity:');
        summary['activity'].forEach((key, value) {
          results.writeln('  $key: $value');
        });
      }

      results.writeln('\n✅ Test complete!');
      results.writeln('\nIf you see "No data available" for all metrics, make sure:');
      results.writeln('• Apple Watch is paired with iPhone');
      results.writeln('• Health app is syncing');
      results.writeln('• You\'ve worn the watch recently');

      setState(() {
        _isLoading = false;
        _testResults = results.toString();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResults = '❌ Error fetching health data:\n$e\n\nMake sure HealthKit capability is enabled in Xcode.';
      });
    }
  }

  Future<void> _syncVitals() async {
    if (!_hasPermissions) {
      setState(() {
        _syncResults = '❌ No permissions. Request permissions first.';
      });
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncResults = 'Syncing vitals to backend...';
    });

    final success = await _syncService.syncVitalsToBackend();
    await _loadLastSync();

    setState(() {
      _isSyncing = false;
      _syncResults = success
          ? '✅ Vitals synced successfully!\nLast sync: ${_formatDateTime(_lastSync)}'
          : '❌ Failed to sync vitals. Check backend connection.';
    });
  }

  Future<void> _syncActivity() async {
    if (!_hasPermissions) {
      setState(() {
        _syncResults = '❌ No permissions. Request permissions first.';
      });
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncResults = 'Syncing activity to backend...';
    });

    final success = await _syncService.syncActivityToBackend();
    await _loadLastSync();

    setState(() {
      _isSyncing = false;
      _syncResults = success
          ? '✅ Activity synced successfully!\nLast sync: ${_formatDateTime(_lastSync)}'
          : '❌ Failed to sync activity. Check backend connection.';
    });
  }

  Future<void> _syncAllData() async {
    if (!_hasPermissions) {
      setState(() {
        _syncResults = '❌ No permissions. Request permissions first.';
      });
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncResults = 'Syncing all health data to backend...';
    });

    final results = await _syncService.syncAllHealthData();
    await _loadLastSync();

    final StringBuffer summary = StringBuffer();
    summary.writeln('=== SYNC RESULTS ===\n');
    summary.writeln('Vitals: ${results['vitals']! ? "✅ Success" : "❌ Failed"}');
    summary.writeln('Activity: ${results['activity']! ? "✅ Success" : "❌ Failed"}');
    summary.writeln('Sleep: ${results['sleep']! ? "✅ Success" : "❌ Failed"}');
    summary.writeln('\nLast sync: ${_formatDateTime(_lastSync)}');

    setState(() {
      _isSyncing = false;
      _syncResults = summary.toString();
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthKit Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status card
              Card(
                color: _hasPermissions ? Colors.green.shade50 : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _hasPermissions ? Icons.check_circle : Icons.warning,
                        color: _hasPermissions ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _hasPermissions ? 'HealthKit Connected' : 'HealthKit Not Connected',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: _hasPermissions ? Colors.green.shade900 : Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _requestPermissions,
                      icon: const Icon(Icons.security),
                      label: const Text('Request Permissions'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading || !_hasPermissions ? null : _testConnection,
                      icon: const Icon(Icons.science),
                      label: const Text('Test Connection'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sync section
              const Text(
                'Backend Sync',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Last sync info
              if (_lastSync != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Last sync: ${_formatDateTime(_lastSync)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),

              // Sync buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing || !_hasPermissions ? null : _syncVitals,
                      icon: const Icon(Icons.favorite, size: 18),
                      label: const Text('Sync Vitals'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing || !_hasPermissions ? null : _syncActivity,
                      icon: const Icon(Icons.directions_run, size: 18),
                      label: const Text('Sync Activity'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.orange.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing || !_hasPermissions ? null : _syncAllData,
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: const Text('Sync All'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sync results
              Card(
                color: Colors.purple.shade50,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  height: 120,
                  child: SingleChildScrollView(
                    child: _isSyncing
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Syncing...'),
                              ],
                            ),
                          )
                        : SelectableText(
                            _syncResults,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              color: Colors.purple.shade900,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Results section
              Expanded(
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: _isLoading
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Loading...'),
                                ],
                              ),
                            )
                          : SelectableText(
                              _testResults,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This screen tests HealthKit integration. Use it to verify permissions and data fetching before building the full health dashboard.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
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
    );
  }
}
