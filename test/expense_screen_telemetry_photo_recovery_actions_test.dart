import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

import 'helpers/expense_screen_telemetry_harness.dart';

void main() {
  installExpenseTelemetryHiveLifecycle(
    'expense_screen_telemetry_photo_recovery_actions_test_',
  );

  test(
    'marks expense camera health for review when saved-photo warnings are frequent',
    () async {
      final store = await ExpenseTelemetryStore.create();

      await store.enqueue(
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          metadata: {
            'savedPhotoWarningCounts': {'saved_photo_dimmer_than_preview': 1},
            'savedPhotoWarningCauseCounts': {
              'saved_photo_dim_or_live_to_saved_mismatch': 1,
            },
            'savedPhotoWarningSeverityCounts': {'warning': 1},
            'savedPhotoWarningActionCounts': {'review_or_add_light': 1},
            'hasSavedPhotoQualityWarning': true,
          },
        ),
      );
      await store.enqueue(
        const ExpenseTelemetryEvent(type: ExpenseTelemetryEventType.ocrStarted),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );
      final map = snapshot.toCommandCenterMap();

      expect(snapshot.savedPhotoQualityWarningRate, .5);
      expect(snapshot.savedPhotoWarningCauseCounts, {
        'saved_photo_dim_or_live_to_saved_mismatch': 1,
      });
      expect(snapshot.savedPhotoWarningSeverityCounts, {'warning': 1});
      expect(snapshot.savedPhotoWarningActionCounts, {
        'review_or_add_light': 1,
      });
      expect(snapshot.savedPhotoCriticalWarningCount, 0);
      expect(snapshot.savedPhotoCriticalWarningRate, 0);
      expect(snapshot.topSavedPhotoWarningSeverity, 'warning');
      expect(
        snapshot.topSavedPhotoWarningCause,
        'saved_photo_dim_or_live_to_saved_mismatch',
      );
      expect(snapshot.topSavedPhotoWarningActionCode, 'review_or_add_light');
      expect(snapshot.needsAttention, isTrue);
      expect(snapshot.healthLabel, 'review');
      expect(map['savedPhotoQualityWarningRate'], .5);
      expect(map['savedPhotoWarningCauseCounts'], {
        'saved_photo_dim_or_live_to_saved_mismatch': 1,
      });
      expect(map['savedPhotoWarningSeverityCounts'], {'warning': 1});
      expect(map['savedPhotoWarningActionCounts'], {'review_or_add_light': 1});
      expect(map['savedPhotoCriticalWarningRate'], 0);
      expect(map['topSavedPhotoWarning'], 'saved_photo_dimmer_than_preview');
      expect(
        map['topSavedPhotoWarningCause'],
        'saved_photo_dim_or_live_to_saved_mismatch',
      );
      expect(map['topSavedPhotoWarningSeverity'], 'warning');
      expect(map['topSavedPhotoWarningActionCode'], 'review_or_add_light');
      expect(map.toString().toLowerCase(), isNot(contains('lowes')));
    },
  );

  test(
    'summarizes critical saved-photo warnings for Command 1 without receipt content',
    () async {
      final store = await ExpenseTelemetryStore.create();

      await store.enqueue(
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          metadata: {
            'savedPhotoWarningCounts': {
              'saved_photo_darker_than_preview': 1,
              'saved_photo_soft_blur_risk': 1,
            },
            'savedPhotoWarningCauseCounts': {
              'saved_photo_darker_than_live_preview': 1,
              'saved_photo_soft_blur_risk': 1,
            },
            'savedPhotoWarningSeverityCounts': {'critical': 2},
            'savedPhotoWarningActionCounts': {
              'retake_with_more_light': 1,
              'retake_hold_steady': 1,
            },
            'savedPhotoParserRiskCounts': {
              'ocr_item_prices_may_fail': 1,
              'ocr_text_or_total_may_fail': 1,
            },
            'hasSavedPhotoQualityWarning': true,
          },
        ),
      );
      await store.enqueue(
        const ExpenseTelemetryEvent(type: ExpenseTelemetryEventType.ocrStarted),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expect(snapshot.savedPhotoWarningCauseCounts, {
        'saved_photo_darker_than_live_preview': 1,
        'saved_photo_soft_blur_risk': 1,
      });
      expect(snapshot.savedPhotoWarningSeverityCounts, {'critical': 2});
      expect(snapshot.savedPhotoWarningActionCounts, {
        'retake_hold_steady': 1,
        'retake_with_more_light': 1,
      });
      expect(snapshot.savedPhotoParserRiskCounts, {
        'ocr_item_prices_may_fail': 1,
        'ocr_text_or_total_may_fail': 1,
      });
      expect(snapshot.savedPhotoQualityWarningCount, 1);
      expect(snapshot.savedPhotoQualityWarningRate, .5);
      expect(snapshot.savedPhotoCriticalWarningCount, 2);
      expect(snapshot.savedPhotoCriticalWarningRate, 1);
      expect(
        snapshot.topSavedPhotoWarningCause,
        'saved_photo_darker_than_live_preview',
      );
      expect(snapshot.topSavedPhotoWarningSeverity, 'critical');
      expect(snapshot.topSavedPhotoWarningActionCode, 'retake_hold_steady');
      expect(snapshot.topSavedPhotoWarningAction, contains('exposure'));
      expect(snapshot.topSavedPhotoParserRisk, 'ocr_item_prices_may_fail');
      expect(map['savedPhotoWarningSeverityCounts'], {'critical': 2});
      expect(map['savedPhotoWarningActionCounts'], {
        'retake_hold_steady': 1,
        'retake_with_more_light': 1,
      });
      expect(map['savedPhotoParserRiskCounts'], {
        'ocr_item_prices_may_fail': 1,
        'ocr_text_or_total_may_fail': 1,
      });
      expect(map['savedPhotoWarningCauseCounts'], {
        'saved_photo_darker_than_live_preview': 1,
        'saved_photo_soft_blur_risk': 1,
      });
      expect(map['savedPhotoCriticalWarningCount'], 2);
      expect(map['savedPhotoCriticalWarningRate'], 1);
      expect(
        map['topSavedPhotoWarningCause'],
        'saved_photo_darker_than_live_preview',
      );
      expect(map['topSavedPhotoWarningSeverity'], 'critical');
      expect(map['topSavedPhotoWarningActionCode'], 'retake_hold_steady');
      expect(map['topSavedPhotoWarningAction'], contains('exposure'));
      expect(map['topSavedPhotoParserRisk'], 'ocr_item_prices_may_fail');
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('receipt text')));
    },
  );

  test(
    'gives Command 1 a recovery action when interrupted receipt photos are stale or missing',
    () async {
      final store = await ExpenseTelemetryStore.create();

      await store.enqueue(
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          metadata: {
            'nativeRecoveryFreshnessBuckets': {'very_stale': 2},
            'nativeRecoveryStorageStatusBuckets': {
              'photos_missing': 1,
              'partial_photos_available': 1,
            },
            'nativeRecoveryRecoveredPhotoTotal': 1,
            'nativeRecoveryMultipleSectionCount': 1,
          },
        ),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 29, 5),
      );
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expect(snapshot.nativeRecoveryFreshnessCounts, {'very_stale': 2});
      expect(snapshot.nativeRecoveryStorageStatusCounts, {
        'partial_photos_available': 1,
        'photos_missing': 1,
      });
      expect(snapshot.topNativeRecoveryFreshness, 'very_stale');
      expect(
        snapshot.topNativeRecoveryStorageStatus,
        'partial_photos_available',
      );
      expect(
        snapshot.topNativeRecoveryAction,
        contains('Saved photos are missing'),
      );
      expect(snapshot.topNativeRecoveryAction, contains('retakes'));
      expect(map['topNativeRecoveryAction'], snapshot.topNativeRecoveryAction);
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('receipt text')));
      expect(encoded, isNot(contains('99.99')));
    },
  );
}
