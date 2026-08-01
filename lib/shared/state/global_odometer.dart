import 'dart:async';

import 'package:flutter/widgets.dart';

import '../odometer/odometer_correction_review.dart';
import '../odometer/odometer_distance_value.dart';
import '../odometer/odometer_entry_plausibility_policy.dart';
import '../odometer/live_odometer_display.dart';
import '../odometer/odometer_mileage_review.dart';
import '../odometer/odometer_validation.dart';
import '../odometer/odometer_vehicle_snapshot.dart';

class GlobalOdometerController extends ChangeNotifier {
  GlobalOdometerController({
    String vehicleId = defaultVehicleId,
    int initialReading = 298150,
    int? initialReadingTenths,
    DateTime? initialRecordedAt,
    List<OdometerReadingEvent>? initialHistory,
    OdometerValidationPolicy validationPolicy =
        const OdometerValidationPolicy(),
    OdometerEntryPlausibilityPolicy plausibilityPolicy =
        const OdometerEntryPlausibilityPolicy(),
    Future<OdometerVehicleSnapshot> Function(
      String vehicleId, {
      int fallbackReading,
    })?
    snapshotReader,
    Future<void> Function(OdometerVehicleSnapshot snapshot)? snapshotWriter,
  }) : _vehicleId = safeOdometerVehicleId(vehicleId),
       _reading = _safeOdometerReading(initialReading),
       _readingTenths = _safeInitialTenths(
         initialReading,
         initialReadingTenths,
       ),
       _validationPolicy = validationPolicy,
       _plausibilityPolicy = plausibilityPolicy,
       _drivingPatternReviewEnabled =
           validationPolicy.drivingPatternReviewEnabled,
       _snapshotReader = snapshotReader,
       _snapshotWriter = snapshotWriter,
       _history = initialHistory == null || initialHistory.isEmpty
           ? [
               OdometerReadingEvent(
                 reading: _safeOdometerReading(initialReading),
                 readingTenths: _safeInitialTenths(
                   initialReading,
                   initialReadingTenths,
                 ),
                 recordedAt: initialRecordedAt ?? DateTime.now(),
                 affectsCurrentReading: true,
               ),
             ]
           : [...initialHistory];

  int _reading;
  int _readingTenths;
  String _vehicleId;
  String? _liveTripId;
  int? _liveTripEstimatedReading;
  int? _liveTripEstimatedTenths;
  DateTime? _liveTripUpdatedAt;
  var _liveTripProjectionRevision = 0;
  var _eventSequence = 0;
  final OdometerValidationPolicy _validationPolicy;
  final OdometerEntryPlausibilityPolicy _plausibilityPolicy;
  bool _drivingPatternReviewEnabled;
  final Future<OdometerVehicleSnapshot> Function(
    String vehicleId, {
    int fallbackReading,
  })?
  _snapshotReader;
  final Future<void> Function(OdometerVehicleSnapshot snapshot)?
  _snapshotWriter;
  final List<OdometerReadingEvent> _history;

  /// The current display reading. During a GPS-assisted trip this includes the
  /// live estimate, while [confirmedReading] remains the audit source of truth.
  int get reading => _liveTripEstimatedReading ?? _reading;
  int get confirmedReading => _reading;
  int get confirmedReadingTenths => _readingTenths;
  String get vehicleId => _vehicleId;
  int get maxSupportedReading => _validationPolicy.maxSupportedReading;
  bool get hasLiveTripProjection => _liveTripId != null;
  String? get activeLiveTripId => _liveTripId;
  DateTime? get liveTripUpdatedAt => _liveTripUpdatedAt;
  int get liveTripProjectionRevision => _liveTripProjectionRevision;
  int get liveTripDeltaMiles => hasLiveTripProjection ? reading - _reading : 0;
  String get liveTripDisplayLabel =>
      hasLiveTripProjection ? 'Live GPS odometer' : 'Odometer';
  LiveOdometerDisplaySnapshot get liveDisplaySnapshot =>
      LiveOdometerDisplaySnapshot(
        confirmedReading: _reading,
        confirmedReadingTenths: _readingTenths,
        displayReading: reading,
        displayTenths: hasLiveTripProjection
            ? _liveTripEstimatedTenths
            : _readingTenths,
        isLive: hasLiveTripProjection,
        liveUpdatedAt: _liveTripUpdatedAt,
        projectionRevision: _liveTripProjectionRevision,
      );
  List<OdometerReadingEvent> get history => List.unmodifiable(_history);
  List<OdometerReadingEvent> get unresolvedMileageEvents => _history
      .where(
        (event) => event.mileageReview?.use == OdometerMileageUse.unresolved,
      )
      .toList(growable: false);
  List<OdometerReadingEvent> get unresolvedCorrectionEvents => _history
      .where(
        (event) =>
            event.correctionReview?.reason ==
            OdometerCorrectionReason.unresolved,
      )
      .toList(growable: false);

  String get displayValue => liveDisplaySnapshot.displayValue;
  bool get drivingPatternReviewEnabled => _drivingPatternReviewEnabled;

  OdometerVehicleSnapshot get snapshot => OdometerVehicleSnapshot(
    vehicleId: _vehicleId,
    currentReading: _reading,
    currentReadingTenths: _readingTenths,
    updatedAt: DateTime.now(),
    history: history,
    drivingPatternReviewEnabled: _drivingPatternReviewEnabled,
  );

  /// Prevent changing vehicles while an active GPS trip is projecting the
  /// odometer. That trip has one vehicle identity and must be reviewed first.
  Future<bool> switchVehicle(OdometerVehicleSnapshot snapshot) async {
    if (hasLiveTripProjection) return false;
    await _persistSnapshot();
    _vehicleId = snapshot.vehicleId;
    _reading = _safeOdometerReading(snapshot.currentReading);
    _readingTenths = snapshot.effectiveCurrentReadingTenths;
    _drivingPatternReviewEnabled = snapshot.drivingPatternReviewEnabled;
    _history
      ..clear()
      ..addAll(
        snapshot.history.isEmpty
            ? [
                OdometerReadingEvent(
                  reading: _safeOdometerReading(snapshot.currentReading),
                  readingTenths: snapshot.effectiveCurrentReadingTenths,
                  recordedAt: snapshot.updatedAt,
                ),
              ]
            : snapshot.history,
      );
    notifyListeners();
    await _persistSnapshot();
    return true;
  }

  Future<void> setDrivingPatternReviewEnabled(bool enabled) async {
    if (_drivingPatternReviewEnabled == enabled) return;
    _drivingPatternReviewEnabled = enabled;
    notifyListeners();
    await _persistSnapshot();
  }

  bool beginLiveTripProjection({
    required String tripId,
    required int startingOdometer,
    int? startingOdometerTenths,
    DateTime? observedAtUtc,
  }) {
    if (!_isSafeLiveTripId(tripId) || hasLiveTripProjection) return false;
    final safeStartingTenths = startingOdometerTenths ?? startingOdometer * 10;
    if (startingOdometer != _reading ||
        safeStartingTenths != _readingTenths ||
        startingOdometer > _validationPolicy.maxSupportedReading) {
      return false;
    }
    _liveTripId = tripId;
    _liveTripEstimatedReading = startingOdometer;
    _liveTripEstimatedTenths = startingOdometerTenths;
    _liveTripUpdatedAt = _safeBeginLiveProjectionUpdateTime(observedAtUtc);
    _liveTripProjectionRevision += 1;
    notifyListeners();
    return true;
  }

  bool updateLiveTripProjection({
    required String tripId,
    required int estimatedOdometer,
    int? estimatedOdometerTenths,
    DateTime? observedAtUtc,
    DateTime? receivedAtUtc,
    Duration staleAfter = const Duration(minutes: 5),
  }) {
    final trustedUpdateAt = _safeLiveProjectionUpdateTime(
      observedAtUtc,
      receivedAtUtc: receivedAtUtc,
      currentUpdatedAt: _liveTripUpdatedAt,
      staleAfter: staleAfter,
    );
    final hasTenths = estimatedOdometerTenths != null;
    final safeTenths = estimatedOdometerTenths ?? estimatedOdometer * 10;
    if (_liveTripId != tripId ||
        estimatedOdometer < _reading ||
        estimatedOdometer > _validationPolicy.maxSupportedReading ||
        safeTenths < _reading * 10 ||
        safeTenths > _validationPolicy.maxSupportedReading * 10 ||
        trustedUpdateAt == null) {
      return false;
    }
    final current = _liveTripEstimatedReading ?? _reading;
    final currentTenths = _liveTripEstimatedTenths ?? current * 10;
    if (estimatedOdometer < current) return true;
    if (safeTenths < currentTenths) return true;
    if (estimatedOdometer == current) {
      final tenthsAdvanced = hasTenths && safeTenths > currentTenths;
      final timestampCanRefresh = _liveProjectionTimestampCanRefresh(
        trustedUpdateAt,
        currentUpdatedAt: _liveTripUpdatedAt,
      );
      if (tenthsAdvanced || timestampCanRefresh) {
        if (tenthsAdvanced) _liveTripEstimatedTenths = safeTenths;
        if (timestampCanRefresh) {
          _liveTripUpdatedAt = trustedUpdateAt;
        }
        _liveTripProjectionRevision += 1;
        notifyListeners();
      }
      return true;
    }
    _liveTripEstimatedReading = estimatedOdometer;
    _liveTripEstimatedTenths = hasTenths ? safeTenths : null;
    _liveTripUpdatedAt = trustedUpdateAt;
    _liveTripProjectionRevision += 1;
    notifyListeners();
    return true;
  }

  bool clearLiveTripProjection({required String tripId}) {
    if (_liveTripId != tripId) return false;
    _liveTripId = null;
    _liveTripEstimatedReading = null;
    _liveTripEstimatedTenths = null;
    _liveTripUpdatedAt = null;
    _liveTripProjectionRevision += 1;
    notifyListeners();
    return true;
  }

  Future<bool> switchVehicleById(
    String vehicleId, {
    int fallbackReading = 298150,
  }) async {
    if (hasLiveTripProjection) return false;
    final reader = _snapshotReader;
    if (reader == null) {
      return switchVehicle(
        OdometerVehicleSnapshot(
          vehicleId: vehicleId,
          currentReading: fallbackReading,
          updatedAt: DateTime.now(),
          history: const [],
        ),
      );
    }
    final snapshot = await reader(vehicleId, fallbackReading: fallbackReading);
    return switchVehicle(snapshot);
  }

  /// Reads another vehicle's durable odometer snapshot without changing this
  /// controller's active vehicle, history, or live GPS projection.
  ///
  /// Context-handoff review flows consume this before explicit confirmation.
  /// It never persists a fallback snapshot: a missing local record is only an
  /// in-memory zero-mile preview until the user confirms a real reading.
  Future<OdometerVehicleSnapshot> previewVehicleSnapshot(
    String vehicleId,
  ) async {
    final safeVehicleId = safeOdometerVehicleId(vehicleId);
    if (safeVehicleId == _vehicleId) return snapshot;
    final reader = _snapshotReader;
    final loaded = reader == null
        ? null
        : await reader(safeVehicleId, fallbackReading: 0);
    if (loaded == null) {
      return OdometerVehicleSnapshot(
        vehicleId: safeVehicleId,
        currentReading: 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        history: const [],
      );
    }
    return OdometerVehicleSnapshot(
      vehicleId: safeVehicleId,
      currentReading: _safeOdometerReading(loaded.currentReading),
      updatedAt: loaded.updatedAt,
      history: List.unmodifiable(loaded.history),
      drivingPatternReviewEnabled: loaded.drivingPatternReviewEnabled,
    );
  }

  OdometerUpdateResult updateFromText(
    String rawValue, {
    DateTime? enteredAt,
    bool confirmSuspicious = false,
    bool commit = true,
    OdometerMileageReview? mileageReview,
    OdometerCorrectionReview? correctionReview,
    String? workProfileId,
    String? sourceType,
    String? sourceId,
    OdometerEntryPlausibilityContext? plausibilityContext,
    OdometerDistanceUnit distanceUnit = OdometerDistanceUnit.miles,
    OdometerNumberConvention numberConvention =
        OdometerNumberConvention.decimalPoint,
  }) {
    final effectiveUnit = plausibilityContext?.distanceUnit ?? distanceUnit;
    final exact = OdometerDistanceValue.tryParse(
      rawValue,
      unit: effectiveUnit,
      convention: numberConvention,
    );
    if (exact == null) {
      final legacyWhole = parseOdometerInput(rawValue);
      if (legacyWhole != null) {
        final legacyValidation = _validationPolicy.validate(
          currentReading: _reading,
          candidateReading: legacyWhole,
          history: _history,
          enteredAt: enteredAt ?? DateTime.now(),
          drivingPatternReviewEnabled: _drivingPatternReviewEnabled,
        );
        if (legacyValidation.isBlocked) {
          return OdometerUpdateResult.error(legacyValidation.message);
        }
      }
      return const OdometerUpdateResult.error(
        'Enter a whole odometer number or one optional decimal digit.',
      );
    }
    final parsedTenths = exact.tenths;
    final parsed = parsedTenths ~/ 10;
    final existingSourceEvent = _eventForSource(sourceType, sourceId);
    if (existingSourceEvent != null) {
      final sourceLabel = _odometerSourceLabel(sourceType);
      if (existingSourceEvent.effectiveReadingTenths == parsedTenths) {
        return OdometerUpdateResult.success(
          message:
              'This odometer reading is already recorded for this $sourceLabel.',
          mileageReview: existingSourceEvent.mileageReview,
          correctionReview: existingSourceEvent.correctionReview,
          affectsCurrentReading: existingSourceEvent.affectsCurrentReading,
        );
      }
      return OdometerUpdateResult.error(
        'This $sourceLabel already has a different odometer history entry. Use the odometer correction flow before changing it.',
      );
    }
    if (parsedTenths < _readingTenths) {
      return _handleLowerReading(
        parsed,
        parsedTenths: parsedTenths,
        enteredAt: enteredAt ?? DateTime.now(),
        correctionReview: correctionReview,
        commit: commit,
        workProfileId: workProfileId,
        sourceType: sourceType,
        sourceId: sourceId,
      );
    }
    final validation = _validationPolicy.validate(
      currentReading: _reading,
      candidateReading: parsed,
      history: _history,
      enteredAt: enteredAt ?? DateTime.now(),
      drivingPatternReviewEnabled: _drivingPatternReviewEnabled,
    );
    if (validation.isBlocked) {
      return OdometerUpdateResult.error(validation.message);
    }

    final deltaTenths = parsedTenths - _readingTenths;
    final deltaMiles = parsed - _reading;
    if (plausibilityContext != null) {
      final current = OdometerDistanceValue.fromTenths(
        tenths: _readingTenths,
        unit: plausibilityContext.distanceUnit,
      );
      final candidate = OdometerDistanceValue.fromTenths(
        tenths: parsedTenths,
        unit: plausibilityContext.distanceUnit,
      );
      if (current != null && candidate != null) {
        final plausibility = _plausibilityPolicy.evaluate(
          current: current,
          candidate: candidate,
          enteredAt: enteredAt ?? DateTime.now(),
          context: plausibilityContext,
        );
        if (plausibility.requiresReview && !confirmSuspicious) {
          return OdometerUpdateResult.needsConfirmation(
            plausibility.explanation,
            mileageReview: mileageReview,
          );
        }
      }
    }
    final gpsDifferenceMiles = hasLiveTripProjection
        ? (parsed - reading).abs()
        : 0;
    if (deltaTenths > 0 && mileageReview == null) {
      return OdometerUpdateResult.mileageReviewRequired(
        message: odometerMileageReviewPromptTenths(deltaTenths),
        deltaMiles: deltaMiles,
      );
    }
    if (deltaTenths > 0 && mileageReview != null) {
      final reviewError = validateOdometerMileageReview(
        deltaMiles: deltaMiles,
        deltaTenths: deltaTenths,
        review: mileageReview,
      );
      if (reviewError != null) {
        return OdometerUpdateResult.error(reviewError);
      }
    }
    if (validation.needsConfirmation && !confirmSuspicious) {
      return OdometerUpdateResult.needsConfirmation(
        validation.message,
        mileageReview: mileageReview,
      );
    }
    if (gpsDifferenceMiles >= 50 && !confirmSuspicious) {
      return OdometerUpdateResult.needsConfirmation(
        'Your reading differs from the live GPS estimate by '
        '$gpsDifferenceMiles miles. GPS is only a suggestion; double-check '
        'the vehicle odometer, then confirm your reading if it is correct.',
        mileageReview: mileageReview,
      );
    }

    return _acceptReading(
      parsed,
      parsedTenths: parsedTenths,
      enteredAt: enteredAt ?? DateTime.now(),
      message: validation.message,
      wasConfirmed: validation.needsConfirmation,
      commit: commit,
      mileageReview: mileageReview,
      workProfileId: workProfileId,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }

  OdometerUpdateResult _handleLowerReading(
    int parsed, {
    required int parsedTenths,
    required DateTime enteredAt,
    OdometerCorrectionReview? correctionReview,
    required bool commit,
    String? workProfileId,
    String? sourceType,
    String? sourceId,
  }) {
    if (correctionReview == null) {
      return OdometerUpdateResult.correctionReviewRequired(
        message: odometerCorrectionReviewPrompt(
          currentReading: _reading,
          candidateReading: parsed,
          currentReadingTenths: _readingTenths,
          candidateReadingTenths: parsedTenths,
        ),
        currentReading: _reading,
        candidateReading: parsed,
      );
    }

    final reviewError = validateOdometerCorrectionReview(
      currentReading: _reading,
      candidateReading: parsed,
      currentReadingTenths: _readingTenths,
      candidateReadingTenths: parsedTenths,
      review: correctionReview,
    );
    if (reviewError != null) {
      return OdometerUpdateResult.error(reviewError);
    }

    if (correctionReview.canSaveHistoricalReading ||
        correctionReview.reason == OdometerCorrectionReason.unresolved) {
      if (!commit) {
        return OdometerUpdateResult.success(
          message:
              'Lower odometer reading is ready to save for review. Current odometer remains $_reading.',
          correctionReview: correctionReview,
          affectsCurrentReading: false,
        );
      }
      _history.add(
        OdometerReadingEvent(
          id: _nextEventId(),
          reading: parsed,
          readingTenths: parsedTenths,
          recordedAt: enteredAt,
          correctionReview: correctionReview,
          affectsCurrentReading: false,
          previousReading: _reading,
          previousReadingTenths: _readingTenths,
          workProfileId: workProfileId,
          sourceType: sourceType,
          sourceId: sourceId,
        ),
      );
      notifyListeners();
      unawaited(_persistSnapshot());
      return OdometerUpdateResult.success(
        message:
            'Lower odometer reading saved for review. Current odometer remains $_reading.',
        correctionReview: correctionReview,
        affectsCurrentReading: false,
      );
    }

    return const OdometerUpdateResult.error(
      'This reading needs the odometer correction flow before it can be saved.',
    );
  }

  OdometerUpdateResult _acceptReading(
    int parsed, {
    required int parsedTenths,
    required DateTime enteredAt,
    required String message,
    required bool wasConfirmed,
    required bool commit,
    OdometerMileageReview? mileageReview,
    String? workProfileId,
    String? sourceType,
    String? sourceId,
  }) {
    if (parsedTenths == _readingTenths) {
      return OdometerUpdateResult.success(message: message);
    }
    if (!commit) {
      return OdometerUpdateResult.success(
        message: message,
        wasConfirmed: wasConfirmed,
        mileageReview: mileageReview,
      );
    }
    final previousReading = _reading;
    final previousReadingTenths = _readingTenths;
    _reading = parsed;
    _readingTenths = parsedTenths;
    if (hasLiveTripProjection) {
      _liveTripEstimatedReading = parsed;
      _liveTripEstimatedTenths = parsedTenths;
      _liveTripUpdatedAt = enteredAt;
      _liveTripProjectionRevision += 1;
    }
    _history.add(
      OdometerReadingEvent(
        id: _nextEventId(),
        reading: parsed,
        readingTenths: parsedTenths,
        recordedAt: enteredAt,
        mileageReview: mileageReview,
        previousReading: previousReading,
        previousReadingTenths: previousReadingTenths,
        workProfileId: workProfileId,
        sourceType: sourceType,
        sourceId: sourceId,
      ),
    );
    notifyListeners();
    unawaited(_persistSnapshot());
    return OdometerUpdateResult.success(
      message: message,
      wasConfirmed: wasConfirmed,
      mileageReview: mileageReview,
    );
  }

  OdometerReadingEvent? _eventForSource(String? sourceType, String? sourceId) {
    final type = sourceType?.trim() ?? '';
    final id = sourceId?.trim() ?? '';
    if (type.isEmpty || id.isEmpty) return null;
    for (final event in _history.reversed) {
      if (event.sourceType == type && event.sourceId == id) return event;
    }
    return null;
  }

  Future<void> applyAuditCorrection({
    required String rawValue,
    required OdometerCorrectionReview correctionReview,
    OdometerDistanceUnit distanceUnit = OdometerDistanceUnit.miles,
    OdometerNumberConvention numberConvention =
        OdometerNumberConvention.decimalPoint,
    DateTime? correctedAt,
    String? workProfileId,
    String? sourceType,
    String? sourceId,
  }) async {
    final exact = OdometerDistanceValue.tryParse(
      rawValue,
      unit: distanceUnit,
      convention: numberConvention,
    );
    if (exact == null) {
      throw ArgumentError(
        'Enter a whole odometer number or one optional decimal digit.',
      );
    }
    final parsedTenths = exact.tenths;
    final parsed = parsedTenths ~/ 10;
    if (!correctionReview.requiresDedicatedCorrectionFlow) {
      throw ArgumentError(
        'Audit corrections are only for previous-entry fixes, odometer replacement, rollover, or unit changes.',
      );
    }
    final validation = _validationPolicy.validate(
      currentReading: parsed,
      candidateReading: parsed,
      history: _history,
      enteredAt: correctedAt ?? DateTime.now(),
      drivingPatternReviewEnabled: _drivingPatternReviewEnabled,
    );
    if (validation.isBlocked) {
      throw ArgumentError(validation.message);
    }
    final previousReading = _reading;
    final previousReadingTenths = _readingTenths;
    _reading = parsed;
    _readingTenths = parsedTenths;
    if (hasLiveTripProjection) {
      _liveTripEstimatedReading = parsed;
      _liveTripEstimatedTenths = parsedTenths;
      _liveTripUpdatedAt = correctedAt ?? DateTime.now();
      _liveTripProjectionRevision += 1;
    }
    _history.add(
      OdometerReadingEvent(
        id: _nextEventId(),
        reading: parsed,
        readingTenths: parsedTenths,
        recordedAt: correctedAt ?? DateTime.now(),
        correctionReview: correctionReview,
        previousReading: previousReading,
        previousReadingTenths: previousReadingTenths,
        workProfileId: workProfileId,
        sourceType: sourceType,
        sourceId: sourceId,
      ),
    );
    notifyListeners();
    await _persistSnapshot();
  }

  Future<bool> resolveMileageReview({
    required String eventId,
    required OdometerMileageReview review,
  }) async {
    final index = _history.indexWhere((event) => event.id == eventId);
    if (index < 0) return false;
    final event = _history[index];
    final deltaMiles =
        (event.reading - (event.previousReading ?? event.reading)).abs();
    final reviewError = validateOdometerMileageReview(
      deltaMiles: deltaMiles,
      review: review,
    );
    if (reviewError != null) {
      throw ArgumentError(reviewError);
    }
    _history[index] = event.copyWith(mileageReview: review);
    notifyListeners();
    await _persistSnapshot();
    return true;
  }

  Future<bool> resolveCorrectionReview({
    required String eventId,
    required OdometerCorrectionReview review,
  }) async {
    final index = _history.indexWhere((event) => event.id == eventId);
    if (index < 0) return false;
    _history[index] = _history[index].copyWith(correctionReview: review);
    notifyListeners();
    await _persistSnapshot();
    return true;
  }

  Future<void> _persistSnapshot() async {
    final writer = _snapshotWriter;
    if (writer == null) return;
    await writer(snapshot);
  }

  String _nextEventId() {
    _eventSequence += 1;
    return '${_vehicleId}_${DateTime.now().microsecondsSinceEpoch}_$_eventSequence';
  }
}

bool _isSafeLiveTripId(String value) {
  final clean = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ').trim();
  return clean == value && clean.isNotEmpty && clean.length <= 160;
}

class OdometerUpdateResult {
  const OdometerUpdateResult._({
    required this.ok,
    required this.requiresConfirmation,
    required this.requiresMileageReview,
    required this.requiresCorrectionReview,
    this.message,
    this.deltaMiles,
    this.wasConfirmed = false,
    this.mileageReview,
    this.correctionReview,
    this.currentReading,
    this.candidateReading,
    this.affectsCurrentReading = true,
  });

  const OdometerUpdateResult.success({
    String? message,
    bool wasConfirmed = false,
    OdometerMileageReview? mileageReview,
    OdometerCorrectionReview? correctionReview,
    bool affectsCurrentReading = true,
  }) : this._(
         ok: true,
         requiresConfirmation: false,
         requiresMileageReview: false,
         requiresCorrectionReview: false,
         message: message,
         wasConfirmed: wasConfirmed,
         mileageReview: mileageReview,
         correctionReview: correctionReview,
         affectsCurrentReading: affectsCurrentReading,
       );

  const OdometerUpdateResult.error(String message)
    : this._(
        ok: false,
        requiresConfirmation: false,
        requiresMileageReview: false,
        requiresCorrectionReview: false,
        message: message,
      );

  const OdometerUpdateResult.needsConfirmation(
    String message, {
    OdometerMileageReview? mileageReview,
  }) : this._(
         ok: false,
         requiresConfirmation: true,
         requiresMileageReview: false,
         requiresCorrectionReview: false,
         message: message,
         mileageReview: mileageReview,
       );

  const OdometerUpdateResult.mileageReviewRequired({
    required String message,
    required int deltaMiles,
  }) : this._(
         ok: false,
         requiresConfirmation: false,
         requiresMileageReview: true,
         requiresCorrectionReview: false,
         message: message,
         deltaMiles: deltaMiles,
       );

  const OdometerUpdateResult.correctionReviewRequired({
    required String message,
    required int currentReading,
    required int candidateReading,
  }) : this._(
         ok: false,
         requiresConfirmation: false,
         requiresMileageReview: false,
         requiresCorrectionReview: true,
         message: message,
         currentReading: currentReading,
         candidateReading: candidateReading,
       );

  final bool ok;
  final bool requiresConfirmation;
  final bool requiresMileageReview;
  final bool requiresCorrectionReview;
  final String? message;
  final int? deltaMiles;
  final bool wasConfirmed;
  final OdometerMileageReview? mileageReview;
  final OdometerCorrectionReview? correctionReview;
  final int? currentReading;
  final int? candidateReading;
  final bool affectsCurrentReading;
}

class GlobalOdometerScope extends InheritedNotifier<GlobalOdometerController> {
  const GlobalOdometerScope({
    super.key,
    required GlobalOdometerController controller,
    required super.child,
  }) : super(notifier: controller);

  static GlobalOdometerController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GlobalOdometerScope>();
    assert(scope != null, 'GlobalOdometerScope is missing above this context.');
    return scope!.notifier!;
  }
}

String _odometerSourceLabel(String? sourceType) =>
    sourceType == 'gps_trip_review' ? 'GPS trip' : 'receipt';

int _safeOdometerReading(int value) => value < 0 ? 0 : value;

int _safeInitialTenths(int reading, int? tenths) {
  final safeReading = _safeOdometerReading(reading);
  final candidate = tenths ?? safeReading * 10;
  if (candidate < safeReading * 10 ||
      candidate > safeReading * 10 + 9 ||
      candidate > OdometerDistanceValue.maximumTenths) {
    return safeReading * 10;
  }
  return candidate;
}

DateTime _safeBeginLiveProjectionUpdateTime(DateTime? observedAtUtc) =>
    (observedAtUtc ?? DateTime.now()).toUtc();

DateTime? _safeLiveProjectionUpdateTime(
  DateTime? observedAtUtc, {
  DateTime? receivedAtUtc,
  DateTime? currentUpdatedAt,
  Duration staleAfter = const Duration(minutes: 5),
}) {
  final received = (receivedAtUtc ?? DateTime.now()).toUtc();
  final observed = (observedAtUtc ?? received).toUtc();
  if (observed.isAfter(received.add(const Duration(seconds: 30)))) {
    return null;
  }
  if (staleAfter > Duration.zero &&
      received.difference(observed) > staleAfter) {
    return null;
  }
  final current = currentUpdatedAt?.toUtc();
  if (current != null && observed.isBefore(current)) return null;
  return observed;
}

bool _liveProjectionTimestampCanRefresh(
  DateTime trustedUpdateAt, {
  DateTime? currentUpdatedAt,
}) {
  final current = currentUpdatedAt?.toUtc();
  if (current == null) return true;
  return trustedUpdateAt.toUtc().isAfter(current);
}
