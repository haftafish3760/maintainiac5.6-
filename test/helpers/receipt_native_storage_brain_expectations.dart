import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';

void expectStorageSaverReceiptBrainArguments(
  Map<dynamic, dynamic> sentArguments,
  ReceiptNativeCaptureResult result,
) {
  expect(sentArguments['receiptBrainMode'], 'base_local_reader_only');
  expect(sentArguments['receiptBrainLocalOcrMode'], 'lean_local_ocr');
  expect(sentArguments['receiptBrainBaseCaptureAvailable'], isTrue);
  expect(sentArguments['receiptBrainLocalReaderDefault'], isTrue);
  expect(sentArguments['receiptBrainOptionalLocalPackAllowed'], isFalse);
  expect(sentArguments['receiptBrainOptionalLocalPackBytes'], 0);
  expect(sentArguments['receiptBrainAssistFallbackAllowed'], isTrue);
  expect(sentArguments['receiptBrainRequiresInternetForAssist'], isTrue);
  expect(sentArguments['receiptBrainStorageClass'], 'critical');
  expect(sentArguments['receiptBrainDeviceTier'], 'heavyweight');
  expect(sentArguments['receiptBrainKeepsBaseInstallLean'], isTrue);
  expect(sentArguments['receiptBrainBaseBudgetBytes'], 40 * 1024 * 1024);
  expect(sentArguments['receiptBrainIncludedLocalPackBytes'], 0);
  expect(sentArguments['receiptBrainFullOfflineBudgetBytes'], 64 * 1024 * 1024);
  expect(sentArguments['receiptBrainBaseWorksWithoutOptionalPacks'], isTrue);
  expect(sentArguments['receiptBrainOptionalPacksDetachedFromBase'], isTrue);
  expect(sentArguments['receiptBrainShouldDeferOptionalLocalPacks'], isTrue);
  expect(sentArguments['receiptBrainRequiresExplicitDownload'], isFalse);
  expect(sentArguments['receiptBrainBaseInstallKeepsLean'], isTrue);
  expect(sentArguments['receiptBrainBaseUnderRequiredBudget'], isTrue);
  expect(
    sentArguments['localOnlyCapturePolicy'],
    'capture_save_basic_review_now_optional_packs_later',
  );
  expect(sentArguments['localOnlyBaseFlowCanRunNow'], isTrue);
  expect(sentArguments['localOnlyHeavyPacksMayBlockCapture'], isFalse);
  expect(sentArguments['localOnlyCloudAssistMayBlockCapture'], isFalse);
  expect(sentArguments['localOnlyCameraMustStayAvailableBeforePacks'], isTrue);
  expect(
    sentArguments['localOnlyProofSaveMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    sentArguments['localOnlyBasicReviewMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    sentArguments['receiptBrainBaseBudgetTierCode'],
    'lean_base_under_40mb',
  );
  expect(
    sentArguments['receiptBrainRequiredBaseReleaseActionCode'],
    'ship_lean_base_and_defer_optional_receipt_packs',
  );
  expect(
    sentArguments['receiptBrainInstallDistributionModeCode'],
    'base_app_only_optional_cloud_assist',
  );
  expect(
    sentArguments['receiptBrainUserFacingInstallChoiceSummary'],
    contains('Base receipt capture and basic local reading stay around 40 MB'),
  );
  expect(
    sentArguments['receiptBrainUserFacingInstallChoiceSummary'],
    contains('Keep the phone lean first'),
  );
  expect(
    sentArguments['receiptBrainUserFacingBaseVersusFullOfflineSummary'],
    contains('First install needs the receipt camera'),
  );
  expect(
    sentArguments['receiptBrainUserFacingBaseVersusFullOfflineSummary'],
    contains('Do not block receipt capture behind optional OCR/parser packs'),
  );
  expect(
    sentArguments['receiptBrainRequiredBaseGuardrailSummary'],
    contains('required receipt camera stays under 100 MB'),
  );
  expect(
    result.captureDiagnostics['receiptBrainMode'],
    'base_local_reader_only',
  );
  expect(result.captureDiagnostics['receiptBrainKeepsBaseInstallLean'], isTrue);
  expect(
    result.captureDiagnostics['receiptBrainBaseBudgetBytes'],
    40 * 1024 * 1024,
  );
  expect(
    result.captureDiagnostics['receiptBrainShouldDeferOptionalLocalPacks'],
    isTrue,
  );
  expect(result.captureDiagnostics['receiptBrainBaseInstallKeepsLean'], isTrue);
  expect(
    result.captureDiagnostics['receiptBrainBaseUnderRequiredBudget'],
    isTrue,
  );
  expect(
    result.captureDiagnostics['receiptBrainBaseBudgetTierCode'],
    'lean_base_under_40mb',
  );
  expect(
    result.captureDiagnostics['receiptBrainRequiredBaseReleaseActionCode'],
    'ship_lean_base_and_defer_optional_receipt_packs',
  );
  expect(
    result.captureDiagnostics['receiptBrainInstallDistributionModeCode'],
    'base_app_only_optional_cloud_assist',
  );
  expect(
    result.captureDiagnostics['receiptBrainRequiredBaseGuardrailSummary'],
    contains('required receipt camera stays under 100 MB'),
  );
  expect(
    result.captureDiagnostics['receiptBrainUserFacingInstallChoiceSummary'],
    contains('Base receipt capture and basic local reading stay around 40 MB'),
  );
  expect(
    result
        .captureDiagnostics['receiptBrainUserFacingBaseVersusFullOfflineSummary'],
    contains('First install needs the receipt camera'),
  );
}
