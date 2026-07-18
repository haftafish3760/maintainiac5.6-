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
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteTotalsCanonical': false,
    'moduleImportsCanMutateTripLog': false,
    'moduleImportsCanMutateExpenses': false,
    'moduleImportsCanMutateMaterials': false,
    'moduleImportsCanMutateMaintenance': false,
    'odometerRemainsOfficialMileageTruth': true,
    'rawModulePayloadIncluded': false,
    'rawReceiptPayloadIncluded': false,
    'rawLocationIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };
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

bool _containsSensitiveValue(String value) {
  final lower = value.toLowerCase();
  return lower.contains('token') ||
      lower.contains('secret') ||
      lower.contains('pk.') ||
      lower.contains('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}').hasMatch(value);
}
