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
        final status = _statusFor(controller, settings);
        final canResume = controller.isTracking && !controller.nativeTracking;
        final canStop = controller.nativeTracking;
        final hasReview = controller.latestUnconfirmedReview != null;
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
            ],
          ),
        );
      },
    );
  }
}

_TrackingStatus _statusFor(
  TripTrackingController controller,
  TripTrackingSettings settings,
) {
  if (!settings.gpsAssistedTrackingEnabled) {
    return const _TrackingStatus(
      '• GPS assistance off — manual tracking is available',
      Icons.gps_off_rounded,
      Color(0xFFCAD2D5),
    );
  }
  if (controller.nativeTracking) {
    return const _TrackingStatus(
      '• GPS live — odometer remains official',
      Icons.gps_fixed_rounded,
      Color(0xFF50F77A),
    );
  }
  if (controller.lifecycleState == TripTrackingSessionLifecycleState.starting) {
    return const _TrackingStatus(
      '• GPS connecting — waiting for provider confirmation',
      Icons.gps_not_fixed_rounded,
      Color(0xFFFFD166),
    );
  }
  if (controller.isTracking) {
    return const _TrackingStatus(
      '• Location paused — workday and odometer are saved',
      Icons.pause_circle_outline_rounded,
      Color(0xFFFFD166),
    );
  }
  return const _TrackingStatus(
    '• GPS ready — start location assistance when needed',
    Icons.gps_not_fixed_rounded,
    Color(0xFFCAD2D5),
  );
}

class _TrackingStatus {
  const _TrackingStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
