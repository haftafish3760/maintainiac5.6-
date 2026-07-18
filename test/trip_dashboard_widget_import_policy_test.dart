import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_dashboard_widget_import_policy.dart';

void main() {
  test('trip summary widget can render without maps or source mutation', () {
    final decision = TripDashboardWidgetImportPolicy.evaluate(
      descriptor(sourceModule: TripDashboardWidgetSourceModule.tripTracking),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.isRenderable, isTrue);
    expect(safe['summaryOnlyImport'], isTrue);
    expect(safe['tripTrackingStartButtonShouldRemainPrimary'], isTrue);
    expect(safe['mapsRequiredForDashboardWidget'], isFalse);
  });

  test(
    'expense and maintenance summaries are render-only dashboard imports',
    () {
      for (final module in const [
        TripDashboardWidgetSourceModule.expenses,
        TripDashboardWidgetSourceModule.maintenance,
        TripDashboardWidgetSourceModule.materials,
      ]) {
        final decision = TripDashboardWidgetImportPolicy.evaluate(
          descriptor(sourceModule: module, widgetId: '${module.name}_summary'),
        );

        expect(decision.isRenderable, isTrue);
        expect(decision.sourceModule, module);
        expect(
          decision.reason,
          TripDashboardWidgetImportReason.renderSummaryOnly,
        );
      }
    },
  );

  test('mutating or raw-payload imports are blocked', () {
    final mutating = TripDashboardWidgetImportPolicy.evaluate(
      descriptor(mutatesSourceModule: true),
    );
    final raw = TripDashboardWidgetImportPolicy.evaluate(
      descriptor(rawPayloadIncluded: true),
    );

    expect(mutating.status, TripDashboardWidgetImportStatus.blocked);
    expect(
      mutating.reason,
      TripDashboardWidgetImportReason.mutatingImportRejected,
    );
    expect(raw.status, TripDashboardWidgetImportStatus.blocked);
    expect(raw.reason, TripDashboardWidgetImportReason.unsafePayload);
  });

  test(
    'customization controls are required for imported dashboard widgets',
    () {
      final fixed = TripDashboardWidgetImportPolicy.evaluate(
        descriptor(userCanRemove: false),
      );
      final noOpen = TripDashboardWidgetImportPolicy.evaluate(
        descriptor(opensSourceScreen: false),
      );

      expect(fixed.reason, TripDashboardWidgetImportReason.unsafeSourceModule);
      expect(noOpen.reason, TripDashboardWidgetImportReason.unsafeSourceModule);
    },
  );

  test('safe import summaries never expose module payloads or authority', () {
    final safe = TripDashboardWidgetImportPolicy.evaluate(
      descriptor(sourceModule: TripDashboardWidgetSourceModule.expenses),
    ).toSafeDashboardMap();

    expect(safe['dashboardCanMutateSourceModule'], isFalse);
    expect(safe['moduleImportsCanMutateExpenses'], isFalse);
    expect(safe['moduleImportsCanMutateMaterials'], isFalse);
    expect(safe['moduleImportsCanMutateMaintenance'], isFalse);
    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['remoteTotalsCanonical'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['rawModulePayloadIncluded'], isFalse);
    expect(safe['rawReceiptPayloadIncluded'], isFalse);
    expect(safe['rawLocationIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test('token-like widget metadata is rejected before rendering', () {
    final decision = TripDashboardWidgetImportPolicy.evaluate(
      descriptor(
        widgetId: 'pk.secret',
        title: 'Expense token=sk.secret',
        summaryMetricToken: 'summary_35.12345',
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripDashboardWidgetImportStatus.blocked);
    expect(safe['widgetId'], 'invalid_widget');
    expect(safe['renderToken'], 'blocked_widget');
    expect(safe.toString(), isNot(contains('pk.secret')));
    expect(safe.toString(), isNot(contains('sk.secret')));
    expect(safe.toString(), isNot(contains('35.12345')));
  });
}

TripDashboardWidgetDescriptor descriptor({
  String widgetId = 'trip_summary',
  TripDashboardWidgetSourceModule sourceModule =
      TripDashboardWidgetSourceModule.tripTracking,
  String title = 'Trip summary',
  String summaryMetricToken = 'summary_trip_miles',
  bool userCanRemove = true,
  bool userCanReorder = true,
  bool opensSourceScreen = true,
  bool mutatesSourceModule = false,
  bool rawPayloadIncluded = false,
}) {
  return TripDashboardWidgetDescriptor(
    widgetId: widgetId,
    sourceModule: sourceModule,
    title: title,
    summaryMetricToken: summaryMetricToken,
    userCanRemove: userCanRemove,
    userCanReorder: userCanReorder,
    opensSourceScreen: opensSourceScreen,
    mutatesSourceModule: mutatesSourceModule,
    rawPayloadIncluded: rawPayloadIncluded,
  );
}
