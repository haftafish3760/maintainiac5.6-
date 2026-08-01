// Confirmed per-vehicle mileage-allocation evidence and period summaries.
// Owns business, personal, and unresolved mileage classification after the
// user confirms an owning source record. It does not own trips, expenses,
// odometer history, GPS evidence, or durable storage. Trip Tracking and the
// future durable allocation bucket consume its serializable contract.
// odometerIsGlobalTruth: true.

enum VehicleMileageAllocationUse { business, personal, split, unclassified }

/// One confirmed source revision contributing mileage to a vehicle period.
///
/// Distances are integer tenths of a mile to avoid floating-point allocation
/// drift. An unclassified value is intentionally retained rather than being
/// silently assigned to business or personal use.
class VehicleMileageAllocationRecord {
  const VehicleMileageAllocationRecord({
    required this.id,
    required this.vehicleId,
    required this.sourceType,
    required this.sourceId,
    required this.sourceRevision,
    required this.occurredAt,
    required this.confirmedAt,
    required this.use,
    required this.distanceTenths,
    required this.businessTenths,
    required this.personalTenths,
    required this.unclassifiedTenths,
  });

  final String id;
  final String vehicleId;
  final String sourceType;
  final String sourceId;
  final int sourceRevision;
  final DateTime occurredAt;
  final DateTime confirmedAt;
  final VehicleMileageAllocationUse use;
  final int distanceTenths;
  final int businessTenths;
  final int personalTenths;
  final int unclassifiedTenths;

  /// Collision-safe identity for one owning source inside one vehicle.
  ///
  /// Tokens may legitimately contain punctuation such as `:`. Length-prefixing
  /// prevents those tokens from making two different vehicles or source
  /// records share an allocation identity.
  String get sourceKey => sourceKeyFor(
    vehicleId: vehicleId,
    sourceType: sourceType,
    sourceId: sourceId,
  );

  static String sourceKeyFor({
    required String vehicleId,
    required String sourceType,
    required String sourceId,
  }) => _sourceIdentity(vehicleId, sourceType, sourceId);
  double get distanceMiles => distanceTenths / 10;
  double get businessMiles => businessTenths / 10;
  double get personalMiles => personalTenths / 10;
  double get unclassifiedMiles => unclassifiedTenths / 10;

  bool get isValid =>
      _safeToken(id) &&
      _safeToken(vehicleId) &&
      _safeToken(sourceType) &&
      _safeToken(sourceId) &&
      sourceRevision >= 0 &&
      !confirmedAt.toUtc().isBefore(occurredAt.toUtc()) &&
      distanceTenths >= 0 &&
      businessTenths >= 0 &&
      personalTenths >= 0 &&
      unclassifiedTenths >= 0 &&
      businessTenths + personalTenths + unclassifiedTenths == distanceTenths &&
      _matchesUse;

  bool get _matchesUse => switch (use) {
    VehicleMileageAllocationUse.business =>
      businessTenths == distanceTenths &&
          personalTenths == 0 &&
          unclassifiedTenths == 0,
    VehicleMileageAllocationUse.personal =>
      businessTenths == 0 &&
          personalTenths == distanceTenths &&
          unclassifiedTenths == 0,
    VehicleMileageAllocationUse.split =>
      businessTenths > 0 && personalTenths > 0 && unclassifiedTenths == 0,
    VehicleMileageAllocationUse.unclassified =>
      businessTenths == 0 &&
          personalTenths == 0 &&
          unclassifiedTenths == distanceTenths,
  };

  factory VehicleMileageAllocationRecord.confirmed({
    required String id,
    required String vehicleId,
    required String sourceType,
    required String sourceId,
    required int sourceRevision,
    required DateTime occurredAt,
    required DateTime confirmedAt,
    required VehicleMileageAllocationUse use,
    required int distanceTenths,
    int? businessTenths,
  }) {
    final safeDistance = distanceTenths < 0 ? 0 : distanceTenths;
    final splitBusiness = (businessTenths ?? 0).clamp(0, safeDistance).toInt();
    final business = switch (use) {
      VehicleMileageAllocationUse.business => safeDistance,
      VehicleMileageAllocationUse.personal ||
      VehicleMileageAllocationUse.unclassified => 0,
      VehicleMileageAllocationUse.split => splitBusiness,
    };
    final personal = switch (use) {
      VehicleMileageAllocationUse.personal => safeDistance,
      VehicleMileageAllocationUse.business ||
      VehicleMileageAllocationUse.unclassified => 0,
      VehicleMileageAllocationUse.split => safeDistance - business,
    };
    final unresolved = use == VehicleMileageAllocationUse.unclassified
        ? safeDistance
        : 0;
    return VehicleMileageAllocationRecord(
      id: id,
      vehicleId: vehicleId,
      sourceType: sourceType,
      sourceId: sourceId,
      sourceRevision: sourceRevision,
      occurredAt: occurredAt.toUtc(),
      confirmedAt: confirmedAt.toUtc(),
      use: use,
      distanceTenths: safeDistance,
      businessTenths: business,
      personalTenths: personal,
      unclassifiedTenths: unresolved,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'vehicleId': vehicleId,
    'sourceType': sourceType,
    'sourceId': sourceId,
    'sourceRevision': sourceRevision,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'confirmedAt': confirmedAt.toUtc().toIso8601String(),
    'use': use.name,
    'distanceTenths': distanceTenths,
    'businessTenths': businessTenths,
    'personalTenths': personalTenths,
    'unclassifiedTenths': unclassifiedTenths,
  };

  static VehicleMileageAllocationRecord? fromMap(Map<dynamic, dynamic> map) {
    final use = VehicleMileageAllocationUse.values.firstWhere(
      (candidate) => candidate.name == map['use'],
      orElse: () => VehicleMileageAllocationUse.unclassified,
    );
    final occurredAt = DateTime.tryParse('${map['occurredAt'] ?? ''}');
    final confirmedAt = DateTime.tryParse('${map['confirmedAt'] ?? ''}');
    if (occurredAt == null || confirmedAt == null) return null;
    final record = VehicleMileageAllocationRecord(
      id: '${map['id'] ?? ''}',
      vehicleId: '${map['vehicleId'] ?? ''}',
      sourceType: '${map['sourceType'] ?? ''}',
      sourceId: '${map['sourceId'] ?? ''}',
      sourceRevision: _safeInt(map['sourceRevision']),
      occurredAt: occurredAt.toUtc(),
      confirmedAt: confirmedAt.toUtc(),
      use: use,
      distanceTenths: _safeInt(map['distanceTenths']),
      businessTenths: _safeInt(map['businessTenths']),
      personalTenths: _safeInt(map['personalTenths']),
      unclassifiedTenths: _safeInt(map['unclassifiedTenths']),
    );
    return record.isValid ? record : null;
  }
}

/// A transparent allocation for one vehicle and one inclusive date window.
class VehicleMileageAllocationSummary {
  const VehicleMileageAllocationSummary({
    required this.vehicleId,
    required this.from,
    required this.until,
    required this.businessTenths,
    required this.personalTenths,
    required this.unclassifiedTenths,
    required this.recordCount,
  });

  final String vehicleId;
  final DateTime from;
  final DateTime until;
  final int businessTenths;
  final int personalTenths;
  final int unclassifiedTenths;
  final int recordCount;

  int get classifiedTenths => businessTenths + personalTenths;
  int get totalTenths => classifiedTenths + unclassifiedTenths;
  bool get hasMileage => totalTenths > 0;
  bool get isComplete => hasMileage && unclassifiedTenths == 0;
  double? get businessPercentOfClassified =>
      classifiedTenths == 0 ? null : businessTenths / classifiedTenths;

  /// Exact confirmed ratio for downstream money calculations.
  ///
  /// Consumers retain these integer tenths instead of multiplying a rounded
  /// display percentage. Null means the period cannot suggest an expense split.
  int? get expenseBusinessNumeratorTenths => isComplete ? businessTenths : null;
  int? get expenseClassifiedDenominatorTenths =>
      isComplete ? classifiedTenths : null;

  double? get expenseSuggestedBusinessPercent =>
      isComplete ? businessPercentOfClassified : null;

  String get expenseExplanation {
    if (!hasMileage) {
      return 'No confirmed vehicle mileage is available for this period.';
    }
    if (!isComplete) {
      return 'Mileage is partly unclassified. Review it before using a vehicle-use percentage for an expense.';
    }
    final percent = ((expenseSuggestedBusinessPercent ?? 0) * 100)
        .toStringAsFixed(1);
    return '$percent% business based on confirmed mileage for this period.';
  }
}

int _safeInt(Object? value) {
  final parsed = value is int ? value : int.tryParse('${value ?? ''}');
  return parsed == null || parsed < 0 ? 0 : parsed;
}

bool _safeToken(String value) =>
    value.isNotEmpty &&
    value.length <= 160 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);

String _sourceIdentity(String vehicleId, String sourceType, String sourceId) =>
    '${vehicleId.length}:$vehicleId${sourceType.length}:$sourceType${sourceId.length}:$sourceId';
