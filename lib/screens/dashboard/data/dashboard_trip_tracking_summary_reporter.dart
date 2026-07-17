import '../../../shared/storage/app_storage_guard.dart';
import '../../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../../shared/trip_tracking/trip_tracking_settings_store.dart';
import 'active_workday_store.dart';
import 'dashboard_firestore_mirror.dart';
import 'dashboard_trip_tracking_summary.dart';

typedef DashboardSummaryStringReader = String? Function();
typedef DashboardSummaryIntReader = int? Function();
typedef DashboardSummaryBoolReader = bool? Function();
typedef DashboardSummaryClock = DateTime Function();
typedef DashboardSummaryStorageReader = Future<AppStorageCheck?> Function();

class DashboardTripTrackingSummaryReport {
  const DashboardTripTrackingSummaryReport({
    required this.queued,
    required this.reasonCode,
    required this.summary,
  });

  final bool queued;
  final String reasonCode;
  final DashboardTripTrackingSummary? summary;
}

/// Queues reference-only dashboard trip tracking state.
///
/// The dashboard summary intentionally contains no raw GPS samples, routes,
/// addresses, receipt text, local file paths, or Mapbox geometry. It is a
/// Firebase-safe command-center mirror, not a source of truth.
class DashboardTripTrackingSummaryReporter {
  DashboardTripTrackingSummaryReporter({
    required DashboardFirestoreMirror mirror,
    required TripTrackingSettingsController settingsController,
    required DashboardSummaryStringReader uid,
    required DashboardSummaryStringReader dashboardId,
    DashboardSummaryStringReader? orgId,
    DashboardSummaryStringReader? activeVehicleId,
    DashboardSummaryStringReader? activeWorkdayId,
    DashboardSummaryStringReader? activeWorkProfileId,
    TripTrackingController? tripTracking,
    ActiveWorkdayController? activeWorkday,
    DashboardSummaryStorageReader? storageReader,
    DashboardSummaryBoolReader? wifiAvailable,
    DashboardSummaryBoolReader? mobileDataAvailable,
    DashboardSummaryIntReader? syncsUsedInWindow,
    DashboardSummaryClock? clock,
  }) : _mirror = mirror,
       _settingsController = settingsController,
       _uid = uid,
       _dashboardId = dashboardId,
       _orgId = orgId,
       _activeVehicleId = activeVehicleId,
       _activeWorkdayId = activeWorkdayId,
       _activeWorkProfileId = activeWorkProfileId,
       _tripTracking = tripTracking,
       _activeWorkday = activeWorkday,
       _storageReader = storageReader,
       _wifiAvailable = wifiAvailable,
       _mobileDataAvailable = mobileDataAvailable,
       _syncsUsedInWindow = syncsUsedInWindow,
       _clock = clock ?? DateTime.now;

  final DashboardFirestoreMirror _mirror;
  final TripTrackingSettingsController _settingsController;
  final DashboardSummaryStringReader _uid;
  final DashboardSummaryStringReader _dashboardId;
  final DashboardSummaryStringReader? _orgId;
  final DashboardSummaryStringReader? _activeVehicleId;
  final DashboardSummaryStringReader? _activeWorkdayId;
  final DashboardSummaryStringReader? _activeWorkProfileId;
  final TripTrackingController? _tripTracking;
  final ActiveWorkdayController? _activeWorkday;
  final DashboardSummaryStorageReader? _storageReader;
  final DashboardSummaryBoolReader? _wifiAvailable;
  final DashboardSummaryBoolReader? _mobileDataAvailable;
  final DashboardSummaryIntReader? _syncsUsedInWindow;
  final DashboardSummaryClock _clock;
  var _queueInFlight = false;
  var _queueAgainRequested = false;

  Future<DashboardTripTrackingSummaryReport> queueNow() async {
    if (_queueInFlight) {
      _queueAgainRequested = true;
      return const DashboardTripTrackingSummaryReport(
        queued: false,
        reasonCode: 'dashboard_summary_queue_in_flight',
        summary: null,
      );
    }
    _queueInFlight = true;
    try {
      var report = await _queueOnce();
      while (_queueAgainRequested) {
        _queueAgainRequested = false;
        report = await _queueOnce();
      }
      return report;
    } finally {
      _queueInFlight = false;
    }
  }

  Future<DashboardTripTrackingSummaryReport> _queueOnce() async {
    final uid = _safeRequiredId(_uid());
    final dashboardId = _safeRequiredId(_dashboardId());
    if (uid == null || dashboardId == null) {
      return const DashboardTripTrackingSummaryReport(
        queued: false,
        reasonCode: 'dashboard_summary_identity_missing',
        summary: null,
      );
    }
    try {
      final storage = await _readStorage();
      final summary = DashboardTripTrackingSummary.fromRuntime(
        settings: _settingsController.settings,
        tripTracking: _tripTracking,
        activeWorkday: _activeWorkday?.activeSession,
        storageCheck: storage,
        wifiAvailable: _safeBool(_wifiAvailable),
        mobileDataAvailable: _safeBool(_mobileDataAvailable),
        syncsUsedInWindow: _safeInt(_syncsUsedInWindow),
      );
      await _mirror.queueTripTrackingSummary(
        uid: uid,
        dashboardId: dashboardId,
        updatedAtUtc: _clock().toUtc(),
        tripTracking: summary,
        orgId: _safeOptionalId(_orgId?.call()),
        activeVehicleId: _safeOptionalId(_activeVehicleId?.call()),
        activeWorkdayId: _safeOptionalId(_activeWorkdayId?.call()),
        activeWorkProfileId: _safeOptionalId(_activeWorkProfileId?.call()),
      );
      return DashboardTripTrackingSummaryReport(
        queued: true,
        reasonCode: 'dashboard_summary_queued',
        summary: summary,
      );
    } catch (_) {
      return const DashboardTripTrackingSummaryReport(
        queued: false,
        reasonCode: 'dashboard_summary_queue_failed',
        summary: null,
      );
    }
  }

  Future<AppStorageCheck?> _readStorage() async {
    final reader = _storageReader;
    if (reader == null) return null;
    try {
      return await reader();
    } catch (_) {
      return null;
    }
  }
}

String? _safeRequiredId(String? value) {
  final clean = value?.trim();
  if (clean == null || clean.isEmpty) return null;
  return clean;
}

String? _safeOptionalId(String? value) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? null : clean;
}

bool? _safeBool(DashboardSummaryBoolReader? reader) {
  try {
    return reader?.call();
  } catch (_) {
    return null;
  }
}

int? _safeInt(DashboardSummaryIntReader? reader) {
  try {
    return reader?.call();
  } catch (_) {
    return null;
  }
}
