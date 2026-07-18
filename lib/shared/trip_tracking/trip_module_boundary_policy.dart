enum TripModuleBoundaryStatus { allowed, blocked }

enum TripModuleBoundaryReason {
  allowedSharedTripDependency,
  blockedFeatureModuleDependency,
  blockedScreenDependency,
  blockedCredentialLikeImport,
}

class TripModuleBoundaryDecision {
  const TripModuleBoundaryDecision({
    required this.status,
    required this.reason,
    required this.importPath,
  });

  final TripModuleBoundaryStatus status;
  final TripModuleBoundaryReason reason;
  final String importPath;

  bool get isAllowed => status == TripModuleBoundaryStatus.allowed;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reason': reason.name,
    'importPathClass': _safeImportClass(importPath),
    'tripTrackingBoundaryEnforced': true,
    'dashboardMayImportTripSummaries': true,
    'tripTrackingMayMutateDashboard': false,
    'tripTrackingMayMutateExpenses': false,
    'tripTrackingMayMutateMaterials': false,
    'tripTrackingMayMutateReceipts': false,
    'tripTrackingMayMutateFuel': false,
    'tripTrackingMayMutateMaintenance': false,
    'sharedDurableStorageAllowed': true,
    'sharedDeviceCapabilityAllowed': true,
    'sharedOdometerAllowed': true,
    'odometerIsGlobalTruth': true,
    'rawFeaturePayloadIncluded': false,
    'privatePathIncluded': false,
    'tokensIncluded': false,
  };
}

class TripModuleBoundaryPolicy {
  const TripModuleBoundaryPolicy._();

  static TripModuleBoundaryDecision evaluateImport(String importPath) {
    final clean = importPath.trim();
    if (_looksLikeCredential(clean)) {
      return _blocked(
        clean,
        TripModuleBoundaryReason.blockedCredentialLikeImport,
      );
    }
    if (_isScreenDependency(clean)) {
      return _blocked(clean, TripModuleBoundaryReason.blockedScreenDependency);
    }
    if (_isFeatureModuleDependency(clean)) {
      return _blocked(
        clean,
        TripModuleBoundaryReason.blockedFeatureModuleDependency,
      );
    }
    return TripModuleBoundaryDecision(
      status: TripModuleBoundaryStatus.allowed,
      reason: TripModuleBoundaryReason.allowedSharedTripDependency,
      importPath: clean,
    );
  }
}

TripModuleBoundaryDecision _blocked(
  String importPath,
  TripModuleBoundaryReason reason,
) {
  return TripModuleBoundaryDecision(
    status: TripModuleBoundaryStatus.blocked,
    reason: reason,
    importPath: importPath,
  );
}

bool _isScreenDependency(String value) {
  final lower = value.toLowerCase();
  return lower.contains('/screens/') ||
      lower.contains('../screens/') ||
      lower.contains('dashboard_screen') ||
      lower.endsWith('_screen.dart');
}

bool _isFeatureModuleDependency(String value) {
  final lower = value.toLowerCase();
  return lower.contains('/receipt') ||
      lower.contains('/receipts') ||
      lower.contains('/expense') ||
      lower.contains('/expenses') ||
      lower.contains('/fuel') ||
      lower.contains('/materials') ||
      lower.contains('/work_supplies') ||
      lower.contains('/inventory') ||
      lower.contains('/maintenance');
}

bool _looksLikeCredential(String value) {
  final lower = value.toLowerCase();
  return lower.contains('token') ||
      lower.contains('secret') ||
      lower.contains('pk.') ||
      lower.contains('sk.');
}

String _safeImportClass(String value) {
  final lower = value.toLowerCase();
  if (_looksLikeCredential(lower)) return 'redacted_credential_like_import';
  if (_isScreenDependency(lower)) return 'screen_dependency';
  if (_isFeatureModuleDependency(lower)) return 'feature_module_dependency';
  if (lower.startsWith('dart:')) return 'dart_sdk';
  if (lower.startsWith('package:flutter')) return 'flutter_sdk';
  if (lower.startsWith('package:')) return 'package_dependency';
  if (lower.startsWith('../')) return 'allowed_shared_relative_dependency';
  return 'local_trip_tracking_dependency';
}
