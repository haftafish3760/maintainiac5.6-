import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_odometer_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/odometer/odometer_correction_review.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';

void main() {
  test(
    'odometer correction is shown with its recorded time, never actual time',
    () {
      final event = CalendarOdometerProjectionAdapter.fromEvent(
        vehicleId: 'truck-1',
        event: _event(
          correction: const OdometerCorrectionReview(
            reason: OdometerCorrectionReason.previousEntryWrong,
          ),
        ),
      );

      expect(event.timing.timeSource, CalendarTimeSource.recorded);
      expect(event.timing.displayTimeLabel, 'Recorded time');
      expect(event.timing.actualAt, isNull);
      expect(event.vehicleIds, ['truck-1']);
      expect(event.workProfileId, 'delivery');
      expect(event.deepLink.target, CalendarDeepLinkTarget.odometerDetail);
    },
  );

  test('unresolved correction remains review-required', () {
    final event = CalendarOdometerProjectionAdapter.fromEvent(
      vehicleId: 'truck-1',
      event: _event(
        correction: const OdometerCorrectionReview(
          reason: OdometerCorrectionReason.unresolved,
        ),
      ),
    );

    expect(event.state, CalendarProjectionState.needsReview);
    expect(event.sourceRecordStatus, 'correction reason unresolved');
  });

  test('day projection excludes malformed IDs and other dates', () {
    final events = CalendarOdometerProjectionAdapter.eventsForDay(
      vehicleId: 'truck-1',
      day: DateTime(2026, 7, 22),
      history: [
        _event(),
        _event(id: '', reading: 1010),
        _event(
          id: 'other-day',
          recordedAt: DateTime(2026, 7, 23, 8),
          reading: 1020,
        ),
      ],
    );

    expect(events.map((event) => event.sourceRecordId), ['odometer-1']);
  });
}

OdometerReadingEvent _event({
  String id = 'odometer-1',
  int reading = 1000,
  DateTime? recordedAt,
  OdometerCorrectionReview? correction,
}) => OdometerReadingEvent(
  id: id,
  reading: reading,
  previousReading: 990,
  recordedAt: recordedAt ?? DateTime(2026, 7, 22, 8),
  correctionReview: correction,
  workProfileId: 'delivery',
  sourceType: 'manual entry',
  sourceId: 'source-1',
);
