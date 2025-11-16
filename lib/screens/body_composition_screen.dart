import 'package:flutter/material.dart';
import '../models/body_composition.dart';
import '../services/withings_service.dart';
import '../widgets/connect_withings_button.dart';
import '../widgets/body_composition_card.dart';
import 'body_composition_detail_screen.dart';

/// Body Composition Screen
///
/// Displays body composition measurements from Withings Body Smart scale.
/// Features:
/// - Connection status and "Connect Withings" button
/// - List of recent measurements (last 30 days)
/// - Pull-to-refresh to sync latest data
/// - Tap measurement to see full details
class BodyCompositionScreen extends StatefulWidget {
  const BodyCompositionScreen({super.key});

  @override
  State<BodyCompositionScreen> createState() => _BodyCompositionScreenState();
}

class _BodyCompositionScreenState extends State<BodyCompositionScreen> {
  final WithingsService _withingsService = WithingsService();

  bool _isLoading = true;
  bool _isConnected = false;
  List<BodyComposition> _measurements = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check connection status
      final status = await _withingsService.getConnectionStatus();
      final connected = status['connected'] as bool;

      setState(() {
        _isConnected = connected;
      });

      if (connected) {
        // Sync recent measurements
        await _syncMeasurements();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isConnected = false;
        _measurements = [];
      });
    }
  }

  Future<void> _syncMeasurements() async {
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final measurements = await _withingsService.syncMeasurements(
        startDate: startDate,
      );

      setState(() {
        _measurements = measurements;
        _measurements.sort((a, b) => b.measuredAt.compareTo(a.measuredAt)); // Most recent first
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to sync measurements: $e';
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _handleConnectionChanged() {
    _loadData();
  }

  void _handleSyncComplete() {
    _syncMeasurements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Composition'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_isConnected && !_isLoading)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _syncMeasurements,
              tooltip: 'Sync measurements',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Connection Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ConnectWithingsButton(
                          onConnectionChanged: _handleConnectionChanged,
                          onSyncComplete: _handleSyncComplete,
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (_isConnected) ...[
                      const SizedBox(height: 24),

                      // Section header
                      const Text(
                        'Recent Measurements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Measurements list
                      if (_measurements.isEmpty)
                        Card(
                          color: Colors.grey.shade100,
                          child: const Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.monitor_weight_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No measurements found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Step on your Withings scale and tap "Sync Now" to fetch your data',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._measurements.map((measurement) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BodyCompositionDetailScreen(
                                    measurement: measurement,
                                  ),
                                ),
                              );
                            },
                            child: BodyCompositionCard(
                              measurement: measurement,
                              isLoading: false,
                            ),
                          ),
                        )).toList(),
                    ] else ...[
                      const SizedBox(height: 24),
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Connect your Withings Body Smart scale to track your body composition metrics over time.',
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
