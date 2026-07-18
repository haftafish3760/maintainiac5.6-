import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_correction_review.dart';
import 'package:maintaniac/shared/odometer/odometer_mileage_review.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';
import 'package:maintaniac/shared/odometer/odometer_vehicle_snapshot.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  test('rejects empty and non-numeric odometer input', () {
    final controller = GlobalOdometerController(initialReading: 1000);

    expect(controller.updateFromText('').ok, isFalse);
    expect(controller.updateFromText('12A45').ok, isFalse);
    expect(controller.reading, 1000);
  });

  test('negative odometer baselines recover to zero', () async {
    final controller = GlobalOdometerController(initialReading: -100);

    expect(controller.reading, isZero);
    expect(controller.confirmedReading, isZero);
    expect(controller.history.single.reading, isZero);

    final switched = await controller.switchVehicle(
      OdometerVehicleSnapshot(
        vehicleId: 'vehicle_negative_snapshot',
        currentReading: -5,
        updatedAt: DateTime.utc(2026, 7, 17, 12),
        history: const [],
      ),
    );

    expect(switched, isTrue);
    expect(controller.reading, isZero);
    expect(controller.confirmedReading, isZero);
    expect(controller.history.single.reading, isZero);
  });

  test('malformed odometer event timestamps do not become current time', () {
    final event = OdometerReadingEvent.fromMap({
      'id': 'bad-time',
      'reading': 1000,
      'recordedAt': 'not-a-date',
    });

    expect(
      event.recordedAt,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  });

  test('can validate a reviewed reading before committing it', () {
    final controller = GlobalOdometerController(initialReading: 1000);

    final preview = controller.updateFromText(
      '1045',
      commit: false,
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.business,
      ),
    );

    expect(preview.ok, isTrue);
    expect(controller.confirmedReading, 1000);
    expect(controller.history, hasLength(1));

    final saved = controller.updateFromText(
      '1045',
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.business,
      ),
    );
    expect(saved.ok, isTrue);
    expect(controller.confirmedReading, 1045);
    expect(controller.history, hasLength(2));
  });

  test('does not duplicate a receipt-linked odometer history event', () {
    final controller = GlobalOdometerController(initialReading: 1000);
    const review = OdometerMileageReview(use: OdometerMileageUse.business);

    final first = controller.updateFromText(
      '1045',
      mileageReview: review,
      sourceType: 'expense_receipt',
      sourceId: 'expense-1',
    );
    final repeated = controller.updateFromText(
      '1045',
      mileageReview: review,
      sourceType: 'expense_receipt',
      sourceId: 'expense-1',
    );

    expect(first.ok, isTrue);
    expect(repeated.ok, isTrue);
    expect(controller.history, hasLength(2));
    expect(
      controller
          .updateFromText(
            '1050',
            mileageReview: const OdometerMileageReview(
              use: OdometerMileageUse.business,
            ),
            sourceType: 'expense_receipt',
            sourceId: 'expense-1',
          )
          .ok,
      isFalse,
    );
  });

  test('GPS review idempotency uses trip-specific wording', () {
    final controller = GlobalOdometerController(initialReading: 1000);
    const review = OdometerMileageReview(use: OdometerMileageUse.business);

    controller.updateFromText(
      '1045',
      mileageReview: review,
      sourceType: 'gps_trip_review',
      sourceId: 'trip-1',
    );

    final repeated = controller.updateFromText(
      '1045',
      mileageReview: review,
      sourceType: 'gps_trip_review',
      sourceId: 'trip-1',
    );
    final conflict = controller.updateFromText(
      '1050',
      mileageReview: review,
      sourceType: 'gps_trip_review',
      sourceId: 'trip-1',
    );

    expect(repeated.ok, isTrue);
    expect(repeated.message, contains('GPS trip'));
    expect(conflict.ok, isFalse);
    expect(conflict.message, contains('GPS trip'));
  });

  test('lower odometer reading requires correction review', () {
    final controller = GlobalOdometerController(initialReading: 1000);
    final result = controller.updateFromText('999');

    expect(result.ok, isFalse);
    expect(result.requiresCorrectionReview, isTrue);
    expect(result.currentReading, 1000);
    expect(result.candidateReading, 999);
    expect(controller.reading, 1000);
  });

  test(
    'backdated lower reading is saved without changing current odometer',
    () {
      final controller = GlobalOdometerController(initialReading: 1000);
      final result = controller.updateFromText(
        '950',
        enteredAt: DateTime(2026, 6, 1, 8),
        correctionReview: const OdometerCorrectionReview(
          reason: OdometerCorrectionReason.backdatedEntry,
        ),
      );

      expect(result.ok, isTrue);
      expect(result.affectsCurrentReading, isFalse);
      expect(controller.reading, 1000);
      expect(controller.history.last.reading, 950);
      expect(controller.history.last.affectsCurrentReading, isFalse);
      expect(
        controller.history.last.correctionReview?.reason,
        OdometerCorrectionReason.backdatedEntry,
      );
    },
  );

  test(
    'typed-wrong lower reading stops the save and keeps current odometer',
    () {
      final controller = GlobalOdometerController(initialReading: 1000);
      final result = controller.updateFromText(
        '950',
        correctionReview: const OdometerCorrectionReview(
          reason: OdometerCorrectionReason.typedWrong,
        ),
      );

      expect(result.ok, isFalse);
      expect(
        result.message,
        contains('Review the vehicle and odometer number'),
      );
      expect(controller.reading, 1000);
      expect(controller.history.length, 1);
    },
  );

  test('previous-entry lower correction is held for dedicated audit flow', () {
    final controller = GlobalOdometerController(initialReading: 1000);
    final result = controller.updateFromText(
      '950',
      correctionReview: const OdometerCorrectionReview(
        reason: OdometerCorrectionReason.previousEntryWrong,
      ),
    );

    expect(result.ok, isFalse);
    expect(result.message, contains('odometer correction flow'));
    expect(controller.reading, 1000);
    expect(controller.history.length, 1);
  });

  test(
    'audit correction can replace current odometer with audit event',
    () async {
      final controller = GlobalOdometerController(initialReading: 1000);

      await controller.applyAuditCorrection(
        rawValue: '950',
        correctedAt: DateTime(2026, 6, 2, 8),
        correctionReview: const OdometerCorrectionReview(
          reason: OdometerCorrectionReason.previousEntryWrong,
          note: 'Previous entry had two digits swapped.',
        ),
      );

      expect(controller.reading, 950);
      expect(controller.history.last.reading, 950);
      expect(
        controller.history.last.correctionReview?.reason,
        OdometerCorrectionReason.previousEntryWrong,
      );
    },
  );

  test('audit correction rejects non-audit reasons', () async {
    final controller = GlobalOdometerController(initialReading: 1000);

    expect(
      () => controller.applyAuditCorrection(
        rawValue: '950',
        correctionReview: const OdometerCorrectionReview(
          reason: OdometerCorrectionReason.typedWrong,
        ),
      ),
      throwsArgumentError,
    );
    expect(controller.reading, 1000);
  });

  test('rejects readings above supported odometer range', () {
    final controller = GlobalOdometerController(initialReading: 1000);
    final result = controller.updateFromText('10,000,000');

    expect(result.ok, isFalse);
    expect(result.message, contains('up to 9,999,999 miles'));
    expect(controller.reading, 1000);
  });

  test('requires mileage review before saving higher odometer progress', () {
    final controller = GlobalOdometerController(
      initialReading: 1000,
      initialRecordedAt: DateTime(2026, 6, 1, 8),
    );

    final result = controller.updateFromText(
      '1,045',
      enteredAt: DateTime(2026, 6, 2, 8),
    );

    expect(result.ok, isFalse);
    expect(result.requiresMileageReview, isTrue);
    expect(result.deltaMiles, 45);
    expect(controller.reading, 1000);
  });

  test('accepts higher odometer progress after mileage use is assigned', () {
    final controller = GlobalOdometerController(
      initialReading: 1000,
      initialRecordedAt: DateTime(2026, 6, 1, 8),
    );

    final result = controller.updateFromText(
      '1,045',
      enteredAt: DateTime(2026, 6, 2, 8),
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.business,
      ),
    );

    expect(result.ok, isTrue);
    expect(controller.reading, 1045);
    expect(controller.history.length, 2);
    expect(
      controller.history.last.mileageReview?.use,
      OdometerMileageUse.business,
    );
  });

  test(
    'higher unresolved mileage is queued and can be resolved later',
    () async {
      final controller = GlobalOdometerController(initialReading: 1000);

      final result = controller.updateFromText(
        '1,050',
        mileageReview: const OdometerMileageReview(
          use: OdometerMileageUse.unresolved,
        ),
        workProfileId: 'main_work',
        sourceType: 'manual_odometer',
        sourceId: 'entry-1',
      );

      expect(result.ok, isTrue);
      expect(controller.unresolvedMileageEvents.length, 1);
      final event = controller.unresolvedMileageEvents.single;
      expect(event.workProfileId, 'main_work');
      expect(event.sourceType, 'manual_odometer');
      expect(event.sourceId, 'entry-1');

      final resolved = await controller.resolveMileageReview(
        eventId: event.id,
        review: const OdometerMileageReview(use: OdometerMileageUse.personal),
      );

      expect(resolved, isTrue);
      expect(controller.unresolvedMileageEvents, isEmpty);
      expect(
        controller.history.last.mileageReview?.use,
        OdometerMileageUse.personal,
      );
    },
  );

  test('split mileage cannot assign more business miles than the delta', () {
    final controller = GlobalOdometerController(initialReading: 1000);

    final result = controller.updateFromText(
      '1,045',
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.split,
        businessMiles: 50,
      ),
    );

    expect(result.ok, isFalse);
    expect(result.message, contains('cannot be more than the 45 miles added'));
    expect(controller.reading, 1000);
  });

  test('daily average review can be disabled when needed', () {
    final controller = GlobalOdometerController(
      initialReading: 1300,
      validationPolicy: const OdometerValidationPolicy(
        drivingPatternReviewEnabled: false,
      ),
      initialHistory: [
        OdometerReadingEvent(
          reading: 1000,
          recordedAt: DateTime(2026, 6, 1, 8),
        ),
        OdometerReadingEvent(
          reading: 1100,
          recordedAt: DateTime(2026, 6, 2, 8),
        ),
        OdometerReadingEvent(
          reading: 1200,
          recordedAt: DateTime(2026, 6, 3, 8),
        ),
        OdometerReadingEvent(
          reading: 1300,
          recordedAt: DateTime(2026, 6, 4, 8),
        ),
      ],
    );

    final result = controller.updateFromText(
      '2100',
      enteredAt: DateTime(2026, 6, 5, 8),
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.business,
      ),
    );

    expect(result.ok, isTrue);
    expect(controller.reading, 2100);
  });

  test(
    'opt-in daily average review flags mileage far outside recent average',
    () {
      final controller = GlobalOdometerController(
        initialReading: 1300,
        validationPolicy: const OdometerValidationPolicy(
          drivingPatternReviewEnabled: true,
        ),
        initialHistory: [
          OdometerReadingEvent(
            reading: 1000,
            recordedAt: DateTime(2026, 6, 1, 8),
          ),
          OdometerReadingEvent(
            reading: 1100,
            recordedAt: DateTime(2026, 6, 2, 8),
          ),
          OdometerReadingEvent(
            reading: 1200,
            recordedAt: DateTime(2026, 6, 3, 8),
          ),
          OdometerReadingEvent(
            reading: 1300,
            recordedAt: DateTime(2026, 6, 4, 8),
          ),
        ],
      );

      final result = controller.updateFromText(
        '2100',
        enteredAt: DateTime(2026, 6, 5, 8),
        mileageReview: const OdometerMileageReview(
          use: OdometerMileageUse.business,
        ),
      );

      expect(result.ok, isFalse);
      expect(result.requiresConfirmation, isTrue);
      expect(result.message, contains('outside the expected range'));
      expect(controller.reading, 1300);
    },
  );

  test('daily average review stays off until the user opts in', () {
    final controller = GlobalOdometerController(
      initialReading: 1300,
      initialHistory: [
        OdometerReadingEvent(
          reading: 1000,
          recordedAt: DateTime(2026, 6, 1, 8),
        ),
        OdometerReadingEvent(
          reading: 1100,
          recordedAt: DateTime(2026, 6, 2, 8),
        ),
        OdometerReadingEvent(
          reading: 1200,
          recordedAt: DateTime(2026, 6, 3, 8),
        ),
        OdometerReadingEvent(
          reading: 1300,
          recordedAt: DateTime(2026, 6, 4, 8),
        ),
      ],
    );

    final result = controller.updateFromText(
      '2100',
      enteredAt: DateTime(2026, 6, 5, 8),
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.business,
      ),
    );

    expect(result.ok, isTrue);
    expect(result.requiresConfirmation, isFalse);
    expect(controller.reading, 2100);
  });

  test('weekday trend retains separate typical and maximum daily mileage', () {
    final trend = OdometerTrend.fromHistory(
      [
        OdometerReadingEvent(reading: 1000, recordedAt: DateTime(2026, 6, 7)),
        OdometerReadingEvent(reading: 1300, recordedAt: DateTime(2026, 6, 8)),
        OdometerReadingEvent(reading: 1400, recordedAt: DateTime(2026, 6, 9)),
        OdometerReadingEvent(reading: 1500, recordedAt: DateTime(2026, 6, 10)),
        OdometerReadingEvent(reading: 1600, recordedAt: DateTime(2026, 6, 11)),
        OdometerReadingEvent(reading: 1700, recordedAt: DateTime(2026, 6, 12)),
        OdometerReadingEvent(reading: 1800, recordedAt: DateTime(2026, 6, 13)),
        OdometerReadingEvent(reading: 1900, recordedAt: DateTime(2026, 6, 14)),
        OdometerReadingEvent(reading: 2200, recordedAt: DateTime(2026, 6, 15)),
        OdometerReadingEvent(reading: 2300, recordedAt: DateTime(2026, 6, 16)),
      ],
      currentReading: 2300,
      enteredAt: DateTime(2026, 6, 16),
    );

    expect(trend.averageDailyMilesForWeekday(DateTime.monday), 300);
    expect(trend.maximumDailyMilesForWeekday(DateTime.monday), 300);
    expect(trend.maximumObservedDailyMiles, 300);
  });

  test(
    'opt-in daily average review flags unusually low mileage for the trend',
    () {
      final controller = GlobalOdometerController(
        initialReading: 1300,
        validationPolicy: const OdometerValidationPolicy(
          drivingPatternReviewEnabled: true,
        ),
        initialHistory: [
          OdometerReadingEvent(
            reading: 1000,
            recordedAt: DateTime(2026, 6, 1, 8),
          ),
          OdometerReadingEvent(
            reading: 1100,
            recordedAt: DateTime(2026, 6, 2, 8),
          ),
          OdometerReadingEvent(
            reading: 1200,
            recordedAt: DateTime(2026, 6, 3, 8),
          ),
          OdometerReadingEvent(
            reading: 1300,
            recordedAt: DateTime(2026, 6, 4, 8),
          ),
        ],
      );

      final result = controller.updateFromText(
        '1310',
        enteredAt: DateTime(2026, 6, 7, 8),
        mileageReview: const OdometerMileageReview(
          use: OdometerMileageUse.business,
        ),
      );

      expect(result.ok, isFalse);
      expect(result.requiresConfirmation, isTrue);
      expect(
        result.message,
        contains('lower than the vehicle usually records'),
      );
      expect(controller.reading, 1300);
    },
  );

  test('confirmed suspicious odometer reading is accepted and marked', () {
    final review = const OdometerMileageReview(
      use: OdometerMileageUse.business,
    );
    final controller = GlobalOdometerController(
      initialReading: 1300,
      validationPolicy: const OdometerValidationPolicy(
        drivingPatternReviewEnabled: true,
      ),
      initialHistory: [
        OdometerReadingEvent(
          reading: 1000,
          recordedAt: DateTime(2026, 6, 1, 8),
        ),
        OdometerReadingEvent(
          reading: 1100,
          recordedAt: DateTime(2026, 6, 2, 8),
        ),
        OdometerReadingEvent(
          reading: 1200,
          recordedAt: DateTime(2026, 6, 3, 8),
        ),
        OdometerReadingEvent(
          reading: 1300,
          recordedAt: DateTime(2026, 6, 4, 8),
        ),
      ],
    );

    final result = controller.updateFromText(
      '2100',
      enteredAt: DateTime(2026, 6, 5, 8),
      confirmSuspicious: true,
      mileageReview: review,
    );

    expect(result.ok, isTrue);
    expect(result.wasConfirmed, isTrue);
    expect(result.mileageReview, review);
    expect(controller.reading, 2100);
    expect(controller.history.length, 5);
  });

  test(
    'lower unresolved correction is queued and can be resolved later',
    () async {
      final controller = GlobalOdometerController(initialReading: 1000);

      final result = controller.updateFromText(
        '950',
        correctionReview: const OdometerCorrectionReview(
          reason: OdometerCorrectionReason.unresolved,
        ),
        workProfileId: 'night_route',
        sourceType: 'receipt',
        sourceId: 'fuel-7',
      );

      expect(result.ok, isTrue);
      expect(result.affectsCurrentReading, isFalse);
      expect(controller.unresolvedCorrectionEvents.length, 1);
      final event = controller.unresolvedCorrectionEvents.single;
      expect(event.workProfileId, 'night_route');
      expect(event.sourceType, 'receipt');
      expect(event.sourceId, 'fuel-7');

      final resolved = await controller.resolveCorrectionReview(
        eventId: event.id,
        review: const OdometerCorrectionReview(
          reason: OdometerCorrectionReason.backdatedEntry,
        ),
      );

      expect(resolved, isTrue);
      expect(controller.unresolvedCorrectionEvents, isEmpty);
      expect(
        controller.history.last.correctionReview?.reason,
        OdometerCorrectionReason.backdatedEntry,
      );
    },
  );

  test('odometer event metadata survives snapshot serialization', () {
    final event = OdometerReadingEvent(
      id: 'event-1',
      reading: 1234,
      recordedAt: DateTime(2026, 6, 12, 8),
      previousReading: 1200,
      workProfileId: 'main_work',
      sourceType: 'expense_receipt',
      sourceId: 'receipt-9',
      mileageReview: const OdometerMileageReview(
        use: OdometerMileageUse.split,
        businessMiles: 20,
      ),
    );
    final restored = OdometerReadingEvent.fromMap(event.toMap());

    expect(restored.id, 'event-1');
    expect(restored.previousReading, 1200);
    expect(restored.workProfileId, 'main_work');
    expect(restored.sourceType, 'expense_receipt');
    expect(restored.sourceId, 'receipt-9');
    expect(restored.mileageReview?.businessMiles, 20);
  });

  test('restored odometer event metadata is trimmed and bounded', () {
    final restored = OdometerReadingEvent.fromMap({
      'id': 'event-metadata',
      'reading': 1234,
      'recordedAt': DateTime(2026, 6, 12, 8).toIso8601String(),
      'workProfileId': '  work\nprofile  ',
      'sourceType': ' gps_trip_review\t',
      'sourceId': ' ${'trip' * 80} ',
    });

    expect(restored.workProfileId, 'work profile');
    expect(restored.sourceType, 'gps_trip_review');
    expect(restored.sourceId, hasLength(160));
    expect(restored.sourceId, isNot(contains('\n')));
  });

  test('odometer event serialization never writes negative readings', () {
    final event = OdometerReadingEvent(
      id: 'event-negative',
      reading: -10,
      recordedAt: DateTime(2026, 6, 12, 8),
      previousReading: -20,
    );
    final map = event.toMap();
    final restored = OdometerReadingEvent.fromMap({
      ...map,
      'reading': -30,
      'previousReading': -40,
    });

    expect(map['reading'], isZero);
    expect(map['previousReading'], isNull);
    expect(restored.reading, isZero);
    expect(restored.previousReading, isNull);
  });

  test('odometer mileage review never persists negative business miles', () {
    const review = OdometerMileageReview(
      use: OdometerMileageUse.split,
      businessMiles: -5,
    );
    final restored = OdometerMileageReview.fromMap({
      'use': 'split',
      'businessMiles': -10,
    });

    expect(review.toMap()['businessMiles'], isNull);
    expect(restored.businessMiles, isNull);
    expect(restored.businessMilesForDelta(100), isZero);
  });

  test('odometer review notes are sanitized on restore and persistence', () {
    final mileage = OdometerMileageReview.fromMap({
      'use': 'split',
      'businessMiles': 10,
      'note': ' first line\n${'m' * 300} ',
    });
    final correction = OdometerCorrectionReview.fromMap({
      'reason': 'backdatedEntry',
      'note': ' second\tline\n${'c' * 300} ',
    });

    expect(mileage.note, hasLength(240));
    expect(mileage.note, isNot(contains('\n')));
    expect(mileage.toMap()['note'], mileage.note);
    expect(correction.note, hasLength(240));
    expect(correction.note, isNot(contains('\t')));
    expect(correction.toMap()['note'], correction.note);
  });

  test('vehicle labels normalize into stable temporary odometer keys', () {
    expect(odometerVehicleIdForLabel('Work Truck 1'), 'work_truck_1');
    expect(odometerVehicleIdForLabel('  Ram 2500 / Crew  '), 'ram_2500_crew');
    expect(odometerVehicleIdForLabel(''), defaultVehicleId);
  });

  test('stable vehicle identity survives an editable nickname change', () {
    const vehicleId = 'vehicle_9c5f0f';

    expect(
      odometerVehicleIdForVehicleId(vehicleId, fallbackLabel: 'Work Truck 1'),
      vehicleId,
    );
    expect(
      odometerVehicleIdForVehicleId(vehicleId, fallbackLabel: 'Blue F-150'),
      vehicleId,
    );
  });

  test(
    'live GPS trip projection updates display without overwriting audit odometer',
    () {
      final controller = GlobalOdometerController(initialReading: 1000);

      expect(
        controller.beginLiveTripProjection(
          tripId: 'trip_1',
          startingOdometer: 1000,
        ),
        isTrue,
      );
      expect(
        controller.updateLiveTripProjection(
          tripId: 'trip_1',
          estimatedOdometer: 1002,
        ),
        isTrue,
      );
      expect(controller.reading, 1002);
      expect(controller.confirmedReading, 1000);
      expect(controller.liveTripDeltaMiles, 2);
      expect(controller.liveTripDisplayLabel, 'Live GPS odometer');
      expect(controller.liveTripUpdatedAt, isNotNull);
      final dashboardMap = controller.liveDisplaySnapshot.toSafeDashboardMap(
        DateTime.now(),
      );
      expect(dashboardMap['displayValue'], '0001002');
      expect(dashboardMap['confirmedDisplayValue'], '0001000');
      expect(dashboardMap['confirmedReadingIsCanonical'], isTrue);
      expect(dashboardMap['liveUiMustRefreshOnProjectionChange'], isTrue);
      expect(dashboardMap['remoteProjectionRequiresMatchingTripId'], isTrue);
      expect(dashboardMap['staleProjectionCanCommitMileage'], isFalse);
      expect(dashboardMap['rawGpsIncluded'], isFalse);
      expect(dashboardMap['routeGeometryIncluded'], isFalse);
      expect(dashboardMap['mapboxMayOverrideOdometer'], isFalse);
      expect(controller.updateFromText('1003').ok, isFalse);
      expect(controller.clearLiveTripProjection(tripId: 'trip_1'), isTrue);
      expect(controller.reading, 1000);
      expect(controller.liveTripDeltaMiles, 0);
      expect(controller.liveTripDisplayLabel, 'Odometer');
      expect(controller.liveTripUpdatedAt, isNull);
    },
  );

  test('live GPS trip projection rejects unsafe trip ids', () {
    final controller = GlobalOdometerController(initialReading: 1000);

    expect(
      controller.beginLiveTripProjection(
        tripId: ' trip_1 ',
        startingOdometer: 1000,
      ),
      isFalse,
    );
    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_\n1',
        startingOdometer: 1000,
      ),
      isFalse,
    );
    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_${'x' * 200}',
        startingOdometer: 1000,
      ),
      isFalse,
    );
    expect(controller.hasLiveTripProjection, isFalse);
  });

  test('live GPS trip projection rejects over-range odometer estimates', () {
    final controller = GlobalOdometerController(
      initialReading: 1000,
      validationPolicy: const OdometerValidationPolicy(
        maxSupportedReading: 2000,
      ),
    );

    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_1',
        startingOdometer: 2001,
      ),
      isFalse,
    );
    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_1',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      controller.updateLiveTripProjection(
        tripId: 'trip_1',
        estimatedOdometer: 2001,
      ),
      isFalse,
    );
    expect(controller.reading, 1000);
  });

  test('live GPS trip projection cannot start above confirmed odometer', () {
    final controller = GlobalOdometerController(initialReading: 1000);

    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_future_baseline',
        startingOdometer: 1001,
      ),
      isFalse,
    );
    expect(controller.hasLiveTripProjection, isFalse);
    expect(controller.reading, 1000);
    expect(controller.confirmedReading, 1000);
  });

  test(
    'stale GPS trip projection updates cannot move a restarted odometer',
    () {
      final controller = GlobalOdometerController(initialReading: 1000);

      expect(
        controller.beginLiveTripProjection(
          tripId: 'trip_original',
          startingOdometer: 1000,
        ),
        isTrue,
      );
      expect(
        controller.clearLiveTripProjection(tripId: 'trip_original'),
        isTrue,
      );
      expect(
        controller.beginLiveTripProjection(
          tripId: 'trip_restarted',
          startingOdometer: 1000,
        ),
        isTrue,
      );

      expect(
        controller.updateLiveTripProjection(
          tripId: 'trip_original',
          estimatedOdometer: 1005,
        ),
        isFalse,
      );
      expect(controller.reading, 1000);
      expect(controller.confirmedReading, 1000);
    },
  );

  test('lower live GPS projections are ignored without stale UI rollback', () {
    final controller = GlobalOdometerController(initialReading: 1000);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    expect(
      controller.beginLiveTripProjection(
        tripId: 'trip_monotonic',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      controller.updateLiveTripProjection(
        tripId: 'trip_monotonic',
        estimatedOdometer: 1004,
      ),
      isTrue,
    );
    final updatedAt = controller.liveTripUpdatedAt;
    expect(
      controller.updateLiveTripProjection(
        tripId: 'trip_monotonic',
        estimatedOdometer: 1002,
      ),
      isTrue,
    );

    expect(controller.reading, 1004);
    expect(controller.confirmedReading, 1000);
    expect(controller.liveTripUpdatedAt, updatedAt);
    expect(controller.liveDisplaySnapshot.displayValue, '0001004');
    expect(notifications, 2);
  });

  test(
    'an active GPS trip prevents switching the active odometer vehicle',
    () async {
      final controller = GlobalOdometerController(initialReading: 1000);
      controller.beginLiveTripProjection(
        tripId: 'trip_1',
        startingOdometer: 1000,
      );

      final switched = await controller.switchVehicleById(
        'vehicle_second',
        fallbackReading: 2000,
      );

      expect(switched, isFalse);
      expect(controller.vehicleId, defaultVehicleId);
      expect(controller.reading, 1000);
      expect(controller.hasLiveTripProjection, isTrue);
    },
  );
}
