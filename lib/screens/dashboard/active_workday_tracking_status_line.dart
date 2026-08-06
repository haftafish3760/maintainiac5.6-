/// Compact GPS-assisted tracking status for an active workday dashboard.
///
/// Owns only the user-visible state label for native collection. It does not
/// start, stop, persist, or interpret GPS samples. Consumed by
/// ActiveWorkdayScreen so location state remains visible without a large panel.
library;

import 'package:flutter/material.dart';

import '../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../shared/trip_tracking/trip_tracking_bluetooth_runtime.dart';
import '../../shared/trip_tracking/trip_tracking_models.dart';
import '../../shared/trip_tracking/trip_tracking_signal_quality.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import 'active_workday_bluetooth_status_line.dart';

class ActiveWorkdayTrackingStatusLine extends StatelessWidget {
  const ActiveWorkdayTrackingStatusLine({
    super.key,
    required this.onStart,
    required this.onResume,
    required this.onStop,
    required this.onReview,
    this.onReviewAutomaticEvidence,
    this.resumeInFlight = false,
    this.stopInFlight = false,
  });

  final VoidCallback onStart;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onReview;
  final VoidCallback? onReviewAutomaticEvidence;
  final bool resumeInFlight;
  final bool stopInFlight;

  @override
  Widget build(BuildContext context) {
    final controller = TripTrackingScope.maybeOf(context);
    final settings = TripTrackingSettingsScope.maybeOf(context)?.settings;
    final bluetoothRuntime = TripTrackingBluetoothRuntimeScope.maybeOf(context);
    if (controller == null || settings == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: Listenable.merge([controller, ?bluetoothRuntime]),
      builder: (context, _) {
        final status = ActiveWorkdayTrackingStatus.forSnapshot(
          gpsAssistanceEnabled: settings.gpsAssistedTrackingEnabled,
          nativeTracking: controller.nativeTracking,
          tracking: controller.isTracking,
          lifecycleState: controller.lifecycleState,
          platformStatus: controller.platformStatus,
          awaitingInitialFix: controller.awaitingInitialFix,
          signalReviewRequired:
              controller.signalQualitySummary.requiresUserReview,
        );
        final canStart =
            settings.gpsAssistedTrackingEnabled && !controller.isTracking;
        final canResume = controller.isTracking && !controller.nativeTracking;
        final canStop = controller.nativeTracking || stopInFlight;
        final hasReview = controller.latestUnconfirmedReview != null;
        final pendingAutomaticEvidenceCount =
            controller.pendingAutomaticEvidenceCandidates.length;
        final evidenceSummary = ActiveWorkdayTrackingStatus.evidenceSummaryFor(
          tracking: controller.isTracking,
          nativeTracking: controller.nativeTracking,
          acceptedMiles: controller.acceptedMiles,
        );
        final bluetoothStatus = ActiveWorkdayBluetoothStatus.forSnapshot(
          recognitionEnabled: settings.bluetoothVehicleRecognitionEnabled,
          observationAvailable: bluetoothRuntime?.observationAvailable ?? false,
          isListening: bluetoothRuntime?.isListening ?? false,
          lastDecision: bluetoothRuntime?.lastDecision,
        );
        final diagnostics = controller.diagnostics;
        final signal = controller.signalQualitySummary;
        final diagnosticSummary =
            ActiveWorkdayTrackingStatus.diagnosticSummaryFor(
              nativeTracking: controller.nativeTracking,
              providerRegistered: controller.nativeProviderRegistered,
              awaitingInitialFix: controller.awaitingInitialFix,
              receivedSamples: diagnostics.receivedSamples,
              acceptedSamples: diagnostics.acceptedSamples,
              rejectedSamples: diagnostics.rejectedSamples,
              signalQuality: signal.quality,
              signalReason: signal.reasonCode,
              motionState: controller.motionState,
              signalGapCount: controller.signalGaps.length,
              pendingStopCount: controller.pendingStopReviewCount,
              hasAcceptedLocation:
                  controller.activeSession?.engineSnapshot.lastAccepted != null,
              bluetoothLabel: bluetoothStatus.label,
            );
        return Semantics(
          label: status.label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(status.icon, size: 15, color: status.color),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (canStart) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: resumeInFlight ? null : onStart,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(98, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: const Color(0xFF1976B9),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('START GPS'),
                    ),
                  ] else if (canResume) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: resumeInFlight ? null : onResume,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(82, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: const Color(0xFF1976B9),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: Text(resumeInFlight ? 'STARTING' : 'RESUME'),
                    ),
                  ],
                  if (canStop) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: stopInFlight ? null : onStop,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(72, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: const Color(0xFF8D2D2D),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: Text(stopInFlight ? 'STOPPING' : 'STOP'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              ActiveWorkdayBluetoothStatusLine(status: bluetoothStatus),
              if (hasReview)
                TextButton(
                  onPressed: onReview,
                  child: const Text('Review GPS Trip Odometer'),
                ),
              if (pendingAutomaticEvidenceCount > 0)
                TextButton(
                  onPressed: onReviewAutomaticEvidence,
                  child: Text(
                    'Review $pendingAutomaticEvidenceCount App Assistant ${pendingAutomaticEvidenceCount == 1 ? 'item' : 'items'}',
                  ),
                ),
              if (evidenceSummary != null) ...[
                const SizedBox(height: 3),
                Text(
                  evidenceSummary,
                  style: const TextStyle(
                    color: Color(0xFF9CC7E8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                collapsedIconColor: const Color(0xFF9CC7E8),
                iconColor: const Color(0xFF9CC7E8),
                title: const Text(
                  'GPS test details',
                  style: TextStyle(
                    color: Color(0xFF9CC7E8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      diagnosticSummary,
                      style: const TextStyle(
                        color: Color(0xFFCAD2D5),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

@immutable
class ActiveWorkdayTrackingStatus {
  const ActiveWorkdayTrackingStatus(this.label, this.icon, this.color);

  /// Derives a visible status from controller evidence only.
  ///
  /// It deliberately does not equate provider registration with a current
  /// location fix, and it never presents degraded evidence as live GPS.
  static ActiveWorkdayTrackingStatus forSnapshot({
    required bool gpsAssistanceEnabled,
    required bool nativeTracking,
    required bool tracking,
    required TripTrackingSessionLifecycleState? lifecycleState,
    required String? platformStatus,
    required bool awaitingInitialFix,
    required bool signalReviewRequired,
  }) {
    if (!gpsAssistanceEnabled) {
      return const ActiveWorkdayTrackingStatus(
        '• GPS assistance off — manual tracking is available',
        Icons.gps_off_rounded,
        Color(0xFFCAD2D5),
      );
    }
    if (_isExplicitPause(platformStatus)) {
      return const ActiveWorkdayTrackingStatus(
        '• Location paused — workday and odometer are saved',
        Icons.pause_circle_outline_rounded,
        Color(0xFFFFD166),
      );
    }
    if (lifecycleState == TripTrackingSessionLifecycleState.starting ||
        awaitingInitialFix) {
      return const ActiveWorkdayTrackingStatus(
        '• GPS acquiring — waiting for a current location',
        Icons.gps_not_fixed_rounded,
        Color(0xFFFFD166),
      );
    }
    if (lifecycleState == TripTrackingSessionLifecycleState.degraded ||
        platformStatus == 'gps_signal_stale' ||
        signalReviewRequired) {
      return const ActiveWorkdayTrackingStatus(
        '• GPS degraded — review signal before ending',
        Icons.gps_off_rounded,
        Color(0xFFFFD166),
      );
    }
    if (nativeTracking) {
      return const ActiveWorkdayTrackingStatus(
        '• GPS live — odometer remains official',
        Icons.gps_fixed_rounded,
        Color(0xFF50F77A),
      );
    }
    if (tracking) {
      return const ActiveWorkdayTrackingStatus(
        '• Location paused — workday and odometer are saved',
        Icons.pause_circle_outline_rounded,
        Color(0xFFFFD166),
      );
    }
    return const ActiveWorkdayTrackingStatus(
      '• GPS ready — start location assistance when needed',
      Icons.gps_not_fixed_rounded,
      Color(0xFFCAD2D5),
    );
  }

  static bool _isExplicitPause(String? platformStatus) =>
      platformStatus == 'paused' ||
      platformStatus == 'recovery_paused_by_user' ||
      platformStatus == 'battery_critical_gps_blocked' ||
      platformStatus == 'low_battery_requires_user_choice' ||
      platformStatus == 'gps_signal_review_required';

  /// Describes accepted GPS evidence without presenting it as mileage truth.
  static String? evidenceSummaryFor({
    required bool tracking,
    required bool nativeTracking,
    required double acceptedMiles,
  }) {
    if (!tracking) return null;
    if (!nativeTracking) {
      return 'GPS evidence paused. No new GPS distance is being added.';
    }
    if (acceptedMiles < 0.05) {
      return 'GPS evidence: waiting for accepted movement. Odometer stays official.';
    }
    return 'GPS evidence: ${acceptedMiles.toStringAsFixed(1)} mi accepted. Odometer stays official.';
  }

  /// Builds privacy-safe, live field-test diagnostics from controller state.
  ///
  /// This explains collector and evidence health without showing coordinates,
  /// route geometry, or changing a trip, stop, or odometer record.
  static String diagnosticSummaryFor({
    required bool nativeTracking,
    required bool providerRegistered,
    required bool awaitingInitialFix,
    required int receivedSamples,
    required int acceptedSamples,
    required int rejectedSamples,
    required TripTrackingSignalQuality signalQuality,
    required String signalReason,
    required TripMotionState motionState,
    required int signalGapCount,
    required int pendingStopCount,
    required bool hasAcceptedLocation,
    required String bluetoothLabel,
  }) {
    final collector = nativeTracking
        ? (providerRegistered ? 'running' : 'starting')
        : 'not running';
    final location = awaitingInitialFix
        ? 'waiting for a current location'
        : hasAcceptedLocation
        ? 'current evidence accepted'
        : 'no accepted location yet';
    final safeReason = signalReason.trim().isEmpty ? 'none' : signalReason;
    return 'Collector: $collector\n'
        'Location: $location\n'
        'Samples: $receivedSamples received · $acceptedSamples accepted · '
        '$rejectedSamples rejected\n'
        'Signal: ${signalQuality.name} ($safeReason) · gaps: $signalGapCount\n'
        'Motion: ${motionState.name} · stops waiting for review: '
        '$pendingStopCount\n'
        'Bluetooth: $bluetoothLabel\n'
        'No coordinates are shown here. GPS remains evidence; the odometer '
        'and your review remain official.';
  }

  final String label;
  final IconData icon;
  final Color color;
}
