import 'package:flutter/material.dart';
import '../models/body_composition.dart';
import '../services/health_service.dart';
import '../widgets/body_composition_card.dart';
import 'body_composition_detail_screen.dart';

/// Body Composition Screen - HealthKit Integration
/// Reads from ANY HealthKit-compatible smart scale
class BodyCompositionScreen extends StatefulWidget {
  const BodyCompositionScreen({super.key});

  @override
  State<BodyCompositionScreen> createState() => _BodyCompositionScreenState();
}

class _BodyCompositionScreenState extends State<BodyCompositionScreen> {
  final HealthService _healthService = HealthService();
  bool _isLoading = true;
  BodyComposition? _latestMeasurement;
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
      final hasPermissions = await _healthService.requestPermissions();
      if (!hasPermissions) {
        setState(() {
          _error = 'HealthKit permissions denied';
          _isLoading = false;
        });
        return;
      }

      await _fetchLatestMeasurement();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLatestMeasurement() async {
    print('🔄 [BodyComp] Starting to fetch latest measurement from HealthKit...');
    final weight = await _healthService.getLatestWeight();
    final bodyFat = await _healthService.getLatestBodyFat();
    final bmi = await _healthService.getLatestBMI();
    final leanMass = await _healthService.getLatestLeanBodyMass();

    if (weight == null) {
      print('⚠️ [BodyComp] No weight data found in HealthKit');
      setState(() {
        _latestMeasurement = null;
      });
      return;
    }

    // HealthKit returns weight in kg (no conversion needed)
    final weightInKg = weight.value;

    print('📊 [BodyComp] Creating BodyComposition object:');
    print('   Weight: $weightInKg kg');
    print('   Body Fat: ${bodyFat?.value}%');
    print('   BMI: ${bmi?.value}');
    print('   Timestamp: ${weight.timestamp}');

    setState(() {
      _latestMeasurement = BodyComposition(
        id: 'healthkit-${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current-user',
        weightKg: weightInKg,
        bodyFatPercent: bodyFat?.value,
        bmi: bmi?.value,
        measuredAt: weight.timestamp,
        source: 'healthkit',
      );
    });

    print('✅ [BodyComp] Latest measurement updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Composition'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Info card
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Text('Data from Apple Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Step on any HealthKit-compatible smart scale and your data will appear here automatically.', style: TextStyle(fontSize: 14, color: Colors.blue.shade900)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Latest measurement
                        if (_latestMeasurement != null)
                          BodyCompositionCard(
                            measurement: _latestMeasurement!,
                          )
                        else
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text('No measurements found. Pull down to refresh.', textAlign: TextAlign.center),
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
