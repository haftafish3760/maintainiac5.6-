/// Pure, local maintenance receipt interpretation.
///
/// This file deliberately has no camera, OCR, storage, Firebase, or UI
/// dependency. OCR supplies text; this parser returns review suggestions. It
/// never creates a maintenance record or claims that a purchased part was
/// installed.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

part 'maintenance_receipt_parser_catalog.dart';
part 'maintenance_receipt_parser_dates.dart';
part 'maintenance_receipt_parser_engine.dart';
part 'maintenance_receipt_parser_support.dart';

enum MaintenanceReceiptKind { partsPurchase, serviceInvoice, mixed, unknown }

enum MaintenanceReceiptAction {
  reviewTrackingSetup,
  reviewCompletedService,
  manualReview,
}

enum MaintenanceReceiptReviewStatus {
  readyForReview,
  needsDetails,
  noMaintenanceEvidence,
}

class MaintenanceReceiptParserInput {
  const MaintenanceReceiptParserInput({
    required this.sourceText,
    this.activeVehicleId = '',
    this.activeVehicleName = '',
    this.currentOdometer,
    this.locale = 'en-US',
    this.referenceDate,
  });

  final String sourceText;
  final String activeVehicleId;
  final String activeVehicleName;
  final int? currentOdometer;
  final String locale;
  final DateTime? referenceDate;
}

class MaintenanceReceiptEvidence {
  const MaintenanceReceiptEvidence({
    required this.code,
    required this.lineNumber,
    required this.safeSnippet,
  });

  final String code;
  final int lineNumber;
  final String safeSnippet;

  factory MaintenanceReceiptEvidence.fromJson(Map<dynamic, dynamic> map) {
    final code = '${map['code'] ?? ''}'.trim();
    final lineNumber = _jsonInt(map['lineNumber']);
    final safeSnippet = '${map['safeSnippet'] ?? ''}'.trim();
    if (code.isEmpty || lineNumber == null || lineNumber < 1) {
      throw const FormatException('Receipt evidence is invalid.');
    }
    return MaintenanceReceiptEvidence(
      code: code,
      lineNumber: lineNumber,
      safeSnippet: safeSnippet,
    );
  }

  Map<String, Object?> toJson() => {
    'code': code,
    'lineNumber': lineNumber,
    'safeSnippet': safeSnippet,
  };
}

class MaintenanceReceiptCandidate {
  const MaintenanceReceiptCandidate({
    required this.itemName,
    required this.action,
    required this.confidence,
    required this.evidence,
    this.detailA,
    this.detailB,
    this.serviceDate,
    this.serviceOdometer,
    this.dueOdometer,
    this.intervalMiles,
    this.intervalMonths,
    this.productPurchased = false,
    this.completedServiceIndicated = false,
    this.returnOrExchangeIndicated = false,
    this.notCompletedIndicated = false,
  });

  final String itemName;
  final MaintenanceReceiptAction action;
  final double confidence;
  final List<MaintenanceReceiptEvidence> evidence;
  final String? detailA;
  final String? detailB;
  final DateTime? serviceDate;
  final int? serviceOdometer;
  final int? dueOdometer;
  final int? intervalMiles;
  final int? intervalMonths;
  final bool productPurchased;
  final bool completedServiceIndicated;
  final bool returnOrExchangeIndicated;
  final bool notCompletedIndicated;

  bool get requiresUserConfirmation => true;

  factory MaintenanceReceiptCandidate.fromJson(Map<dynamic, dynamic> map) {
    final itemName = '${map['itemName'] ?? ''}'.trim();
    final action = _enumValue(MaintenanceReceiptAction.values, map['action']);
    final confidence = _jsonDouble(map['confidence']);
    if (itemName.isEmpty ||
        action == null ||
        confidence == null ||
        confidence < 0 ||
        confidence > 1) {
      throw const FormatException('Receipt candidate is invalid.');
    }
    return MaintenanceReceiptCandidate(
      itemName: itemName,
      action: action,
      confidence: confidence,
      evidence: List.unmodifiable(
        _jsonMaps(map['evidence']).map(MaintenanceReceiptEvidence.fromJson),
      ),
      detailA: _jsonNullableString(map['detailA']),
      detailB: _jsonNullableString(map['detailB']),
      serviceDate: _jsonDate(map['serviceDate']),
      serviceOdometer: _jsonNonNegativeInt(map['serviceOdometer']),
      dueOdometer: _jsonNonNegativeInt(map['dueOdometer']),
      intervalMiles: _jsonNonNegativeInt(map['intervalMiles']),
      intervalMonths: _jsonNonNegativeInt(map['intervalMonths']),
      productPurchased: map['productPurchased'] == true,
      completedServiceIndicated: map['completedServiceIndicated'] == true,
      returnOrExchangeIndicated: map['returnOrExchangeIndicated'] == true,
      notCompletedIndicated: map['notCompletedIndicated'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'itemName': itemName,
    'action': action.name,
    'confidence': confidence,
    'evidence': [for (final item in evidence) item.toJson()],
    if (detailA != null) 'detailA': detailA,
    if (detailB != null) 'detailB': detailB,
    if (serviceDate != null)
      'serviceDate': serviceDate!.toIso8601String().split('T').first,
    if (serviceOdometer != null) 'serviceOdometer': serviceOdometer,
    if (dueOdometer != null) 'dueOdometer': dueOdometer,
    if (intervalMiles != null) 'intervalMiles': intervalMiles,
    if (intervalMonths != null) 'intervalMonths': intervalMonths,
    'productPurchased': productPurchased,
    'completedServiceIndicated': completedServiceIndicated,
    'returnOrExchangeIndicated': returnOrExchangeIndicated,
    'notCompletedIndicated': notCompletedIndicated,
    'requiresUserConfirmation': true,
  };
}

class MaintenanceReceiptParserResult {
  const MaintenanceReceiptParserResult({
    required this.kind,
    required this.reviewStatus,
    required this.merchantName,
    required this.receiptDate,
    required this.candidates,
    required this.warnings,
    required this.activeVehicleId,
    required this.activeVehicleName,
    required this.sourceFingerprintSha256,
  });

  static const schemaVersion = 1;

  final MaintenanceReceiptKind kind;
  final MaintenanceReceiptReviewStatus reviewStatus;
  final String merchantName;
  final DateTime? receiptDate;
  final List<MaintenanceReceiptCandidate> candidates;
  final List<String> warnings;
  final String activeVehicleId;
  final String activeVehicleName;
  final String sourceFingerprintSha256;

  bool get mayMutateMaintenance => false;

  factory MaintenanceReceiptParserResult.fromJson(Map<dynamic, dynamic> map) {
    if (_jsonInt(map['schemaVersion']) != schemaVersion) {
      throw const FormatException(
        'Receipt parser result schema is unsupported.',
      );
    }
    final kind = _enumValue(MaintenanceReceiptKind.values, map['kind']);
    final reviewStatus = _enumValue(
      MaintenanceReceiptReviewStatus.values,
      map['reviewStatus'],
    );
    final fingerprint = '${map['sourceFingerprintSha256'] ?? ''}'.trim();
    if (kind == null ||
        reviewStatus == null ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(fingerprint)) {
      throw const FormatException('Receipt parser result is invalid.');
    }
    final warnings = map['warnings'];
    if (warnings is! Iterable) {
      throw const FormatException('Receipt parser warnings are invalid.');
    }
    return MaintenanceReceiptParserResult(
      kind: kind,
      reviewStatus: reviewStatus,
      merchantName: '${map['merchantName'] ?? ''}'.trim(),
      receiptDate: _jsonDate(map['receiptDate']),
      candidates: List.unmodifiable(
        _jsonMaps(map['candidates']).map(MaintenanceReceiptCandidate.fromJson),
      ),
      warnings: List.unmodifiable(
        warnings
            .map((warning) => '$warning'.trim())
            .where((warning) => warning.isNotEmpty),
      ),
      activeVehicleId: '${map['activeVehicleId'] ?? ''}'.trim(),
      activeVehicleName: '${map['activeVehicleName'] ?? ''}'.trim(),
      sourceFingerprintSha256: fingerprint,
    );
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'reviewStatus': reviewStatus.name,
    'merchantName': merchantName,
    if (receiptDate != null)
      'receiptDate': receiptDate!.toIso8601String().split('T').first,
    'candidates': [for (final candidate in candidates) candidate.toJson()],
    'warnings': warnings,
    'activeVehicleId': activeVehicleId,
    'activeVehicleName': activeVehicleName,
    'sourceFingerprintSha256': sourceFingerprintSha256,
    'schemaVersion': schemaVersion,
    'mayMutateMaintenance': false,
  };
}
