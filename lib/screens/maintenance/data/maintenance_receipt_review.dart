import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'maintenance_receipt_parser.dart';

part 'maintenance_receipt_review_commands.dart';

/// User choices made after parsing and before any maintenance write.
enum MaintenanceReceiptReviewDecision {
  undecided,
  setupOnly,
  serviceOnly,
  setupAndService,
  expenseOnly,
  ignore,
}

enum MaintenanceReceiptSetupMode { basic, advanced }

class MaintenanceReceiptReviewItem {
  const MaintenanceReceiptReviewItem({
    required this.source,
    this.decision = MaintenanceReceiptReviewDecision.undecided,
    this.setupMode = MaintenanceReceiptSetupMode.basic,
    this.itemName,
    this.detailA,
    this.detailB,
    this.serviceDate,
    this.serviceOdometer,
    this.intervalMiles,
    this.intervalMonths,
    this.serviceDateEdited = false,
    this.serviceOdometerEdited = false,
    this.intervalMilesEdited = false,
    this.intervalMonthsEdited = false,
    this.confirmedPurchasedItemWasInstalled = false,
    this.confirmedWorkWasCompleted = false,
    this.confirmedReturnOrExchangeResolved = false,
    this.confirmedOdometerConflict = false,
  });

  final MaintenanceReceiptCandidate source;
  final MaintenanceReceiptReviewDecision decision;
  final MaintenanceReceiptSetupMode setupMode;
  final String? itemName;
  final String? detailA;
  final String? detailB;
  final DateTime? serviceDate;
  final int? serviceOdometer;
  final int? intervalMiles;
  final int? intervalMonths;
  final bool serviceDateEdited;
  final bool serviceOdometerEdited;
  final bool intervalMilesEdited;
  final bool intervalMonthsEdited;
  final bool confirmedPurchasedItemWasInstalled;
  final bool confirmedWorkWasCompleted;
  final bool confirmedReturnOrExchangeResolved;
  final bool confirmedOdometerConflict;

  String get effectiveItemName => (itemName ?? source.itemName).trim();
  String? get suggestedDetailA => _clean(detailA ?? source.detailA);
  String? get suggestedDetailB => _clean(detailB ?? source.detailB);
  String? get effectiveDetailA =>
      setupMode == MaintenanceReceiptSetupMode.advanced
      ? suggestedDetailA
      : null;
  String? get effectiveDetailB =>
      setupMode == MaintenanceReceiptSetupMode.advanced
      ? suggestedDetailB
      : null;
  DateTime? get effectiveServiceDate =>
      serviceDateEdited ? serviceDate : source.serviceDate;
  int? get effectiveServiceOdometer =>
      serviceOdometerEdited ? serviceOdometer : source.serviceOdometer;
  int? get effectiveIntervalMiles =>
      intervalMilesEdited ? intervalMiles : source.intervalMiles;
  int? get effectiveIntervalMonths =>
      intervalMonthsEdited ? intervalMonths : source.intervalMonths;

  MaintenanceReceiptReviewDecision get recommendedDecision =>
      switch (source.action) {
        MaintenanceReceiptAction.reviewTrackingSetup =>
          MaintenanceReceiptReviewDecision.setupOnly,
        MaintenanceReceiptAction.reviewCompletedService =>
          MaintenanceReceiptReviewDecision.setupAndService,
        MaintenanceReceiptAction.manualReview =>
          MaintenanceReceiptReviewDecision.undecided,
      };

  MaintenanceReceiptReviewItem copyWith({
    MaintenanceReceiptReviewDecision? decision,
    MaintenanceReceiptSetupMode? setupMode,
    String? itemName,
    String? detailA,
    String? detailB,
    DateTime? serviceDate,
    int? serviceOdometer,
    int? intervalMiles,
    int? intervalMonths,
    bool clearServiceDate = false,
    bool clearServiceOdometer = false,
    bool clearIntervalMiles = false,
    bool clearIntervalMonths = false,
    bool? confirmedPurchasedItemWasInstalled,
    bool? confirmedWorkWasCompleted,
    bool? confirmedReturnOrExchangeResolved,
    bool? confirmedOdometerConflict,
  }) {
    return MaintenanceReceiptReviewItem(
      source: source,
      decision: decision ?? this.decision,
      setupMode: setupMode ?? this.setupMode,
      itemName: itemName ?? this.itemName,
      detailA: detailA ?? this.detailA,
      detailB: detailB ?? this.detailB,
      serviceDate: clearServiceDate ? null : serviceDate ?? this.serviceDate,
      serviceOdometer: clearServiceOdometer
          ? null
          : serviceOdometer ?? this.serviceOdometer,
      intervalMiles: clearIntervalMiles
          ? null
          : intervalMiles ?? this.intervalMiles,
      intervalMonths: clearIntervalMonths
          ? null
          : intervalMonths ?? this.intervalMonths,
      serviceDateEdited:
          serviceDateEdited || clearServiceDate || serviceDate != null,
      serviceOdometerEdited:
          serviceOdometerEdited ||
          clearServiceOdometer ||
          serviceOdometer != null,
      intervalMilesEdited:
          intervalMilesEdited || clearIntervalMiles || intervalMiles != null,
      intervalMonthsEdited:
          intervalMonthsEdited || clearIntervalMonths || intervalMonths != null,
      confirmedPurchasedItemWasInstalled:
          confirmedPurchasedItemWasInstalled ??
          this.confirmedPurchasedItemWasInstalled,
      confirmedWorkWasCompleted:
          confirmedWorkWasCompleted ?? this.confirmedWorkWasCompleted,
      confirmedReturnOrExchangeResolved:
          confirmedReturnOrExchangeResolved ??
          this.confirmedReturnOrExchangeResolved,
      confirmedOdometerConflict:
          confirmedOdometerConflict ?? this.confirmedOdometerConflict,
    );
  }

  Map<String, Object?> toDraftJson() => {
    'decision': decision.name,
    'setupMode': setupMode.name,
    if (itemName != null) 'itemName': itemName,
    if (detailA != null) 'detailA': detailA,
    if (detailB != null) 'detailB': detailB,
    if (serviceDate != null)
      'serviceDate': serviceDate!.toUtc().toIso8601String(),
    if (serviceOdometer != null) 'serviceOdometer': serviceOdometer,
    if (intervalMiles != null) 'intervalMiles': intervalMiles,
    if (intervalMonths != null) 'intervalMonths': intervalMonths,
    'serviceDateEdited': serviceDateEdited,
    'serviceOdometerEdited': serviceOdometerEdited,
    'intervalMilesEdited': intervalMilesEdited,
    'intervalMonthsEdited': intervalMonthsEdited,
    'confirmedPurchasedItemWasInstalled': confirmedPurchasedItemWasInstalled,
    'confirmedWorkWasCompleted': confirmedWorkWasCompleted,
    'confirmedReturnOrExchangeResolved': confirmedReturnOrExchangeResolved,
    'confirmedOdometerConflict': confirmedOdometerConflict,
  };

  factory MaintenanceReceiptReviewItem.fromDraftJson(
    Map<dynamic, dynamic> map, {
    required MaintenanceReceiptCandidate source,
  }) {
    final decision = _reviewEnum(
      MaintenanceReceiptReviewDecision.values,
      map['decision'],
    );
    if (decision == null) {
      throw const FormatException('Receipt review decision is invalid.');
    }
    return MaintenanceReceiptReviewItem(
      source: source,
      decision: decision,
      setupMode:
          _reviewEnum(MaintenanceReceiptSetupMode.values, map['setupMode']) ??
          MaintenanceReceiptSetupMode.basic,
      itemName: _reviewNullableString(map['itemName']),
      detailA: _reviewNullableString(map['detailA']),
      detailB: _reviewNullableString(map['detailB']),
      serviceDate: _reviewDate(map['serviceDate']),
      serviceOdometer: _reviewNonNegativeInt(map['serviceOdometer']),
      intervalMiles: _reviewNonNegativeInt(map['intervalMiles']),
      intervalMonths: _reviewNonNegativeInt(map['intervalMonths']),
      serviceDateEdited: map['serviceDateEdited'] == true,
      serviceOdometerEdited: map['serviceOdometerEdited'] == true,
      intervalMilesEdited: map['intervalMilesEdited'] == true,
      intervalMonthsEdited: map['intervalMonthsEdited'] == true,
      confirmedPurchasedItemWasInstalled:
          map['confirmedPurchasedItemWasInstalled'] == true,
      confirmedWorkWasCompleted: map['confirmedWorkWasCompleted'] == true,
      confirmedReturnOrExchangeResolved:
          map['confirmedReturnOrExchangeResolved'] == true,
      confirmedOdometerConflict: map['confirmedOdometerConflict'] == true,
    );
  }
}

class MaintenanceReceiptReview {
  const MaintenanceReceiptReview({
    required this.parserResult,
    required this.currentOdometer,
    required this.items,
  });

  final MaintenanceReceiptParserResult parserResult;
  final int? currentOdometer;
  final List<MaintenanceReceiptReviewItem> items;

  static const draftSchemaVersion = 1;

  bool get mayMutateMaintenance => false;

  MaintenanceReceiptReview copyWith({
    int? currentOdometer,
    List<MaintenanceReceiptReviewItem>? items,
  }) {
    return MaintenanceReceiptReview(
      parserResult: parserResult,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      items: List.unmodifiable(items ?? this.items),
    );
  }

  Map<String, Object?> toDraftJson() => {
    'draftSchemaVersion': draftSchemaVersion,
    'parserResult': parserResult.toJson(),
    if (currentOdometer != null) 'currentOdometer': currentOdometer,
    'items': [for (final item in items) item.toDraftJson()],
  };

  factory MaintenanceReceiptReview.fromDraftJson(Map<dynamic, dynamic> map) {
    if (_reviewInt(map['draftSchemaVersion']) != draftSchemaVersion) {
      throw const FormatException(
        'Receipt review draft schema is unsupported.',
      );
    }
    final parserMap = map['parserResult'];
    if (parserMap is! Map) {
      throw const FormatException('Receipt parser draft is missing.');
    }
    final parserResult = MaintenanceReceiptParserResult.fromJson(parserMap);
    final rawItems = map['items'];
    if (rawItems is! Iterable) {
      throw const FormatException('Receipt review items are invalid.');
    }
    final itemMaps = rawItems.toList(growable: false);
    if (itemMaps.length != parserResult.candidates.length) {
      throw const FormatException('Receipt review candidate count changed.');
    }
    return MaintenanceReceiptReview(
      parserResult: parserResult,
      currentOdometer: _reviewNonNegativeInt(map['currentOdometer']),
      items: List.unmodifiable([
        for (var index = 0; index < itemMaps.length; index++)
          if (itemMaps[index] is Map)
            MaintenanceReceiptReviewItem.fromDraftJson(
              itemMaps[index] as Map,
              source: parserResult.candidates[index],
            )
          else
            throw const FormatException('Receipt review item is invalid.'),
      ]),
    );
  }
}

class MaintenanceReceiptReviewIssue {
  const MaintenanceReceiptReviewIssue({
    required this.code,
    required this.message,
    this.itemIndex,
  });

  final String code;
  final String message;
  final int? itemIndex;
}

class MaintenanceReceiptConfirmedCommand {
  const MaintenanceReceiptConfirmedCommand({
    required this.vehicleId,
    required this.vehicleName,
    required this.commandId,
    required this.sourceFingerprintSha256,
    required this.parserSchemaVersion,
    required this.candidateIndex,
    required this.decision,
    required this.setupMode,
    required this.itemName,
    required this.setupTracking,
    required this.logCompletedService,
    required this.merchantName,
    required this.evidenceLineNumbers,
    this.detailA,
    this.detailB,
    this.serviceDate,
    this.serviceOdometer,
    this.intervalMiles,
    this.intervalMonths,
  });

  final String vehicleId;
  final String vehicleName;
  final String commandId;
  final String sourceFingerprintSha256;
  final int parserSchemaVersion;
  final int candidateIndex;
  final MaintenanceReceiptReviewDecision decision;
  final MaintenanceReceiptSetupMode setupMode;
  final String itemName;
  final bool setupTracking;
  final bool logCompletedService;
  final String merchantName;
  final List<int> evidenceLineNumbers;
  final String? detailA;
  final String? detailB;
  final DateTime? serviceDate;
  final int? serviceOdometer;
  final int? intervalMiles;
  final int? intervalMonths;

  /// Commands remain inert until a separate application service validates and
  /// durably commits them.
  bool get mayMutateMaintenance => false;
}

class MaintenanceReceiptReviewOutcome {
  const MaintenanceReceiptReviewOutcome({
    required this.issues,
    required this.commands,
    required this.vehicleId,
    required this.sourceFingerprintSha256,
  });

  final List<MaintenanceReceiptReviewIssue> issues;
  final List<MaintenanceReceiptConfirmedCommand> commands;
  final String vehicleId;
  final String sourceFingerprintSha256;

  bool get isValid => issues.isEmpty;
  bool get mayMutateMaintenance => false;
}

String? _clean(String? value) {
  final cleaned = value?.trim();
  return cleaned == null || cleaned.isEmpty ? null : cleaned;
}

String maintenanceReceiptCommandId({
  required String sourceFingerprint,
  required int parserSchemaVersion,
  required String vehicleId,
  required int candidateIndex,
  required String itemName,
  required MaintenanceReceiptReviewDecision decision,
  required MaintenanceReceiptSetupMode setupMode,
  required String merchantName,
  required String? detailA,
  required String? detailB,
  required DateTime? serviceDate,
  required int? serviceOdometer,
  required int? intervalMiles,
  required int? intervalMonths,
}) {
  final canonical = [
    'maintenance_receipt_command_v3',
    sourceFingerprint,
    parserSchemaVersion,
    vehicleId.trim().toLowerCase(),
    candidateIndex,
    itemName.trim().toLowerCase(),
    decision.name,
    setupMode.name,
    merchantName.trim().toLowerCase(),
    detailA?.trim().toLowerCase() ?? '',
    detailB?.trim().toLowerCase() ?? '',
    serviceDate?.toUtc().toIso8601String() ?? '',
    serviceOdometer ?? '',
    intervalMiles ?? '',
    intervalMonths ?? '',
  ].join('|');
  return sha256.convert(utf8.encode(canonical)).toString();
}

T? _reviewEnum<T extends Enum>(List<T> values, Object? raw) {
  final name = '$raw';
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

int? _reviewInt(Object? raw) {
  return raw is int ? raw : int.tryParse('$raw');
}

int? _reviewNonNegativeInt(Object? raw) {
  if (raw == null) return null;
  final value = _reviewInt(raw);
  if (value == null || value < 0) {
    throw const FormatException('Receipt review integer is invalid.');
  }
  return value;
}

DateTime? _reviewDate(Object? raw) {
  if (raw == null) return null;
  final value = DateTime.tryParse('$raw');
  if (value == null) {
    throw const FormatException('Receipt review date is invalid.');
  }
  return value;
}

String? _reviewNullableString(Object? raw) {
  if (raw == null) return null;
  return '$raw';
}
