part of 'app_state.dart';

class MaintenanceRecord {
  MaintenanceRecord({
    required this.itemName,
    required this.vehicleName,
    required this.intervalMiles,
    required this.milesSinceService,
    required this.intervalMonths,
    required this.monthsSinceService,
    required this.importance,
    this.lastServiceDate,
    this.lastServiceOdometer = 0,
    this.detailA = '',
    this.detailB = '',
    this.setupComplete = false,
    this.lastServiceEstimated = true,
    this.lastOdometerEstimated = true,
    this.thresholdsEnabled = true,
    this.mileageYellowAt = 900,
    this.mileageOrangeAt = 600,
    this.mileageRedAt = 300,
    this.timeYellowDays = 60,
    this.timeOrangeDays = 30,
    this.timeRedDays = 14,
    this.inAppNotifications = false,
    this.pushNotifications = false,
    this.soundNotifications = false,
    this.pairOilFilter = true,
    this.timeOnly = false,
    this.recordId = '',
    this.vehicleId = '',
    this.createdAt,
    this.updatedAt,
    this.revision = 0,
    this.archivedAt,
    this.sourceCommandId = '',
    this.sourceReceiptFingerprint = '',
    this.sourceParserSchemaVersion = 0,
  });

  final String itemName;
  final String vehicleName;
  final int intervalMiles;
  final int milesSinceService;
  final int intervalMonths;
  final int monthsSinceService;
  final int importance;
  final DateTime? lastServiceDate;
  final int lastServiceOdometer;
  final String detailA;
  final String detailB;
  final bool setupComplete;
  final bool lastServiceEstimated;
  final bool lastOdometerEstimated;
  final bool thresholdsEnabled;
  final int mileageYellowAt;
  final int mileageOrangeAt;
  final int mileageRedAt;
  final int timeYellowDays;
  final int timeOrangeDays;
  final int timeRedDays;
  final bool inAppNotifications;
  final bool pushNotifications;
  final bool soundNotifications;
  final bool pairOilFilter;
  final bool timeOnly;
  final String recordId;
  final String vehicleId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int revision;
  final DateTime? archivedAt;
  final String sourceCommandId;
  final String sourceReceiptFingerprint;
  final int sourceParserSchemaVersion;

  int get milesRemaining => intervalMiles - milesSinceService;
  int get monthsRemaining => intervalMonths - monthsSinceService;
  bool get isArchived => archivedAt != null;

  bool belongsToVehicle(VehicleProfile vehicle) {
    final stableId = vehicleId.trim();
    return stableId.isNotEmpty
        ? stableId == vehicle.id
        : vehicleName == vehicle.nickname;
  }

  factory MaintenanceRecord.fromMap(Map<dynamic, dynamic> map) {
    return MaintenanceRecord(
      recordId: '${map['recordId'] ?? ''}'.trim(),
      vehicleId: '${map['vehicleId'] ?? ''}'.trim(),
      itemName: '${map['itemName'] ?? ''}'.trim(),
      vehicleName: '${map['vehicleName'] ?? ''}'.trim(),
      intervalMiles: _nonNegativeInt(map['intervalMiles']),
      milesSinceService: _nonNegativeInt(map['milesSinceService']),
      intervalMonths: _nonNegativeInt(map['intervalMonths']),
      monthsSinceService: _nonNegativeInt(map['monthsSinceService']),
      importance: _nonNegativeInt(map['importance']),
      lastServiceDate: DateTime.tryParse('${map['lastServiceDate'] ?? ''}'),
      lastServiceOdometer: _nonNegativeInt(map['lastServiceOdometer']),
      detailA: '${map['detailA'] ?? ''}'.trim(),
      detailB: '${map['detailB'] ?? ''}'.trim(),
      setupComplete: map['setupComplete'] == true,
      lastServiceEstimated: map['lastServiceEstimated'] != false,
      lastOdometerEstimated: map['lastOdometerEstimated'] != false,
      thresholdsEnabled: map['thresholdsEnabled'] != false,
      mileageYellowAt: _nonNegativeIntOr(map['mileageYellowAt'], 900),
      mileageOrangeAt: _nonNegativeIntOr(map['mileageOrangeAt'], 600),
      mileageRedAt: _nonNegativeIntOr(map['mileageRedAt'], 300),
      timeYellowDays: _nonNegativeIntOr(map['timeYellowDays'], 60),
      timeOrangeDays: _nonNegativeIntOr(map['timeOrangeDays'], 30),
      timeRedDays: _nonNegativeIntOr(map['timeRedDays'], 14),
      inAppNotifications: map['inAppNotifications'] == true,
      pushNotifications: map['pushNotifications'] == true,
      soundNotifications: map['soundNotifications'] == true,
      pairOilFilter: map['pairOilFilter'] != false,
      timeOnly: map['timeOnly'] == true,
      createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}'),
      revision: _nonNegativeInt(map['revision']),
      archivedAt: DateTime.tryParse('${map['archivedAt'] ?? ''}'),
      sourceCommandId: '${map['sourceCommandId'] ?? ''}'.trim(),
      sourceReceiptFingerprint: '${map['sourceReceiptFingerprint'] ?? ''}'
          .trim(),
      sourceParserSchemaVersion: _nonNegativeInt(
        map['sourceParserSchemaVersion'],
      ),
    );
  }

  Map<String, Object?> toMap() => {
    'recordId': recordId,
    'vehicleId': vehicleId,
    'itemName': itemName,
    'vehicleName': vehicleName,
    'intervalMiles': intervalMiles,
    'milesSinceService': milesSinceService,
    'intervalMonths': intervalMonths,
    'monthsSinceService': monthsSinceService,
    'importance': importance,
    'lastServiceDate': lastServiceDate?.toUtc().toIso8601String(),
    'lastServiceOdometer': lastServiceOdometer,
    'detailA': detailA,
    'detailB': detailB,
    'setupComplete': setupComplete,
    'lastServiceEstimated': lastServiceEstimated,
    'lastOdometerEstimated': lastOdometerEstimated,
    'thresholdsEnabled': thresholdsEnabled,
    'mileageYellowAt': mileageYellowAt,
    'mileageOrangeAt': mileageOrangeAt,
    'mileageRedAt': mileageRedAt,
    'timeYellowDays': timeYellowDays,
    'timeOrangeDays': timeOrangeDays,
    'timeRedDays': timeRedDays,
    'inAppNotifications': inAppNotifications,
    'pushNotifications': pushNotifications,
    'soundNotifications': soundNotifications,
    'pairOilFilter': pairOilFilter,
    'timeOnly': timeOnly,
    'createdAt': createdAt?.toUtc().toIso8601String(),
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'revision': revision,
    'archivedAt': archivedAt?.toUtc().toIso8601String(),
    'sourceCommandId': sourceCommandId,
    'sourceReceiptFingerprint': sourceReceiptFingerprint,
    'sourceParserSchemaVersion': sourceParserSchemaVersion,
  };

  MaintenanceRecord copyWith({
    String? itemName,
    String? vehicleName,
    int? intervalMiles,
    int? milesSinceService,
    int? intervalMonths,
    int? monthsSinceService,
    int? importance,
    DateTime? lastServiceDate,
    int? lastServiceOdometer,
    String? detailA,
    String? detailB,
    bool? setupComplete,
    bool? lastServiceEstimated,
    bool? lastOdometerEstimated,
    bool? thresholdsEnabled,
    int? mileageYellowAt,
    int? mileageOrangeAt,
    int? mileageRedAt,
    int? timeYellowDays,
    int? timeOrangeDays,
    int? timeRedDays,
    bool? inAppNotifications,
    bool? pushNotifications,
    bool? soundNotifications,
    bool? pairOilFilter,
    bool? timeOnly,
    String? recordId,
    String? vehicleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? revision,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    String? sourceCommandId,
    String? sourceReceiptFingerprint,
    int? sourceParserSchemaVersion,
  }) {
    return MaintenanceRecord(
      itemName: itemName ?? this.itemName,
      vehicleName: vehicleName ?? this.vehicleName,
      intervalMiles: intervalMiles ?? this.intervalMiles,
      milesSinceService: milesSinceService ?? this.milesSinceService,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      monthsSinceService: monthsSinceService ?? this.monthsSinceService,
      importance: importance ?? this.importance,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceOdometer: lastServiceOdometer ?? this.lastServiceOdometer,
      detailA: detailA ?? this.detailA,
      detailB: detailB ?? this.detailB,
      setupComplete: setupComplete ?? this.setupComplete,
      lastServiceEstimated: lastServiceEstimated ?? this.lastServiceEstimated,
      lastOdometerEstimated:
          lastOdometerEstimated ?? this.lastOdometerEstimated,
      thresholdsEnabled: thresholdsEnabled ?? this.thresholdsEnabled,
      mileageYellowAt: mileageYellowAt ?? this.mileageYellowAt,
      mileageOrangeAt: mileageOrangeAt ?? this.mileageOrangeAt,
      mileageRedAt: mileageRedAt ?? this.mileageRedAt,
      timeYellowDays: timeYellowDays ?? this.timeYellowDays,
      timeOrangeDays: timeOrangeDays ?? this.timeOrangeDays,
      timeRedDays: timeRedDays ?? this.timeRedDays,
      inAppNotifications: inAppNotifications ?? this.inAppNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      soundNotifications: soundNotifications ?? this.soundNotifications,
      pairOilFilter: pairOilFilter ?? this.pairOilFilter,
      timeOnly: timeOnly ?? this.timeOnly,
      recordId: recordId ?? this.recordId,
      vehicleId: vehicleId ?? this.vehicleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
      sourceCommandId: sourceCommandId ?? this.sourceCommandId,
      sourceReceiptFingerprint:
          sourceReceiptFingerprint ?? this.sourceReceiptFingerprint,
      sourceParserSchemaVersion:
          sourceParserSchemaVersion ?? this.sourceParserSchemaVersion,
    );
  }
}

class MaintenanceServiceEvent {
  MaintenanceServiceEvent({
    required this.itemName,
    required this.vehicleName,
    required this.serviceDate,
    required this.odometer,
    this.provider = '',
    this.totalCost = 0,
    this.receiptProofCount = 0,
    this.notes = '',
    this.eventId = '',
    this.vehicleId = '',
    this.createdAt,
    this.sourceCommandId = '',
    this.sourceReceiptFingerprint = '',
    this.sourceParserSchemaVersion = 0,
  });

  final String itemName;
  final String vehicleName;
  final DateTime serviceDate;
  final int odometer;
  final String provider;
  final double totalCost;
  final int receiptProofCount;
  final String notes;
  final String eventId;
  final String vehicleId;
  final DateTime? createdAt;
  final String sourceCommandId;
  final String sourceReceiptFingerprint;
  final int sourceParserSchemaVersion;

  bool belongsToVehicle(VehicleProfile vehicle) {
    final stableId = vehicleId.trim();
    return stableId.isNotEmpty
        ? stableId == vehicle.id
        : vehicleName == vehicle.nickname;
  }

  factory MaintenanceServiceEvent.fromMap(Map<dynamic, dynamic> map) {
    final serviceDate = DateTime.tryParse('${map['serviceDate'] ?? ''}');
    if (serviceDate == null) {
      throw const FormatException('Maintenance service date is invalid.');
    }
    return MaintenanceServiceEvent(
      eventId: '${map['eventId'] ?? ''}'.trim(),
      vehicleId: '${map['vehicleId'] ?? ''}'.trim(),
      itemName: '${map['itemName'] ?? ''}'.trim(),
      vehicleName: '${map['vehicleName'] ?? ''}'.trim(),
      serviceDate: serviceDate,
      odometer: _nonNegativeInt(map['odometer']),
      provider: '${map['provider'] ?? ''}'.trim(),
      totalCost: _nonNegativeDouble(map['totalCost']),
      receiptProofCount: _nonNegativeInt(map['receiptProofCount']),
      notes: '${map['notes'] ?? ''}'.trim(),
      createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}'),
      sourceCommandId: '${map['sourceCommandId'] ?? ''}'.trim(),
      sourceReceiptFingerprint: '${map['sourceReceiptFingerprint'] ?? ''}'
          .trim(),
      sourceParserSchemaVersion: _nonNegativeInt(
        map['sourceParserSchemaVersion'],
      ),
    );
  }

  Map<String, Object?> toMap() => {
    'eventId': eventId,
    'vehicleId': vehicleId,
    'itemName': itemName,
    'vehicleName': vehicleName,
    'serviceDate': serviceDate.toUtc().toIso8601String(),
    'odometer': odometer,
    'provider': provider,
    'totalCost': totalCost,
    'receiptProofCount': receiptProofCount,
    'notes': notes,
    'createdAt': createdAt?.toUtc().toIso8601String(),
    'sourceCommandId': sourceCommandId,
    'sourceReceiptFingerprint': sourceReceiptFingerprint,
    'sourceParserSchemaVersion': sourceParserSchemaVersion,
  };

  MaintenanceServiceEvent copyWith({
    String? eventId,
    String? vehicleId,
    String? itemName,
    String? vehicleName,
    DateTime? serviceDate,
    int? odometer,
    String? provider,
    double? totalCost,
    int? receiptProofCount,
    String? notes,
    DateTime? createdAt,
    String? sourceCommandId,
    String? sourceReceiptFingerprint,
    int? sourceParserSchemaVersion,
  }) {
    return MaintenanceServiceEvent(
      eventId: eventId ?? this.eventId,
      vehicleId: vehicleId ?? this.vehicleId,
      itemName: itemName ?? this.itemName,
      vehicleName: vehicleName ?? this.vehicleName,
      serviceDate: serviceDate ?? this.serviceDate,
      odometer: odometer ?? this.odometer,
      provider: provider ?? this.provider,
      totalCost: totalCost ?? this.totalCost,
      receiptProofCount: receiptProofCount ?? this.receiptProofCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      sourceCommandId: sourceCommandId ?? this.sourceCommandId,
      sourceReceiptFingerprint:
          sourceReceiptFingerprint ?? this.sourceReceiptFingerprint,
      sourceParserSchemaVersion:
          sourceParserSchemaVersion ?? this.sourceParserSchemaVersion,
    );
  }
}

double _nonNegativeDouble(Object? value) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  return parsed == null || !parsed.isFinite || parsed < 0 ? 0 : parsed;
}

int _nonNegativeIntOr(Object? value, int fallback) {
  if (value == null) return fallback;
  final parsed = value is int ? value : int.tryParse('$value');
  return parsed == null || parsed < 0 ? fallback : parsed;
}
