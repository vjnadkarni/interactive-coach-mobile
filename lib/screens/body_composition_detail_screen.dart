import 'package:flutter/material.dart';
import '../models/body_composition.dart';

/// Body Composition Detail Screen
///
/// Displays all 8 metrics from Withings Body Smart scale:
/// 1. Weight (kg)
/// 2. Body Fat %
/// 3. Visceral Fat
/// 4. Water %
/// 5. BMR (Basal Metabolic Rate)
/// 6. Metabolic Age
/// 7. BMI (Body Mass Index)
/// 8. Heart Rate
class BodyCompositionDetailScreen extends StatelessWidget {
  final BodyComposition measurement;

  const BodyCompositionDetailScreen({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Composition Metrics'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Latest Measurement Header
              Card(
                elevation: 2,
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Latest Measurement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatFullTimestamp(measurement.measuredAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Primary Metrics Section
              _buildSectionHeader('Primary Metrics'),
              const SizedBox(height: 12),
              _buildMetricCard(
                icon: Icons.monitor_weight,
                label: 'Weight',
                value: measurement.weightDisplay,
                color: Colors.orange.shade600,
              ),
              _buildMetricCard(
                icon: Icons.water_drop,
                label: 'Body Fat',
                value: measurement.bodyFatDisplay,
                color: Colors.blue.shade600,
              ),
              _buildMetricCard(
                icon: Icons.local_hospital,
                label: 'Visceral Fat',
                value: measurement.visceralFatDisplay,
                subtitle: 'Risk: ${measurement.visceralFatRisk}',
                color: _getVisceralFatColor(measurement.visceralFat),
              ),
              const SizedBox(height: 24),

              // Body Composition Section
              _buildSectionHeader('Body Composition'),
              const SizedBox(height: 12),
              _buildMetricCard(
                icon: Icons.water,
                label: 'Water %',
                value: measurement.waterDisplay,
                subtitle: 'Total body water',
                color: Colors.cyan.shade600,
              ),
              _buildMetricCard(
                icon: Icons.assessment,
                label: 'BMI',
                value: measurement.bmiDisplay,
                subtitle: 'Category: ${measurement.bmiCategory}',
                color: _getBMIColor(measurement.bmi),
              ),
              const SizedBox(height: 24),

              // Metabolism Section
              _buildSectionHeader('Metabolism'),
              const SizedBox(height: 12),
              _buildMetricCard(
                icon: Icons.local_fire_department,
                label: 'Basal Metabolic Rate',
                value: measurement.bmrDisplay,
                subtitle: 'Calories burned at rest',
                color: Colors.deepOrange.shade600,
              ),
              _buildMetricCard(
                icon: Icons.calendar_today,
                label: 'Metabolic Age',
                value: measurement.metabolicAgeDisplay,
                subtitle: 'Body\'s functional age',
                color: Colors.purple.shade600,
              ),
              const SizedBox(height: 24),

              // Cardiovascular Section
              _buildSectionHeader('Cardiovascular'),
              const SizedBox(height: 12),
              _buildMetricCard(
                icon: Icons.favorite,
                label: 'Heart Rate',
                value: measurement.heartRateDisplay,
                subtitle: 'Measured during weighing',
                color: Colors.red.shade600,
              ),
              const SizedBox(height: 24),

              // Data Source
              Card(
                elevation: 1,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Source',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Withings Body Smart Scale',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
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

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Build metric card
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get color for visceral fat based on risk level
  Color _getVisceralFatColor(int? visceralFat) {
    if (visceralFat == null) return Colors.grey;
    if (visceralFat < 10) return Colors.green.shade600;
    if (visceralFat < 15) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  /// Get color for BMI based on category
  Color _getBMIColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return Colors.blue.shade600; // Underweight
    if (bmi < 25) return Colors.green.shade600; // Normal
    if (bmi < 30) return Colors.orange.shade600; // Overweight
    return Colors.red.shade600; // Obese
  }

  /// Format full timestamp for display
  String _formatFullTimestamp(DateTime timestamp) {
    final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][timestamp.weekday - 1];
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][timestamp.month - 1];
    final day = timestamp.day;
    final year = timestamp.year;
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';

    return '$weekday, $month $day, $year at $hour:$minute $period';
  }
}
