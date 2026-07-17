import 'dart:async';

import 'package:flutter/widgets.dart';

import '../odometer/odometer_correction_review.dart';
import '../odometer/odometer_mileage_review.dart';
import '../odometer/odometer_validation.dart';
import '../odometer/odometer_vehicle_snapshot.dart';

class GlobalOdometerController extends ChangeNotifier {
  GlobalOdometerController({
    String vehicleId = defaultVehicleId,
    int initialReading = 298150,
    DateTime? initialRecordedAt,
    List<OdometerReadingEvent>? initialHistory,
    OdometerValidationPolicy validationPolicy =
        const OdometerValidationPolicy(),
    Future<OdometerVehicleSnapshot> Function(
      String vehicleId, {
      int fallbackReading,
    })?
    snapshotReader,
    Future<void> Function(OdometerVehicleSnapshot snapshot)? snapshotWriter,
  }) : _vehicleId = vehicleId,
       _reading = _safeOdometerReading(initialReading),
       _validationPolicy = validationPolicy,
       _drivingPatternReviewEnabled =
           validationPolicy.drivingPatternReviewEnabled,
       _snapshotReader = snapshotReader,
       _snapshotWriter = snapshotWriter,
       _history = initialHistory == null || initialHistory.isEmpty
           ? [
               OdometerReadingEvent(
                 reading: _safeOdometerReading(initialReading),
                 recordedAt: initialRecordedAt ?? DateTime.now(),
                 affectsCurrentReading: true,
               ),
             ]
           : [...initialHistory];

  int _reading;
  String _vehicleId;
  String? _liveTripId;
  int? _liveTripEstimatedReading;
  var _eventSequence = 0;
  final OdometerValidationPolicy _validationPolicy;
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
  String get vehicleId => _vehicleId;
  bool get hasLiveTripProjection => _liveTripId != null;
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

  String get displayValue => reading.toString().padLeft(7, '0');
  bool get drivingPatternReviewEnabled => _drivingPatternReviewEnabled;

  OdometerVehicleSnapshot get snapshot => OdometerVehicleSnapshot(
    vehicleId: _vehicleId,
    currentReading: _reading,
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
    _drivingPatternReviewEnabled = snapshot.drivingPatternReviewEnabled;
    _history
      ..clear()
      ..addAll(
        snapshot.history.isEmpty
            ? [
                OdometerReadingEvent(
                  reading: _safeOdometerReading(snapshot.currentReading),
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
  }) {
    if (!_isSafeLiveTripId(tripId) || hasLiveTripProjection) return false;
    if (startingOdometer != _reading ||
        startingOdometer > _validationPolicy.maxSupportedReading) {
      return false;
    }
    _liveTripId = tripId;
    _liveTripEstimatedReading = startingOdometer;
    notifyListeners();
    return true;
  }

  bool updateLiveTripProjection({
    required String tripId,
    required int estimatedOdometer,
  }) {
    if (_liveTripId != tripId ||
        estimatedOdometer < _reading ||
        estimatedOdometer > _validationPolicy.maxSupportedReading) {
      return false;
    }
    final current = _liveTripEstimatedReading ?? _reading;
    if (estimatedOdometer <= current) return true;
    _liveTripEstimatedReading = estimatedOdometer;
    notifyListeners();
    return true;
  }

  bool clearLiveTripProjection({required String tripId}) {
    if (_liveTripId != tripId) return false;
    _liveTripId = null;
    _liveTripEstimatedReading = null;
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
  }) {
    if (hasLiveTripProjection) {
      return const OdometerUpdateResult.error(
        'A GPS-assisted trip is active. End or review that trip before entering a manual odometer reading.',
      );
    }
    final parseError = parseOdometerInputError(rawValue);
    if (parseError != null) {
      return OdometerUpdateResult.error(parseError);
    }
    final parsed = parseOdometerInput(rawValue);
    if (parsed == null) {
      return const OdometerUpdateResult.error(
        'Use numbers only for the odometer reading.',
      );
    }
    final existingSourceEvent = _eventForSource(sourceType, sourceId);
    if (existingSourceEvent != null) {
      final sourceLabel = _odometerSourceLabel(sourceType);
      if (existingSourceEvent.reading == parsed) {
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
    if (parsed < _reading) {
      return _handleLowerReading(
        parsed,
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

    final deltaMiles = parsed - _reading;
    if (deltaMiles > 0 && mileageReview == null) {
      return OdometerUpdateResult.mileageReviewRequired(
        message: odometerMileageReviewPrompt(deltaMiles),
        deltaMiles: deltaMiles,
      );
    }
    if (deltaMiles > 0 && mileageReview != null) {
      final reviewError = validateOdometerMileageReview(
        deltaMiles: deltaMiles,
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

    return _acceptReading(
      parsed,
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
        ),
        currentReading: _reading,
        candidateReading: parsed,
      );
    }

    final reviewError = validateOdometerCorrectionReview(
      currentReading: _reading,
      candidateReading: parsed,
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
          recordedAt: enteredAt,
          correctionReview: correctionReview,
          affectsCurrentReading: false,
          previousReading: _reading,
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
    required DateTime enteredAt,
    required String message,
    required bool wasConfirmed,
    required bool commit,
    OdometerMileageReview? mileageReview,
    String? workProfileId,
    String? sourceType,
    String? sourceId,
  }) {
    if (parsed == _reading) {
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
    _reading = parsed;
    _history.add(
      OdometerReadingEvent(
        id: _nextEventId(),
        reading: parsed,
        recordedAt: enteredAt,
        mileageReview: mileageReview,
        previousReading: previousReading,
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
    DateTime? correctedAt,
    String? workProfileId,
    String? sourceType,
    String? sourceId,
  }) async {
    final parsed = parseOdometerInput(rawValue);
    if (parsed == null) {
      throw ArgumentError('Use numbers only for the odometer correction.');
    }
    if (!correctionReview.requiresDedicatedCorrectionFlow) {
      throw ArgumentError(
        'Audit corrections are only for previous-entry fixes or odometer replacement.',
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
    _reading = parsed;
    _history.add(
      OdometerReadingEvent(
        id: _nextEventId(),
        reading: parsed,
        recordedAt: correctedAt ?? DateTime.now(),
        correctionReview: correctionReview,
        previousReading: previousReading,
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
