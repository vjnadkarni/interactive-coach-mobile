/// Body Composition Model
/// Represents measurements from Withings Body Smart scale
///
/// Metrics:
/// - Primary (shown in card): Weight, Body Fat %, Visceral Fat
/// - Additional (shown in detail): Water %, BMR, Metabolic Age, BMI, Heart Rate
class BodyComposition {
  final String id;
  final String userId;
  final DateTime measuredAt;

  // Primary metrics (shown in card)
  final double? weightKg;
  final double? bodyFatPercent;
  final int? visceralFat;

  // Additional metrics (shown in detail screen)
  final double? waterPercent;
  final int? bmr; // Basal Metabolic Rate in kcal
  final int? metabolicAge;
  final double? bmi; // Body Mass Index
  final int? heartRate;

  // Metadata
  final String source;
  final int? withingsMeasurementId;
  final DateTime createdAt;

  BodyComposition({
    required this.id,
    required this.userId,
    required this.measuredAt,
    this.weightKg,
    this.bodyFatPercent,
    this.visceralFat,
    this.waterPercent,
    this.bmr,
    this.metabolicAge,
    this.bmi,
    this.heartRate,
    this.source = 'withings',
    this.withingsMeasurementId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from Supabase JSON
  factory BodyComposition.fromJson(Map<String, dynamic> json) {
    return BodyComposition(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      measuredAt: DateTime.parse(json['measured_at'] as String),
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      bodyFatPercent: json['body_fat_percent'] != null ? (json['body_fat_percent'] as num).toDouble() : null,
      visceralFat: json['visceral_fat'] as int?,
      waterPercent: json['water_percent'] != null ? (json['water_percent'] as num).toDouble() : null,
      bmr: json['bmr'] as int?,
      metabolicAge: json['metabolic_age'] as int?,
      bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
      heartRate: json['heart_rate'] as int?,
      source: json['source'] as String? ?? 'withings',
      withingsMeasurementId: json['withings_measurement_id'] as int?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'measured_at': measuredAt.toIso8601String(),
      'weight_kg': weightKg,
      'body_fat_percent': bodyFatPercent,
      'visceral_fat': visceralFat,
      'water_percent': waterPercent,
      'bmr': bmr,
      'metabolic_age': metabolicAge,
      'bmi': bmi,
      'heart_rate': heartRate,
      'source': source,
      'withings_measurement_id': withingsMeasurementId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create mock data for testing UI
  static BodyComposition mock() {
    return BodyComposition(
      id: 'mock-id-12345',
      userId: 'mock-user-id',
      measuredAt: DateTime.now().subtract(const Duration(hours: 2)),
      weightKg: 72.5,
      bodyFatPercent: 18.2,
      visceralFat: 8,
      waterPercent: 61.5,
      bmr: 1680,
      metabolicAge: 32,
      bmi: 22.8,
      heartRate: 68,
      source: 'mock',
    );
  }

  /// Format weight for display
  String get weightDisplay => weightKg != null ? '${weightKg!.toStringAsFixed(1)} kg' : 'N/A';

  /// Format body fat for display
  String get bodyFatDisplay => bodyFatPercent != null ? '${bodyFatPercent!.toStringAsFixed(1)}%' : 'N/A';

  /// Format visceral fat for display
  String get visceralFatDisplay => visceralFat != null ? '$visceralFat' : 'N/A';

  /// Format water percent for display
  String get waterDisplay => waterPercent != null ? '${waterPercent!.toStringAsFixed(1)}%' : 'N/A';

  /// Format BMR for display
  String get bmrDisplay => bmr != null ? '$bmr kcal' : 'N/A';

  /// Format metabolic age for display
  String get metabolicAgeDisplay => metabolicAge != null ? '$metabolicAge years' : 'N/A';

  /// Format BMI for display
  String get bmiDisplay => bmi != null ? bmi!.toStringAsFixed(1) : 'N/A';

  /// Format heart rate for display
  String get heartRateDisplay => heartRate != null ? '$heartRate bpm' : 'N/A';

  /// Get BMI category
  String get bmiCategory {
    if (bmi == null) return 'Unknown';
    if (bmi! < 18.5) return 'Underweight';
    if (bmi! < 25) return 'Normal';
    if (bmi! < 30) return 'Overweight';
    return 'Obese';
  }

  /// Get visceral fat risk level
  String get visceralFatRisk {
    if (visceralFat == null) return 'Unknown';
    if (visceralFat! < 10) return 'Low';
    if (visceralFat! < 15) return 'Moderate';
    return 'High';
  }

  @override
  String toString() {
    return 'BodyComposition{id: $id, measuredAt: $measuredAt, weight: $weightDisplay, bodyFat: $bodyFatDisplay, visceralFat: $visceralFatDisplay}';
  }
}
