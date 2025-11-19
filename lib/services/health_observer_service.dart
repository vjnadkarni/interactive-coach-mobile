import 'dart:async';
import 'package:health_kit_reporter/health_kit_reporter.dart';
import 'package:health_kit_reporter/model/type/quantity_type.dart';
import 'package:health_kit_reporter/model/update_frequency.dart';
import 'package:health_kit_reporter/model/predicate.dart';
import 'health_service.dart';
import 'health_sync_service.dart';

/// Observer-based HealthKit service using health_kit_reporter
/// Provides real-time notifications when Apple Watch writes new health data
/// Replaces polling with event-driven updates for better battery life and responsiveness
class HealthObserverService {
  static final HealthObserverService _instance = HealthObserverService._internal();
  factory HealthObserverService() => _instance;
  HealthObserverService._internal();

  final HealthService _healthService = HealthService();
  final HealthSyncService _syncService = HealthSyncService();

  // Observer subscriptions (keep alive to receive notifications)
  StreamSubscription<void>? _heartRateObserver;
  StreamSubscription<void>? _hrvObserver;
  StreamSubscription<void>? _spo2Observer;
  StreamSubscription<void>? _stepsObserver;
  StreamSubscription<void>? _bodyMassObserver;
  StreamSubscription<void>? _bodyFatObserver;

  // Callbacks for vitals updates (called when new data arrives)
  Function(VitalReading)? onHeartRateUpdate;
  Function(VitalReading)? onHRVUpdate;
  Function(VitalReading)? onSpO2Update;
  Function(int steps, double calories)? onActivityUpdate;
  Function()? onBodyCompositionUpdate;

  // Auto-sync to Supabase when new data arrives
  bool _autoSyncEnabled = false;

  /// Start observing heart rate changes
  /// Enables background delivery and sets up observer
  /// Callback fires immediately when Apple Watch writes new HR data
  Future<void> startObservingHeartRate({
    required Function(VitalReading) onUpdate,
  }) async {
    print('🔔 [HealthObserver] Starting heart rate observer...');

    try {
      // Save callback
      onHeartRateUpdate = onUpdate;

      // Enable background delivery for heart rate (immediate updates)
      final isEnabled = await HealthKitReporter.enableBackgroundDelivery(
        QuantityType.heartRate.identifier,
        UpdateFrequency.immediate,
      );

      if (isEnabled) {
        print('✅ [HealthObserver] Background delivery enabled for heart rate');
      } else {
        print('⚠️ [HealthObserver] Background delivery already enabled for heart rate');
      }

      // Set up observer query (predicate = null for all data)
      _heartRateObserver = HealthKitReporter.observerQuery(
        [QuantityType.heartRate.identifier],
        null, // No predicate (listen to all HR data)
        onUpdate: (identifier) async {
          print('🔔 NEW HEART RATE DATA AVAILABLE! Fetching from HealthKit...');

          // Fetch the latest heart rate reading
          final latestHR = await _healthService.getLatestHeartRate();

          if (latestHR != null) {
            print('✅ [HealthObserver] New HR: ${latestHR.value.round()} BPM at ${latestHR.timestamp}');

            // Trigger callback
            onHeartRateUpdate?.call(latestHR);
          } else {
            print('⚠️ [HealthObserver] No HR data found after observer notification');
          }
        },
      );

      print('✅ [HealthObserver] Heart rate observer started');
    } catch (e) {
      print('❌ [HealthObserver] Error starting heart rate observer: $e');
    }
  }

  /// Start observing HRV changes
  Future<void> startObservingHRV({
    required Function(VitalReading) onUpdate,
  }) async {
    print('🔔 [HealthObserver] Starting HRV observer...');

    try {
      onHRVUpdate = onUpdate;

      final isEnabled = await HealthKitReporter.enableBackgroundDelivery(
        QuantityType.heartRateVariabilitySDNN.identifier,
        UpdateFrequency.immediate,
      );

      if (isEnabled) {
        print('✅ [HealthObserver] Background delivery enabled for HRV');
      }

      _hrvObserver = HealthKitReporter.observerQuery(
        [QuantityType.heartRateVariabilitySDNN.identifier],
        null, // No predicate (listen to all HRV data)
        onUpdate: (identifier) async {
          print('🔔 NEW HRV DATA AVAILABLE! Fetching from HealthKit...');

          final latestHRV = await _healthService.getLatestHRV();

          if (latestHRV != null) {
            print('✅ [HealthObserver] New HRV: ${latestHRV.value.round()} ms at ${latestHRV.timestamp}');
            onHRVUpdate?.call(latestHRV);
          }
        },
      );

      print('✅ [HealthObserver] HRV observer started');
    } catch (e) {
      print('❌ [HealthObserver] Error starting HRV observer: $e');
    }
  }

  /// Start observing SpO2 changes
  Future<void> startObservingSpO2({
    required Function(VitalReading) onUpdate,
  }) async {
    print('🔔 [HealthObserver] Starting SpO2 observer...');

    try {
      onSpO2Update = onUpdate;

      final isEnabled = await HealthKitReporter.enableBackgroundDelivery(
        QuantityType.oxygenSaturation.identifier,
        UpdateFrequency.immediate,
      );

      if (isEnabled) {
        print('✅ [HealthObserver] Background delivery enabled for SpO2');
      }

      _spo2Observer = HealthKitReporter.observerQuery(
        [QuantityType.oxygenSaturation.identifier],
        null, // No predicate (listen to all SpO2 data)
        onUpdate: (identifier) async {
          print('🔔 NEW SPO2 DATA AVAILABLE! Fetching from HealthKit...');

          final latestSpO2 = await _healthService.getLatestSpO2();

          if (latestSpO2 != null) {
            print('✅ [HealthObserver] New SpO2: ${latestSpO2.value.round()}% at ${latestSpO2.timestamp}');
            onSpO2Update?.call(latestSpO2);
          }
        },
      );

      print('✅ [HealthObserver] SpO2 observer started');
    } catch (e) {
      print('❌ [HealthObserver] Error starting SpO2 observer: $e');
    }
  }

  /// Start observing all vitals (HR, HRV, SpO2)
  /// Convenience method to start all observers at once
  Future<void> startObservingAllVitals({
    required Function(VitalReading) onHeartRate,
    required Function(VitalReading) onHRV,
    required Function(VitalReading) onSpO2,
  }) async {
    print('🔔 [HealthObserver] Starting all vitals observers...');

    await Future.wait([
      startObservingHeartRate(onUpdate: onHeartRate),
      startObservingHRV(onUpdate: onHRV),
      startObservingSpO2(onUpdate: onSpO2),
    ]);

    print('✅ [HealthObserver] All vitals observers started');
  }

  /// Stop all observers and disable background delivery
  /// Call this when user logs out or disables health tracking
  Future<void> stopAllObservers() async {
    print('🛑 [HealthObserver] Stopping all observers...');

    try {
      // Cancel observer subscriptions
      await _heartRateObserver?.cancel();
      await _hrvObserver?.cancel();
      await _spo2Observer?.cancel();
      await _stepsObserver?.cancel();
      await _bodyMassObserver?.cancel();
      await _bodyFatObserver?.cancel();

      // Disable background delivery
      await HealthKitReporter.disableBackgroundDelivery(QuantityType.heartRate.identifier);
      await HealthKitReporter.disableBackgroundDelivery(QuantityType.heartRateVariabilitySDNN.identifier);
      await HealthKitReporter.disableBackgroundDelivery(QuantityType.oxygenSaturation.identifier);
      await HealthKitReporter.disableBackgroundDelivery(QuantityType.bodyMass.identifier);
      await HealthKitReporter.disableBackgroundDelivery(QuantityType.bodyFatPercentage.identifier);

      // Clear callbacks
      onHeartRateUpdate = null;
      onHRVUpdate = null;
      onSpO2Update = null;
      onActivityUpdate = null;
      onBodyCompositionUpdate = null;

      print('✅ [HealthObserver] All observers stopped');
    } catch (e) {
      print('❌ [HealthObserver] Error stopping observers: $e');
    }
  }

  /// Request HealthKit permissions (delegates to HealthService)
  Future<bool> requestPermissions() async {
    return await _healthService.requestPermissions();
  }

  /// Check if we have HealthKit permissions
  Future<bool> hasPermissions() async {
    return await _healthService.hasPermissions();
  }

  /// Start observing body composition changes (weight, body fat from smart scale)
  Future<void> startObservingBodyComposition({
    Function()? onUpdate,
  }) async {
    print('🔔 [HealthObserver] Starting body composition observers...');

    try {
      onBodyCompositionUpdate = onUpdate;

      // Enable background delivery for body mass (weight)
      final massEnabled = await HealthKitReporter.enableBackgroundDelivery(
        QuantityType.bodyMass.identifier,
        UpdateFrequency.immediate,
      );

      if (massEnabled) {
        print('✅ [HealthObserver] Background delivery enabled for body mass');
      }

      // Enable background delivery for body fat percentage
      final fatEnabled = await HealthKitReporter.enableBackgroundDelivery(
        QuantityType.bodyFatPercentage.identifier,
        UpdateFrequency.immediate,
      );

      if (fatEnabled) {
        print('✅ [HealthObserver] Background delivery enabled for body fat');
      }

      // Observer for body mass (weight)
      _bodyMassObserver = HealthKitReporter.observerQuery(
        [QuantityType.bodyMass.identifier],
        null,
        onUpdate: (identifier) async {
          print('⚖️ NEW BODY MASS DATA AVAILABLE from Smart Scale!');
          onBodyCompositionUpdate?.call();

          // Auto-sync to Supabase if enabled
          if (_autoSyncEnabled) {
            print('🔄 [HealthObserver] Auto-syncing body composition to Supabase...');
            await _syncService.syncBodyCompositionToBackend();
          }
        },
      );

      // Observer for body fat percentage
      _bodyFatObserver = HealthKitReporter.observerQuery(
        [QuantityType.bodyFatPercentage.identifier],
        null,
        onUpdate: (identifier) async {
          print('⚖️ NEW BODY FAT DATA AVAILABLE from Smart Scale!');
          onBodyCompositionUpdate?.call();

          // Auto-sync to Supabase if enabled
          if (_autoSyncEnabled) {
            print('🔄 [HealthObserver] Auto-syncing body composition to Supabase...');
            await _syncService.syncBodyCompositionToBackend();
          }
        },
      );

      print('✅ [HealthObserver] Body composition observers started');
    } catch (e) {
      print('❌ [HealthObserver] Error starting body composition observers: $e');
    }
  }

  /// Start the hybrid sync architecture
  /// - Observers for real-time push notifications from HealthKit
  /// - Auto-sync to Supabase when new data arrives
  /// - Polling fallback on app launch to catch missed data
  Future<void> startHybridSync({
    bool syncOnStart = true,
  }) async {
    print('🚀 [HealthObserver] Starting hybrid sync architecture...');

    _autoSyncEnabled = true;

    // Start all observers with auto-sync to Supabase
    await startObservingHeartRate(
      onUpdate: (reading) async {
        print('💓 [HybridSync] New HR: ${reading.value.round()} BPM');
        if (_autoSyncEnabled) {
          await _syncService.syncVitalsToBackend();
        }
      },
    );

    await startObservingHRV(
      onUpdate: (reading) async {
        print('💓 [HybridSync] New HRV: ${reading.value.round()} ms');
        if (_autoSyncEnabled) {
          await _syncService.syncVitalsToBackend();
        }
      },
    );

    await startObservingSpO2(
      onUpdate: (reading) async {
        print('💓 [HybridSync] New SpO2: ${reading.value.round()}%');
        if (_autoSyncEnabled) {
          await _syncService.syncVitalsToBackend();
        }
      },
    );

    await startObservingBodyComposition(
      onUpdate: () async {
        print('⚖️ [HybridSync] New body composition data');
        // Sync is handled in the observer itself
      },
    );

    // Polling fallback: sync all data on start to catch anything missed
    if (syncOnStart) {
      print('🔄 [HybridSync] Running initial sync (polling fallback)...');
      await _syncService.syncAllHealthData();
    }

    print('✅ [HybridSync] Hybrid sync architecture started');
    print('   - Observers: HR, HRV, SpO2, Body Mass, Body Fat');
    print('   - Auto-sync to Supabase: ENABLED');
    print('   - Polling fallback: ${syncOnStart ? "COMPLETED" : "DISABLED"}');
  }

  /// Stop hybrid sync and all observers
  Future<void> stopHybridSync() async {
    print('🛑 [HybridSync] Stopping hybrid sync...');
    _autoSyncEnabled = false;
    await stopAllObservers();
    print('✅ [HybridSync] Hybrid sync stopped');
  }

  /// Check if hybrid sync is running
  bool get isHybridSyncEnabled => _autoSyncEnabled;
}
