import 'package:flutter/material.dart';
import '../models/body_composition.dart';
import '../screens/body_composition_detail_screen.dart';

/// Body Composition Card Widget
///
/// Displays primary body composition metrics from Withings Body Smart scale:
/// - Weight (kg)
/// - Body Fat %
/// - Visceral Fat
///
/// Tapping "See more..." opens detailed screen with all 8 metrics
class BodyCompositionCard extends StatelessWidget {
  final BodyComposition? measurement;
  final bool isLoading;

  const BodyCompositionCard({
    super.key,
    this.measurement,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.monitor_weight,
                  color: Colors.orange.shade400,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Body Composition',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!isLoading && measurement != null)
                  Text(
                    _formatTimestamp(measurement!.measuredAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading indicator
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),

            // No data state
            if (!isLoading && measurement == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.scale,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No measurements yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Step on your Withings scale to see your body composition metrics',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Metrics display (side-by-side columns like Vitals card)
            if (!isLoading && measurement != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricColumn(
                    icon: Icons.monitor_weight,
                    label: 'Weight',
                    value: measurement!.weightKg != null
                        ? '${measurement!.weightKg!.toStringAsFixed(1)}'
                        : '--',
                    unit: 'kg',
                    color: Colors.orange,
                  ),
                  _buildMetricColumn(
                    icon: Icons.water_drop,
                    label: 'Body Fat',
                    value: measurement!.bodyFatPercent != null
                        ? '${measurement!.bodyFatPercent!.toStringAsFixed(1)}'
                        : '--',
                    unit: '%',
                    color: Colors.blue,
                  ),
                  _buildMetricColumn(
                    icon: Icons.local_hospital,
                    label: 'Visceral Fat',
                    value: measurement!.visceralFat != null
                        ? '${measurement!.visceralFat}'
                        : '--',
                    unit: _getVisceralFatRisk(measurement!.visceralFat),
                    color: _getVisceralFatColor(measurement!.visceralFat),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // See more button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BodyCompositionDetailScreen(
                          measurement: measurement!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('See more...'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a metric column (matching Vitals card style)
  Widget _buildMetricColumn({
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
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Get visceral fat risk level text
  String _getVisceralFatRisk(int? visceralFat) {
    if (visceralFat == null) return '';
    if (visceralFat < 10) return 'Low';
    if (visceralFat < 15) return 'Moderate';
    return 'High';
  }

  /// Get color for visceral fat based on risk level
  Color _getVisceralFatColor(int? visceralFat) {
    if (visceralFat == null) return Colors.grey;
    if (visceralFat < 10) return Colors.green.shade600;
    if (visceralFat < 15) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
