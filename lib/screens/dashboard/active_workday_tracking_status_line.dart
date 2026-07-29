/// Compact GPS-assisted tracking status for an active workday dashboard.
///
/// Owns only the user-visible state label for native collection. It does not
/// start, stop, persist, or interpret GPS samples. Consumed by
/// ActiveWorkdayScreen so location state remains visible without a large panel.
library;

import 'package:flutter/material.dart';

import '../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../shared/trip_tracking/trip_tracking_models.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';

class ActiveWorkdayTrackingStatusLine extends StatelessWidget {
  const ActiveWorkdayTrackingStatusLine({
    super.key,
    required this.onResume,
    required this.onStop,
    required this.onReview,
    this.resumeInFlight = false,
  });

  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onReview;
  final bool resumeInFlight;

  @override
  Widget build(BuildContext context) {
    final controller = TripTrackingScope.maybeOf(context);
    final settings = TripTrackingSettingsScope.maybeOf(context)?.settings;
    if (controller == null || settings == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
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
        final canResume = controller.isTracking && !controller.nativeTracking;
        final canStop = controller.nativeTracking;
        final hasReview = controller.latestUnconfirmedReview != null;
        final evidenceSummary = ActiveWorkdayTrackingStatus.evidenceSummaryFor(
          tracking: controller.isTracking,
          nativeTracking: controller.nativeTracking,
          acceptedMiles: controller.acceptedMiles,
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
                  if (canResume) ...[
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
                      onPressed: onStop,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(72, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: const Color(0xFF8D2D2D),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: const Text('STOP'),
                    ),
                  ],
                ],
              ),
              if (hasReview)
                TextButton(
                  onPressed: onReview,
                  child: const Text('Review GPS Trip Odometer'),
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

  final String label;
  final IconData icon;
  final Color color;
}
