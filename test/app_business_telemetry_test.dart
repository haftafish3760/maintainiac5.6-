import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/business/app_business_telemetry.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'app_business_telemetry_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('summarizes ads, revenue, costs, exports, and tax records', () async {
    final store = await AppBusinessTelemetryStore.create();

    await store.enqueue(
      const AppBusinessTelemetryEvent(
        type: AppBusinessTelemetryEventType.adImpression,
        platform: 'android',
        appVersion: '1.0.0',
        planStatus: 'free',
        impressionCount: 1000,
        metadata: {'adPlacement': 'dashboard_banner'},
      ),
    );
    await store.enqueue(
      const AppBusinessTelemetryEvent(
        type: AppBusinessTelemetryEventType.adRevenueEstimate,
        revenueSource: AppBusinessRevenueSource.ads,
        amountCents: 375,
        metadata: {'adNetwork': 'admob'},
      ),
    );
    await store.enqueue(
      const AppBusinessTelemetryEvent(
        type: AppBusinessTelemetryEventType.subscriptionRevenue,
        revenueSource: AppBusinessRevenueSource.subscription,
        amountCents: 999,
        metadata: {'billingProvider': 'google_play'},
      ),
    );
    await store.enqueue(
      const AppBusinessTelemetryEvent(
        type: AppBusinessTelemetryEventType.firebaseCostEstimate,
        costSource: AppBusinessCostSource.firebase,
        amountCents: 121,
      ),
    );
    await store.enqueue(
      const AppBusinessTelemetryEvent(
        type: AppBusinessTelemetryEventType.aiCostEstimate,
        costSource: AppBusinessCostSource.ai,
        amountCents: 48,
      ),
    );
    await store.enqueue(
      const AppBusinessTelemetryEvent(
        type: AppBusinessTelemetryEventType.exportUsed,
        metadata: {'exportKind': 'expense_month'},
      ),
    );
    await store.enqueue(
      const AppBusinessTelemetryEvent(
        type: AppBusinessTelemetryEventType.taxRecordGenerated,
        metadata: {'taxYear': '2026'},
      ),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 24, 18),
    );
    final map = snapshot.toCommandCenterMap();

    expect(map['schema'], 'app_business_health_v1');
    expect(snapshot.adImpressionCount, 1000);
    expect(snapshot.adRevenueCents, 375);
    expect(snapshot.averageAdCpmCents, 375);
    expect(snapshot.subscriptionRevenueCents, 999);
    expect(snapshot.totalRevenueCents, 1374);
    expect(snapshot.totalCostCents, 169);
    expect(snapshot.estimatedProfitCents, 1205);
    expect(snapshot.exportCount, 1);
    expect(snapshot.taxRecordGeneratedCount, 1);
  });

  test('rejects private business content before storage', () async {
    final store = await AppBusinessTelemetryStore.create();

    expect(
      () => AppBusinessTelemetryPolicy.sanitizeMap({
        'event': AppBusinessTelemetryEventType.subscriptionRevenue.name,
        'email': 'private@example.com',
      }),
      throwsArgumentError,
    );
    expect(
      store.enqueue(
        const AppBusinessTelemetryEvent(
          type: AppBusinessTelemetryEventType.taxRecordGenerated,
          metadata: {'taxId': '123-45-6789'},
        ),
      ),
      throwsArgumentError,
    );
  });
}
