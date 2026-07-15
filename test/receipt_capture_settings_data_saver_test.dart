import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/backup/cloud_backup_quota.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'receipt_capture_settings_data_saver_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('routes default data saver footprint through one controller policy', () async {
    final settings = await ReceiptCaptureSettingsController.create();

    await settings.setDefaultDataSaverLevel(ReceiptDataSaverLevel.maximum);

    expect(
      settings.defaultDataSaverStorageClass,
      ReceiptDeviceStorageClass.critical,
    );
    expect(
      settings.defaultDataSaverCloudAssistPlan.dataSaverLevel,
      ReceiptDataSaverLevel.maximum,
    );
    expect(
      settings.defaultDataSaverFootprintSummary.baseReceiptBudgetBytes,
      40 * 1024 * 1024,
    );
    expect(settings.defaultDataSaverFootprintSummary.optionalLocalPackBytes, 0);
    expect(settings.defaultDataSaverCanRunBaseReceiptFlowLocallyNow, isTrue);
    expect(settings.defaultDataSaverBlocksLowStorageReceiptUsers, isFalse);
    expect(
      settings.defaultDataSaverLocalOnlyAcceptanceGate.statusCode,
      'ready_local_first_optional_packs_deferred',
    );
    expect(
      settings.defaultDataSaverLocalOnlyAcceptanceGate.actionCode,
      'ship_base_capture_save_review_before_optional_packs',
    );
    expect(
      settings.defaultDataSaverLocalOnlyReadinessSummary,
      contains('receipt capture, proof save, and basic local review work now'),
    );
    expect(
      settings.defaultDataSaverLocalOnlyReadinessSummary,
      contains('Bigger offline packs wait until the user chooses them'),
    );
    expect(
      settings.defaultDataSaverFootprintSummary.shouldDeferOptionalLocalPacks,
      isTrue,
    );
    expect(
      settings.defaultDataSaverShouldOfferOptionalLocalParserPacks,
      isFalse,
    );
    expect(
      settings
          .defaultDataSaverFootprintSummary
          .baseInstallKeepsReceiptBrainLean,
      isTrue,
    );
    expect(
      settings.defaultDataSaverFootprintSummary.userFacingInstallChoiceSummary,
      contains(
        'Base receipt capture and basic local reading stay around 40 MB',
      ),
    );
    expect(
      settings
          .defaultDataSaverFootprintSummary
          .userFacingBaseVersusFullOfflineSummary,
      contains(
        'First install needs the receipt camera, proof storage, data saver copies, manual entry, and basic local reading only',
      ),
    );
    expect(
      settings
          .defaultDataSaverFootprintSummary
          .userFacingBaseVersusFullOfflineSummary,
      contains('Do not block receipt capture behind optional OCR/parser packs'),
    );
    expect(
      settings.defaultDataSaverFootprintSummary.userFacingInstallChoiceSummary,
      contains('Keep the phone lean first'),
    );
    expect(
      settings.defaultDataSaverReceiptCapabilitySummary,
      contains(
        'capture receipts, save proof, and read basic receipt details without any extra download',
      ),
    );
    expect(
      settings.defaultDataSaverReceiptCapabilitySummary,
      contains('receipt camera and fuel/simple receipts working first'),
    );
    expect(
      settings.defaultDataSaverReceiptCapabilitySummary,
      contains('receipt reading still uses the clearest source first'),
    );
    expect(
      settings.defaultDataSaverInstallFootprintStrategy.requiredBaseLabel,
      '40 MB',
    );
    expect(
      settings
          .defaultDataSaverInstallFootprintStrategy
          .recommendedDistributionCode,
      'ship_base_receipt_flow_only',
    );
    expect(
      settings.defaultDataSaverInstallFootprintSummary,
      contains(
        'First install: 40 MB for receipt camera, proof save, manual entry, and basic local reading',
      ),
    );
    expect(
      settings.defaultDataSaverInstallFootprintSummary,
      contains(
        'Low-storage phones can still capture and review basic receipts',
      ),
    );
  });

  test(
    'routes cloud proof photo estimates through the settings controller',
    () async {
      final settings = await ReceiptCaptureSettingsController.create();

      await settings.setDefaultDataSaverLevel(ReceiptDataSaverLevel.strong);

      final estimate = settings.defaultDataSaverStorageEstimate(
        photoCount: 3,
        averageOriginalPhotoBytes: 20 * 1024 * 1024,
        cloudQuota: CloudBackupQuotaPolicy.check(
          entitlement: const CloudBackupEntitlement(
            planId: 'test',
            displayName: 'Test',
            quotaBytes: 100 * 1024 * 1024,
            dailySyncLimit: 4,
            immediateSyncAllowed: false,
            policyVersion: 1,
          ),
          usedBytes: 50 * 1024 * 1024,
          pendingBytes: 0,
          backupEnabled: true,
        ),
      );

      expect(estimate.dataSaverLevel, ReceiptDataSaverLevel.strong);
      expect(estimate.estimatedBytesPerSavedProof, 550 * 1024);
      expect(estimate.estimatedProofBytesForCapture, 1650 * 1024);
      expect(estimate.estimatedOriginalBytesForCapture, 60 * 1024 * 1024);
      expect(
        estimate.approximatePhotosRemainingLabel,
        'About 93 more photos at this setting',
      );
      expect(estimate.toPrivacySafeDiagnostics(), isNot(contains('path')));
    },
  );

  test(
    'allows only the small optional parser pack on strong space saving',
    () async {
      final settings = await ReceiptCaptureSettingsController.create();

      await settings.setDefaultDataSaverLevel(ReceiptDataSaverLevel.strong);

      final installChoice = settings.defaultDataSaverParserPackInstallChoice;
      final footprint = settings.defaultDataSaverFootprintSummary;

      expect(
        settings.defaultDataSaverStorageClass,
        ReceiptDeviceStorageClass.low,
      );
      expect(
        installChoice.optionalLocalDownloadPackCodes,
        contains('general_expense_lines_v1'),
      );
      expect(
        installChoice.optionalLocalDownloadPackCodes,
        isNot(contains('materials_inventory_regional_v1')),
      );
      expect(footprint.optionalLocalPackBytes, 24 * 1024 * 1024);
      expect(footprint.requiresExplicitDownload, isTrue);
      expect(footprint.shouldDeferOptionalLocalPacks, isFalse);
      expect(settings.defaultDataSaverCanRunBaseReceiptFlowLocallyNow, isTrue);
      expect(settings.defaultDataSaverBlocksLowStorageReceiptUsers, isFalse);
      expect(
        settings.defaultDataSaverLocalOnlyAcceptanceGate.statusCode,
        'ready_local_first_optional_packs_deferred',
      );
      expect(
        settings.defaultDataSaverLocalOnlyReadinessSummary,
        contains('Stronger offline packs are optional (24 MB)'),
      );
      expect(
        settings.defaultDataSaverShouldOfferOptionalLocalParserPacks,
        isTrue,
      );
      expect(
        footprint.userFacingInstallChoiceSummary,
        contains('24 MB of optional offline receipt help'),
      );
      expect(
        footprint.userFacingInstallChoiceSummary,
        contains('Larger packs should wait'),
      );
      expect(
        settings.defaultDataSaverReceiptCapabilitySummary,
        contains('Stronger offline receipt help is optional (24 MB)'),
      );
      expect(
        settings.defaultDataSaverReceiptCapabilitySummary,
        contains(
          'Low-storage phones keep fuel receipts and basic OCR available',
        ),
      );
      expect(
        settings.defaultDataSaverProofTargetSizePolicy.policyCode,
        'low_storage_proof_450_650kb',
      );
      expect(
        settings
            .defaultDataSaverProofTargetSizePolicy
            .requiresReadabilityReview,
        isTrue,
      );
      expect(
        settings.defaultDataSaverProofTargetSummary,
        contains('550 KB target'),
      );
      expect(
        settings.defaultDataSaverProofTargetSummary,
        contains('Review readability'),
      );
      expect(
        settings
            .defaultDataSaverInstallFootprintStrategy
            .recommendedDistributionCode,
        'ship_base_hide_large_packs_until_storage_allows',
      );
      expect(
        settings.defaultDataSaverInstallFootprintSummary,
        contains('Extra offline receipt help is optional (24 MB)'),
      );
    },
  );

  test(
    'keeps balanced base receipt brain detached from optional packs',
    () async {
      final settings = await ReceiptCaptureSettingsController.create();

      await settings.setDefaultDataSaverLevel(ReceiptDataSaverLevel.balanced);

      final footprint = settings.defaultDataSaverFootprintSummary;
      final routing = settings.defaultDataSaverParserPackRoutingPlan;

      expect(
        settings.defaultDataSaverStorageClass,
        ReceiptDeviceStorageClass.comfortable,
      );
      expect(footprint.baseReceiptBudgetBytes, 40 * 1024 * 1024);
      expect(footprint.includedLocalPackBytes, 0);
      expect(footprint.optionalPacksDetachedFromBaseInstall, isTrue);
      expect(footprint.baseCaptureWorksWithoutOptionalPacks, isTrue);
      expect(footprint.baseInstallKeepsReceiptBrainLean, isTrue);
      expect(settings.defaultDataSaverCanRunBaseReceiptFlowLocallyNow, isTrue);
      expect(settings.defaultDataSaverBlocksLowStorageReceiptUsers, isFalse);
      expect(
        settings.defaultDataSaverLocalOnlyReadinessSummary,
        contains('basic local review work now'),
      );
      expect(
        settings.defaultDataSaverFirstInstallBoundarySummary,
        contains('Required receipt install'),
      );
      expect(
        settings.defaultDataSaverFirstInstallBoundarySummary,
        contains('Low-storage users can start with the base receipt flow'),
      );
      expect(
        routing.userFacingCategoryPackSummary,
        contains('Receipt capture works without downloading these add-ons.'),
      );
      expect(
        routing.userFacingCategoryPackSummary,
        contains('Fuel receipt essentials stay local-first'),
      );
      expect(
        footprint.userFacingInstallChoiceSummary,
        contains('The full offline receipt setup would be about 64 MB'),
      );
      expect(
        footprint.userFacingInstallChoiceSummary,
        contains('Let the user choose before downloading more'),
      );
      expect(
        settings.defaultDataSaverReceiptCapabilitySummary,
        contains('first install stays separate'),
      );
      expect(
        settings.defaultDataSaverReceiptCapabilitySummary,
        contains('This setup stays local by default'),
      );
      expect(
        settings.defaultDataSaverProofTargetSizePolicy.policyCode,
        'normal_proof_800_1000kb',
      );
      expect(
        settings.defaultDataSaverProofTargetSizePolicy.targetBytes,
        900 * 1024,
      );
      expect(
        settings.defaultDataSaverProofTargetSummary,
        contains('900 KB target'),
      );
      expect(
        settings.defaultDataSaverProofTargetSummary,
        contains('safe for normal backup proof copies'),
      );
      expect(
        settings.defaultDataSaverReceiptCapabilitySummary,
        isNot(contains('deviceModel')),
      );
      expect(
        settings.defaultDataSaverReceiptCapabilitySummary,
        isNot(contains('manufacturer')),
      );
    },
  );
}
