enum TripDashboardWidgetSourceModule {
  tripTracking,
  expenses,
  maintenance,
  materials,
  invoices,
  estimates,
  payments,
  calendar,
}

enum TripDashboardWidgetImportStatus { renderable, blocked }

enum TripDashboardWidgetImportReason {
  renderSummaryOnly,
  unsupportedWidget,
  unsafeSourceModule,
  unsafePayload,
  mutatingImportRejected,
}

class TripDashboardWidgetDescriptor {
  const TripDashboardWidgetDescriptor({
    required this.widgetId,
    required this.sourceModule,
    required this.title,
    required this.summaryMetricToken,
    required this.userCanRemove,
    required this.userCanReorder,
    required this.opensSourceScreen,
    this.mutatesSourceModule = false,
    this.rawPayloadIncluded = false,
  });

  final String widgetId;
  final TripDashboardWidgetSourceModule sourceModule;
  final String title;
  final String summaryMetricToken;
  final bool userCanRemove;
  final bool userCanReorder;
  final bool opensSourceScreen;
  final bool mutatesSourceModule;
  final bool rawPayloadIncluded;
}

class TripDashboardWidgetImportDecision {
  const TripDashboardWidgetImportDecision({
    required this.status,
    required this.reason,
    required this.widgetId,
    required this.sourceModule,
    required this.renderToken,
  });

  final TripDashboardWidgetImportStatus status;
  final TripDashboardWidgetImportReason reason;
  final String widgetId;
  final TripDashboardWidgetSourceModule sourceModule;
  final String renderToken;

  bool get isRenderable => status == TripDashboardWidgetImportStatus.renderable;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reason': reason.name,
    'widgetId': _safeIdentifier(widgetId) ? widgetId : 'invalid_widget',
    'sourceModule': sourceModule.name,
    'renderToken': _safeRenderToken(renderToken),
    'isRenderable': isRenderable,
    'summaryOnlyImport': true,
    'dashboardCanRenderModuleSummary': isRenderable,
    'dashboardCanMutateSourceModule': false,
    'longPressCanCustomizeWidget': true,
    'userCanRemoveWidget': true,
    'userCanReorderWidget': true,
    'opensSourceScreenForEdits': true,
    'dashboardScrollsForAdditionalWidgets': true,
    'tripTrackingStartButtonShouldRemainPrimary': true,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForDashboardWidget': false,
    'sourceModuleOwnershipValidated': true,
    'authenticationAloneAuthorizesWidgetAccess': false,
    'importedWidgetCanOpenSensitiveReview': false,
    'importedWidgetCanConfirmOdometer': false,
    'importedWidgetCanCreateOfficialStop': false,
    'importedWidgetCanDeleteLocalData': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteTotalsCanonical': false,
    'moduleImportsCanMutateTripLog': false,
    'moduleImportsCanMutateExpenses': false,
    'moduleImportsCanMutateMaterials': false,
    'moduleImportsCanMutateMaintenance': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'rawModulePayloadIncluded': false,
    'rawReceiptPayloadIncluded': false,
    'rawLocationIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
}

class TripDashboardWidgetImportSummaryValidation {
  const TripDashboardWidgetImportSummaryValidation._({
    required this.isRenderable,
    required this.sourceModule,
    required this.reasons,
  });

  factory TripDashboardWidgetImportSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    final status = _safeStatus(summary['status']);
    final reason = _safeReason(summary['reason']);
    final sourceModule = _safeSourceModule(summary['sourceModule']);

    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (status == null) reasons.add('invalid_import_status');
    if (reason == null) reasons.add('invalid_import_reason');
    if (sourceModule == null) reasons.add('invalid_source_module');
    if (summary['widgetId'] is! String ||
        !_safeIdentifier(summary['widgetId'] as String)) {
      reasons.add('invalid_widget_id');
    }
    if (summary['renderToken'] is! String ||
        !_safeRenderToken(
          summary['renderToken'] as String,
        ).startsWith('summary_')) {
      reasons.add('invalid_render_token');
    }
    for (final key in const [
      'isRenderable',
      'summaryOnlyImport',
      'dashboardCanRenderModuleSummary',
      'longPressCanCustomizeWidget',
      'userCanRemoveWidget',
      'userCanReorderWidget',
      'opensSourceScreenForEdits',
      'dashboardScrollsForAdditionalWidgets',
      'tripTrackingStartButtonShouldRemainPrimary',
      'gpsAssistedTrackingAvailableWithoutMaps',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'sourceModuleOwnershipValidated',
    ]) {
      if (summary[key] != true) reasons.add('${key}_not_true');
    }
    for (final key in const [
      'dashboardCanMutateSourceModule',
      'mapsRequiredForDashboardWidget',
      'remoteTotalsCanonical',
      'moduleImportsCanMutateTripLog',
      'moduleImportsCanMutateExpenses',
      'moduleImportsCanMutateMaterials',
      'moduleImportsCanMutateMaintenance',
      'authenticationAloneAuthorizesWidgetAccess',
      'importedWidgetCanOpenSensitiveReview',
      'importedWidgetCanConfirmOdometer',
      'importedWidgetCanCreateOfficialStop',
      'importedWidgetCanDeleteLocalData',
      'rawModulePayloadIncluded',
      'rawReceiptPayloadIncluded',
      'rawLocationIncluded',
      'preciseLocationIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] != false) reasons.add('${key}_not_false');
    }
    if (summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true) {
      reasons.add('odometer_truth_boundary_missing');
    }
    if (summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_text');
    }

    return TripDashboardWidgetImportSummaryValidation._(
      isRenderable:
          reasons.isEmpty &&
          status == TripDashboardWidgetImportStatus.renderable &&
          reason == TripDashboardWidgetImportReason.renderSummaryOnly,
      sourceModule: reasons.isEmpty ? sourceModule : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final TripDashboardWidgetSourceModule? sourceModule;
  final List<String> reasons;
}

class TripDashboardWidgetImportPolicy {
  const TripDashboardWidgetImportPolicy._();

  static TripDashboardWidgetImportDecision evaluate(
    TripDashboardWidgetDescriptor descriptor,
  ) {
    if (!_safeIdentifier(descriptor.widgetId) ||
        !_safeTitle(descriptor.title) ||
        !_safeRenderToken(
          descriptor.summaryMetricToken,
        ).startsWith('summary_')) {
      return _blocked(
        descriptor,
        TripDashboardWidgetImportReason.unsupportedWidget,
      );
    }
    if (descriptor.mutatesSourceModule) {
      return _blocked(
        descriptor,
        TripDashboardWidgetImportReason.mutatingImportRejected,
      );
    }
    if (descriptor.rawPayloadIncluded) {
      return _blocked(
        descriptor,
        TripDashboardWidgetImportReason.unsafePayload,
      );
    }
    if (!descriptor.userCanRemove ||
        !descriptor.userCanReorder ||
        !descriptor.opensSourceScreen) {
      return _blocked(
        descriptor,
        TripDashboardWidgetImportReason.unsafeSourceModule,
      );
    }
    return TripDashboardWidgetImportDecision(
      status: TripDashboardWidgetImportStatus.renderable,
      reason: TripDashboardWidgetImportReason.renderSummaryOnly,
      widgetId: descriptor.widgetId,
      sourceModule: descriptor.sourceModule,
      renderToken: descriptor.summaryMetricToken,
    );
  }
}

TripDashboardWidgetImportDecision _blocked(
  TripDashboardWidgetDescriptor descriptor,
  TripDashboardWidgetImportReason reason,
) {
  return TripDashboardWidgetImportDecision(
    status: TripDashboardWidgetImportStatus.blocked,
    reason: reason,
    widgetId: descriptor.widgetId,
    sourceModule: descriptor.sourceModule,
    renderToken: 'blocked_widget',
  );
}

bool _safeIdentifier(String value) =>
    value.trim() == value &&
    value.isNotEmpty &&
    value.length <= 80 &&
    RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(value) &&
    !_containsSensitiveValue(value);

bool _safeTitle(String value) {
  final clean = value.trim();
  return clean.isNotEmpty &&
      clean.length <= 80 &&
      !_containsSensitiveValue(clean);
}

String _safeRenderToken(String value) {
  final clean = value.trim();
  if (clean.isEmpty ||
      clean.length > 80 ||
      !_safeRenderTokenPattern.hasMatch(clean) ||
      _containsSensitiveValue(clean)) {
    return 'blocked_widget';
  }
  return clean;
}

final RegExp _safeRenderTokenPattern = RegExp(r'^[a-z0-9_]+$');

TripDashboardWidgetImportStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripDashboardWidgetImportStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

TripDashboardWidgetImportReason? _safeReason(Object? value) {
  if (value is! String) return null;
  for (final reason in TripDashboardWidgetImportReason.values) {
    if (reason.name == value) return reason;
  }
  return null;
}

TripDashboardWidgetSourceModule? _safeSourceModule(Object? value) {
  if (value is! String) return null;
  for (final module in TripDashboardWidgetSourceModule.values) {
    if (module.name == value) return module;
  }
  return null;
}

bool _containsSensitiveValue(String value) {
  final lower = value.toLowerCase();
  return lower.contains('token') ||
      lower.contains('secret') ||
      lower.contains('pk.') ||
      lower.contains('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}').hasMatch(value);
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  return _containsSensitiveValue(value) ||
      value.toLowerCase().contains('authorization:');
}
