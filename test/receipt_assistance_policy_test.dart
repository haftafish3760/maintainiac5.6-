import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';

import 'helpers/receipt_assistance_policy_fixtures.dart';

void main() {
  test('imported receipt text uses local reading immediately', () {
    final decision = const ReceiptAssistancePolicy().decideForAttachment(
      receiptAttachmentFixture(
        kind: ReceiptAttachmentKind.emailText,
        importedText: 'LOWES\nTOTAL 12.34',
      ),
    );

    expect(decision.mode, ReceiptAssistanceMode.localRead);
    expect(decision.shouldReadLocally, isTrue);
  });

  test('older phone profile keeps heavy PDF proof-only', () {
    final decision =
        const ReceiptAssistancePolicy(
          device: ReceiptDeviceCapability.olderPhone(),
        ).decideForAttachment(
          receiptAttachmentFixture(
            kind: ReceiptAttachmentKind.pdf,
            byteSize: 12 * 1024 * 1024,
            pageCount: 18,
          ),
        );

    expect(decision.mode, ReceiptAssistanceMode.proofOnly);
    expect(decision.reason, contains('Older phone'));
  });

  test(
    'critical storage trims flagship receipt workload without requiring cloud',
    () {
      final capability = const ReceiptDeviceCapability.highCapacity()
          .withStoragePressure(ReceiptDeviceStorageClass.critical);
      final plan = capability.cloudAssistPlan;

      expect(capability.tier, ReceiptCapabilityTier.light);
      expect(capability.parserDepth, ReceiptParserDepth.proofTotalsOnly);
      expect(
        capability.recommendedDataSaverLevel,
        ReceiptDataSaverLevel.maximum,
      );
      expect(capability.maxLocalPhotoBytes, 4 * 1024 * 1024);
      expect(capability.maxLocalPhotoCount, 4);
      expect(capability.assistedCameraShotCount, 1);
      expect(capability.bestShotCandidateCount, 1);
      expect(capability.maxLocalCatalogMatches, 150);
      expect(capability.maxLocalInventoryCacheItems, 400);
      expect(
        capability
            .cameraRuntimeProfileFor(
              guidanceRequested: true,
              startAssistedRequested: true,
              autoCaptureRequested: true,
              longReceiptTipsRequested: true,
            )
            .autoCaptureEnabled,
        isFalse,
      );
      expect(plan.localOcrAvailable, isTrue);
      expect(plan.localOcrMode, 'lean_local_ocr');
      expect(plan.cloudOcrOptional, isTrue);
      expect(plan.cloudInventoryOptional, isTrue);
      expect(
        plan.toPrivacySafeDiagnostics(),
        containsPair('cameraCaptureCloudRequired', false),
      );
      expect(plan.estimatedOptionalLocalPackBytes, 0);
      expect(plan.parserPackCodes, [
        'core_receipt_text_v1',
        'cloud_ocr_assist_v1',
      ]);
    },
  );

  test(
    'unknown RAM does not automatically force capable devices into light tier',
    () {
      final capability = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(cpuCores: 8),
      );

      expect(capability.tier, ReceiptCapabilityTier.medium);
    },
  );

  test('multi-photo receipts beyond the device tier require review', () {
    final attachments = [
      for (var index = 0; index < 5; index++)
        receiptAttachmentFixture(
          kind: ReceiptAttachmentKind.photo,
          byteSize: 800 * 1024,
          idSuffix: '$index',
        ),
    ];

    final decision = const ReceiptAssistancePolicy(
      device: ReceiptDeviceCapability.olderPhone(),
    ).decideForAttachments(attachments);

    expect(decision.mode, ReceiptAssistanceMode.localReadWithReview);
    expect(decision.warnings.single, contains('5 photos'));
    expect(decision.warnings.single, contains('tuned for 4'));
  });

  test('camera runtime profile dials back heavy capture on older phones', () {
    final profile = const ReceiptDeviceCapability.olderPhone()
        .cameraRuntimeProfileFor(
          guidanceRequested: true,
          startAssistedRequested: true,
          autoCaptureRequested: true,
          longReceiptTipsRequested: true,
        );

    expect(profile.tier, ReceiptCapabilityTier.light);
    expect(profile.liveGuidanceEnabled, isTrue);
    expect(profile.startAssistedEnabled, isFalse);
    expect(profile.autoCaptureEnabled, isFalse);
    expect(profile.longReceiptTipsEnabled, isTrue);
    expect(profile.modeLabel, 'Manual capture with guidance');
    expect(profile.summaryLabel, contains('Manual capture with guidance'));
    expect(profile.notesLabel, contains('manual capture first'));
    expect(profile.notesLabel, contains('tap the shutter when ready'));
  });

  test(
    'camera runtime profile allows guided auto capture on capable phones',
    () {
      final profile = const ReceiptDeviceCapability.highCapacity()
          .cameraRuntimeProfileFor(
            guidanceRequested: true,
            startAssistedRequested: true,
            autoCaptureRequested: true,
            longReceiptTipsRequested: true,
          );

      expect(profile.tier, ReceiptCapabilityTier.heavyweight);
      expect(profile.liveGuidanceEnabled, isTrue);
      expect(profile.startAssistedEnabled, isTrue);
      expect(profile.autoCaptureEnabled, isTrue);
      expect(profile.modeLabel, 'Guided auto capture');
      expect(profile.notesLabel, contains('safest receipt camera behavior'));
    },
  );

  test('photo quality metadata forces local read with review', () {
    const poorQuality = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 12,
      brightness: 40,
      contrast: 34,
      cropScore: .7,
      textBandScore: 12,
      isLikelyReadable: false,
    );

    final decision = const ReceiptAssistancePolicy().decideForAttachment(
      receiptAttachmentFixture(
        kind: ReceiptAttachmentKind.photo,
      ).withPhotoQuality(poorQuality),
    );

    expect(decision.mode, ReceiptAssistanceMode.localReadWithReview);
    expect(decision.shouldReadLocally, isTrue);
    expect(decision.reason, contains('quality needs review'));
    expect(decision.warnings.join(' '), contains('too dark'));
  });

  test('unsafe PDF is never opened for app-assisted reading', () {
    final decision = const ReceiptAssistancePolicy().decideForAttachment(
      receiptAttachmentFixture(
        kind: ReceiptAttachmentKind.pdf,
        riskFlags: [ReceiptPdfInspector.embeddedJavaScriptRiskFlag],
      ),
    );

    expect(decision.mode, ReceiptAssistanceMode.proofOnly);
    expect(decision.shouldReadLocally, isFalse);
    expect(decision.warnings, contains('embedded JavaScript'));
  });

  test('cloud candidate requires explicit availability and safe limits', () {
    final decision =
        const ReceiptAssistancePolicy(
          device: ReceiptDeviceCapability(
            profileName: 'Small test device',
            tier: ReceiptCapabilityTier.light,
            parserDepth: ReceiptParserDepth.proofTotalsOnly,
            maxLocalPdfBytes: 4 * 1024 * 1024,
            maxLocalPdfPages: 6,
            maxLocalPhotoBytes: 4 * 1024 * 1024,
            maxLocalPhotoCount: 2,
            cameraResolutionTier: ReceiptCameraResolutionTier.medium,
            assistedCameraShotCount: 2,
            bestShotCandidateCount: 1,
            liveAnalysisGapMs: 760,
            readyHoldMs: 900,
            maxLocalCatalogMatches: 100,
            maxLocalInventoryCacheItems: 500,
            enableSkuDetection: false,
            enableTradeClassification: false,
            enableReturnDetection: true,
            enableAdvancedConfidenceScoring: false,
            recommendedDataSaverLevel: ReceiptDataSaverLevel.strong,
          ),
          cloudAssistedAvailable: true,
        ).decideForAttachment(
          receiptAttachmentFixture(
            kind: ReceiptAttachmentKind.pdf,
            byteSize: 7 * 1024 * 1024,
            pageCount: 8,
          ),
        );

    expect(decision.mode, ReceiptAssistanceMode.cloudCandidate);
    expect(decision.shouldReadLocally, isFalse);
    expect(decision.warnings.single, contains('explicit'));
  });

  test('multiple attachments can use any local-readable receipt proof', () {
    final decision =
        const ReceiptAssistancePolicy(
          device: ReceiptDeviceCapability.olderPhone(),
        ).decideForAttachments([
          receiptAttachmentFixture(
            kind: ReceiptAttachmentKind.pdf,
            byteSize: 14 * 1024 * 1024,
            pageCount: 20,
          ),
          receiptAttachmentFixture(
            kind: ReceiptAttachmentKind.photo,
            byteSize: 2 * 1024 * 1024,
          ),
        ]);

    expect(decision.mode, ReceiptAssistanceMode.localRead);
    expect(decision.shouldReadLocally, isTrue);
  });

  test('capability diagnostics labels expose tier limits clearly', () {
    const light = ReceiptDeviceCapability.olderPhone();
    const heavy = ReceiptDeviceCapability.highCapacity();

    expect(light.localPhotoLimitLabel, '4 receipt photos');
    expect(light.localPdfLimitLabel, '12 PDF pages');
    expect(light.stitchLimits.maxOutputPixels, 9000000);
    expect(light.stitchLimits.maxOutputHeight, 14000);
    expect(light.stitchLimits.label, contains('9.0 MP'));
    expect(light.cameraCaptureLabel, 'Medium camera, 2 assisted shots');
    expect(light.localCatalogLimitLabel, '250 local catalog matches');
    expect(light.localInventoryCacheLabel, '1000 inventory cache items');
    expect(light.enabledFeaturesLabel, 'Return/discount detection');

    expect(heavy.localPhotoLimitLabel, '12 receipt photos');
    expect(heavy.localPdfLimitLabel, '50 PDF pages');
    expect(heavy.stitchLimits.maxOutputPixels, 18000000);
    expect(heavy.stitchLimits.maxOutputHeight, 24000);
    expect(heavy.stitchLimits.label, contains('18.0 MP'));
    expect(heavy.cameraCaptureLabel, 'Receipt High camera, 5 assisted shots');
    expect(heavy.localCatalogLimitLabel, '8000 local catalog matches');
    expect(heavy.localInventoryCacheLabel, '25000 inventory cache items');
    expect(heavy.enabledFeaturesLabel, contains('SKU detection'));
    expect(heavy.enabledFeaturesLabel, contains('Trade classification'));
    expect(heavy.enabledFeaturesLabel, contains('Advanced confidence scoring'));
  });
}
