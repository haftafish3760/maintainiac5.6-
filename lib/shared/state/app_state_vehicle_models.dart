part of 'app_state.dart';

enum VehicleUsage { businessOnly, personalOnly, businessPersonal }

extension VehicleUsageDetails on VehicleUsage {
  String get label {
    switch (this) {
      case VehicleUsage.businessOnly:
        return 'Business only';
      case VehicleUsage.personalOnly:
        return 'Personal only';
      case VehicleUsage.businessPersonal:
        return 'Business + personal';
    }
  }

  String get shortLabel {
    switch (this) {
      case VehicleUsage.businessOnly:
        return 'Business';
      case VehicleUsage.personalOnly:
        return 'Personal';
      case VehicleUsage.businessPersonal:
        return 'Mixed';
    }
  }

  String get setupDescription {
    switch (this) {
      case VehicleUsage.businessOnly:
        return 'Tracked miles default to business unless you mark an exception.';
      case VehicleUsage.personalOnly:
        return 'Hidden from business mileage by default, but still available for maintenance and fuel.';
      case VehicleUsage.businessPersonal:
        return 'Every trip or day segment must be classified as business or personal.';
    }
  }

  String get odometerPrompt {
    switch (this) {
      case VehicleUsage.businessOnly:
        return 'Was this missed business mileage, a correction, or a personal exception?';
      case VehicleUsage.personalOnly:
        return 'Was this personal mileage, a correction, or rare business use?';
      case VehicleUsage.businessPersonal:
        return 'Classify these miles as business, personal, or correction.';
    }
  }
}

class VehicleProfile {
  VehicleProfile({
    required this.nickname,
    this.id = '',
    this.year = '',
    this.make = '',
    this.model = '',
    this.usage = VehicleUsage.businessPersonal,
    this.tireSizeStatus = VehicleTireSizeStatus.unknown,
    this.speedometerCalibrationStatus =
        VehicleSpeedometerCalibrationStatus.unknown,
    this.tireConfigurationRevision = 0,
    this.tireConfigurationUpdatedAt,
    this.archivedAt,
  });

  final String nickname;

  /// A stable local identity for records. Unlike [nickname], this must not
  /// change when the user renames the vehicle.
  final String id;
  final String year;
  final String make;
  final String model;
  final VehicleUsage usage;
  final VehicleTireSizeStatus tireSizeStatus;
  final VehicleSpeedometerCalibrationStatus speedometerCalibrationStatus;

  /// Changes only when the driver updates tire/calibration context. This lets
  /// advisory GPS comparison code avoid blending evidence across configurations.
  final int tireConfigurationRevision;
  final DateTime? tireConfigurationUpdatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  String get displayName {
    final details = [
      year,
      make,
      model,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    return details.isEmpty ? nickname : '$nickname - $details';
  }

  factory VehicleProfile.fromMap(Map<dynamic, dynamic> map) {
    return VehicleProfile(
      id: map['id']?.toString() ?? '',
      nickname: map['nickname']?.toString() ?? 'Vehicle',
      year: map['year']?.toString() ?? '',
      make: map['make']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      usage: VehicleUsage.values.firstWhere(
        (usage) => usage.name == map['usage']?.toString(),
        orElse: () => VehicleUsage.businessPersonal,
      ),
      tireSizeStatus: VehicleTireSizeStatus.values.firstWhere(
        (status) => status.name == map['tireSizeStatus']?.toString(),
        orElse: () => VehicleTireSizeStatus.unknown,
      ),
      speedometerCalibrationStatus: VehicleSpeedometerCalibrationStatus.values
          .firstWhere(
            (status) =>
                status.name == map['speedometerCalibrationStatus']?.toString(),
            orElse: () => VehicleSpeedometerCalibrationStatus.unknown,
          ),
      tireConfigurationRevision: _nonNegativeInt(
        map['tireConfigurationRevision'],
      ),
      tireConfigurationUpdatedAt: DateTime.tryParse(
        '${map['tireConfigurationUpdatedAt'] ?? ''}',
      ),
      archivedAt: DateTime.tryParse('${map['archivedAt'] ?? ''}'),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'nickname': nickname,
    'year': year,
    'make': make,
    'model': model,
    'usage': usage.name,
    'tireSizeStatus': tireSizeStatus.name,
    'speedometerCalibrationStatus': speedometerCalibrationStatus.name,
    'tireConfigurationRevision': tireConfigurationRevision,
    'tireConfigurationUpdatedAt': tireConfigurationUpdatedAt
        ?.toUtc()
        .toIso8601String(),
    'archivedAt': archivedAt?.toUtc().toIso8601String(),
  };

  VehicleProfile copyWith({
    String? nickname,
    String? id,
    String? year,
    String? make,
    String? model,
    VehicleUsage? usage,
    VehicleTireSizeStatus? tireSizeStatus,
    VehicleSpeedometerCalibrationStatus? speedometerCalibrationStatus,
    int? tireConfigurationRevision,
    DateTime? tireConfigurationUpdatedAt,
    bool clearTireConfigurationUpdatedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) => VehicleProfile(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    year: year ?? this.year,
    make: make ?? this.make,
    model: model ?? this.model,
    usage: usage ?? this.usage,
    tireSizeStatus: tireSizeStatus ?? this.tireSizeStatus,
    speedometerCalibrationStatus:
        speedometerCalibrationStatus ?? this.speedometerCalibrationStatus,
    tireConfigurationRevision:
        tireConfigurationRevision ?? this.tireConfigurationRevision,
    tireConfigurationUpdatedAt: clearTireConfigurationUpdatedAt
        ? null
        : tireConfigurationUpdatedAt ?? this.tireConfigurationUpdatedAt,
    archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
  );
}

enum VehicleTireSizeStatus {
  factoryEquivalent,
  largerThanRecommended,
  smallerThanRecommended,
  unknown,
}

enum VehicleSpeedometerCalibrationStatus {
  calibratedForCurrentTires,
  notCalibratedForCurrentTires,
  unknown,
}

int _nonNegativeInt(Object? value) {
  final parsed = value is int ? value : int.tryParse('$value');
  return parsed == null || parsed < 0 ? 0 : parsed;
}

class WorkProfile {
  WorkProfile({required this.name});

  final String name;
}

typedef VehicleProfileStorageCheck = Future<AppStorageCheck> Function();
