part of 'trip_tracking_settings_screen.dart';

/// A standing opt-in is not enough to change GPS estimates. Current,
/// vehicle-specific evidence still requires this explicit review.
class _CalibrationAcceptancePanel extends StatelessWidget {
  const _CalibrationAcceptancePanel({required this.tripTracking});

  final TripTrackingController tripTracking;

  @override
  Widget build(BuildContext context) {
    final guard = tripTracking.gpsAssistanceCalibrationApplyGuard;
    final reviewRequired = guard.reasonCodes.contains(
      'user_must_accept_calibration_review',
    );
    final waitingForHistory = guard.reasonCodes.contains(
      'more_reviewed_odometer_days_required',
    );
    final detail = reviewRequired
        ? 'Current reviewed mileage shows a consistent difference. Accepting applies the advisory adjustment only to future GPS estimates for this vehicle. It never changes confirmed odometer history.'
        : waitingForHistory
        ? 'More consistent, reviewed driving days are needed before a calibration review can be offered.'
        : tripTracking.calibrationReviewAcceptedForCurrentEvidence
        ? 'Current reviewed evidence has been accepted. Only future GPS estimates use the advisory adjustment.'
        : 'Current evidence is not eligible for an advisory GPS calibration.';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SettingText(
            title: 'Calibration review',
            detail:
                'Confirmed odometer readings remain authoritative. GPS can never rewrite them.',
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.18,
            ),
          ),
          if (reviewRequired) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _acceptCurrentReview(context),
              child: const Text('Accept current calibration review'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptCurrentReview(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept advisory GPS calibration?'),
        content: const Text(
          'This affects only future GPS-assisted estimates for the current vehicle. It never edits confirmed odometer readings, completed TripLog history, or Recap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (accepted != true || !context.mounted) return;
    final applied = tripTracking.acceptGpsAssistanceCalibrationReview();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied
              ? 'Advisory GPS calibration will apply to future estimates only.'
              : 'Calibration evidence changed or is not eligible. No adjustment was applied.',
        ),
      ),
    );
  }
}
