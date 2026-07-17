import '../../../shared/storage/app_storage_guard.dart';

class DashboardSummaryTrustBoundary {
  const DashboardSummaryTrustBoundary._();

  static final DateTime minimumTrustedTimestamp = DateTime.utc(2020);

  static DashboardSummaryIdentityDecision validateIdentity({
    required String? uid,
    required String? dashboardId,
    String? orgId,
    String? activeVehicleId,
    String? activeWorkdayId,
    String? activeWorkProfileId,
  }) {
    final cleanUid = uid?.trim();
    final cleanDashboardId = dashboardId?.trim();
    if (cleanUid == null ||
        cleanUid.isEmpty ||
        cleanDashboardId == null ||
        cleanDashboardId.isEmpty) {
      return DashboardSummaryIdentityDecision.reject(
        'dashboard_summary_identity_missing',
      );
    }
    final safeUid = _safeUid(cleanUid);
    final safeDashboardId = _safePathToken(cleanDashboardId);
    if (safeUid == null || safeDashboardId == null) {
      return DashboardSummaryIdentityDecision.reject(
        'dashboard_summary_identity_invalid',
      );
    }
    final safeOrgId = _safeOptionalPathToken(orgId);
    final safeVehicleId = _safeOptionalPathToken(activeVehicleId);
    final safeWorkdayId = _safeOptionalPathToken(activeWorkdayId);
    final safeProfileId = _safeOptionalPathToken(activeWorkProfileId);
    if ((orgId != null && orgId.trim().isNotEmpty && safeOrgId == null) ||
        (activeVehicleId != null &&
            activeVehicleId.trim().isNotEmpty &&
            safeVehicleId == null) ||
        (activeWorkdayId != null &&
            activeWorkdayId.trim().isNotEmpty &&
            safeWorkdayId == null) ||
        (activeWorkProfileId != null &&
            activeWorkProfileId.trim().isNotEmpty &&
            safeProfileId == null)) {
      return DashboardSummaryIdentityDecision.reject(
        'dashboard_summary_identity_invalid',
      );
    }
    return DashboardSummaryIdentityDecision.accept(
      uid: safeUid,
      dashboardId: safeDashboardId,
      orgId: safeOrgId,
      activeVehicleId: safeVehicleId,
      activeWorkdayId: safeWorkdayId,
      activeWorkProfileId: safeProfileId,
    );
  }

  static DashboardSummaryTimestampDecision validateTimestamp(DateTime value) {
    final safe = value.toUtc();
    if (safe.isBefore(minimumTrustedTimestamp)) {
      return DashboardSummaryTimestampDecision.reject(
        'dashboard_summary_clock_untrusted',
      );
    }
    return DashboardSummaryTimestampDecision.accept(safe);
  }

  static AppStorageCheck? validateStorageCheck(AppStorageCheck? check) {
    if (check == null) return null;
    final availableBytes = check.availableBytes;
    if ((availableBytes != null && availableBytes < 0) ||
        check.operationBytes < 0 ||
        check.requiredBytes < 0) {
      return null;
    }
    if (check.requiredBytes < check.operationBytes) return null;
    if (check.purpose != AppStoragePurpose.mileageTracking) return null;
    return check;
  }

  static bool? safeBool(bool? Function()? reader) {
    try {
      return reader?.call();
    } catch (_) {
      return null;
    }
  }

  static int? safeSyncUsage(int? Function()? reader) {
    int? value;
    try {
      value = reader?.call();
    } catch (_) {
      return null;
    }
    if (value == null || value < 0 || value > 999) return null;
    return value;
  }

  static String? _safeUid(String? value) {
    final clean = value?.trim();
    if (clean == null ||
        clean.isEmpty ||
        clean.length > 128 ||
        !RegExp(r'^[A-Za-z0-9:_-]+$').hasMatch(clean)) {
      return null;
    }
    return clean;
  }

  static String? _safeOptionalPathToken(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return _safePathToken(clean);
  }

  static String? _safePathToken(String? value) {
    final clean = value?.trim();
    if (clean == null ||
        clean.isEmpty ||
        clean.length > 128 ||
        clean.contains('/') ||
        clean.contains('..') ||
        !RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(clean)) {
      return null;
    }
    return clean;
  }
}

class DashboardSummaryIdentityDecision {
  const DashboardSummaryIdentityDecision._({
    required this.accepted,
    required this.reasonCode,
    this.uid,
    this.dashboardId,
    this.orgId,
    this.activeVehicleId,
    this.activeWorkdayId,
    this.activeWorkProfileId,
  });

  factory DashboardSummaryIdentityDecision.accept({
    required String uid,
    required String dashboardId,
    String? orgId,
    String? activeVehicleId,
    String? activeWorkdayId,
    String? activeWorkProfileId,
  }) {
    return DashboardSummaryIdentityDecision._(
      accepted: true,
      reasonCode: 'dashboard_summary_identity_valid',
      uid: uid,
      dashboardId: dashboardId,
      orgId: orgId,
      activeVehicleId: activeVehicleId,
      activeWorkdayId: activeWorkdayId,
      activeWorkProfileId: activeWorkProfileId,
    );
  }

  factory DashboardSummaryIdentityDecision.reject(String reasonCode) {
    return DashboardSummaryIdentityDecision._(
      accepted: false,
      reasonCode: reasonCode,
    );
  }

  final bool accepted;
  final String reasonCode;
  final String? uid;
  final String? dashboardId;
  final String? orgId;
  final String? activeVehicleId;
  final String? activeWorkdayId;
  final String? activeWorkProfileId;
}

class DashboardSummaryTimestampDecision {
  const DashboardSummaryTimestampDecision._({
    required this.accepted,
    required this.reasonCode,
    this.updatedAtUtc,
  });

  factory DashboardSummaryTimestampDecision.accept(DateTime updatedAtUtc) {
    return DashboardSummaryTimestampDecision._(
      accepted: true,
      reasonCode: 'dashboard_summary_clock_valid',
      updatedAtUtc: updatedAtUtc.toUtc(),
    );
  }

  factory DashboardSummaryTimestampDecision.reject(String reasonCode) {
    return DashboardSummaryTimestampDecision._(
      accepted: false,
      reasonCode: reasonCode,
    );
  }

  final bool accepted;
  final String reasonCode;
  final DateTime? updatedAtUtc;
}
