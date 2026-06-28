import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';

void main() {
  test('imported receipt text uses local reading immediately', () {
    final decision = const ReceiptAssistancePolicy().decideForAttachment(
      _attachment(
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
          _attachment(
            kind: ReceiptAttachmentKind.pdf,
            byteSize: 12 * 1024 * 1024,
            pageCount: 18,
          ),
        );

    expect(decision.mode, ReceiptAssistanceMode.proofOnly);
    expect(decision.reason, contains('Older phone'));
  });

  test(
    'automatic capability assessment picks a light tier for constrained phones',
    () {
      final capability = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 3900,
          cpuCores: 4,
          androidSdk: 28,
          freeStorageMb: 900,
        ),
      );

      expect(capability.tier, ReceiptCapabilityTier.light);
      expect(capability.parserDepth, ReceiptParserDepth.proofTotalsOnly);
      expect(capability.maxLocalPhotoCount, 4);
      expect(
        capability.cameraResolutionTier,
        ReceiptCameraResolutionTier.medium,
      );
      expect(capability.assistedCameraShotCount, 2);
      expect(capability.liveAnalysisGapMs, greaterThan(700));
      expect(capability.maxLocalCatalogMatches, lessThan(500));
      expect(capability.enableAdvancedConfidenceScoring, isFalse);
      expect(
        capability.recommendedDataSaverLevel,
        ReceiptDataSaverLevel.strong,
      );
    },
  );

  test(
    'automatic capability assessment picks a medium tier for midrange phones',
    () {
      final capability = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 6144,
          cpuCores: 6,
          androidSdk: 31,
          freeStorageMb: 2400,
        ),
      );

      expect(capability.tier, ReceiptCapabilityTier.medium);
      expect(capability.parserDepth, ReceiptParserDepth.lineItems);
      expect(capability.cameraResolutionTier, ReceiptCameraResolutionTier.high);
      expect(capability.assistedCameraShotCount, 4);
      expect(capability.enableTradeClassification, isTrue);
      expect(capability.maxLocalInventoryCacheItems, 5000);
      expect(
        capability.recommendedDataSaverLevel,
        ReceiptDataSaverLevel.balanced,
      );
    },
  );

  test(
    'automatic capability assessment picks a heavyweight tier for capable phones',
    () {
      final capability = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 12288,
          cpuCores: 8,
          androidSdk: 35,
          androidPerformanceClass: 34,
          freeStorageMb: 12000,
          hasOnDeviceAcceleration: true,
        ),
      );

      expect(capability.tier, ReceiptCapabilityTier.heavyweight);
      expect(capability.parserDepth, ReceiptParserDepth.inventoryMatching);
      expect(capability.cameraResolutionTier, ReceiptCameraResolutionTier.max);
      expect(capability.assistedCameraShotCount, 5);
      expect(capability.readyHoldMs, lessThan(650));
      expect(capability.enableSkuDetection, isTrue);
      expect(capability.maxLocalCatalogMatches, greaterThan(5000));
      expect(
        capability.recommendedDataSaverLevel,
        ReceiptDataSaverLevel.balanced,
      );
    },
  );

  test('manual performance modes override automatic tier selection safely', () {
    const strongHardware = ReceiptHardwareProfile(
      availableRamMb: 12288,
      cpuCores: 8,
      androidPerformanceClass: 34,
      hasOnDeviceAcceleration: true,
    );
    const constrainedHardware = ReceiptHardwareProfile(
      availableRamMb: 3900,
      cpuCores: 4,
      androidSdk: 28,
    );

    expect(
      ReceiptDeviceCapability.fromHardware(
        hardware: strongHardware,
        mode: ReceiptPerformanceMode.batterySaver,
      ).tier,
      ReceiptCapabilityTier.light,
    );
    expect(
      ReceiptDeviceCapability.fromHardware(
        hardware: strongHardware,
        mode: ReceiptPerformanceMode.balanced,
      ).tier,
      ReceiptCapabilityTier.medium,
    );
    expect(
      ReceiptDeviceCapability.fromHardware(
        hardware: constrainedHardware,
        mode: ReceiptPerformanceMode.maximumPerformance,
      ).tier,
      ReceiptCapabilityTier.light,
    );
  });

  test('low storage tightens automatic receipt photo space saving', () {
    final capability = ReceiptDeviceCapability.fromHardware(
      hardware: const ReceiptHardwareProfile(
        availableRamMb: 12288,
        cpuCores: 8,
        androidPerformanceClass: 34,
        freeStorageMb: 320,
        hasOnDeviceAcceleration: true,
      ),
      mode: ReceiptPerformanceMode.maximumPerformance,
    );

    expect(capability.tier, ReceiptCapabilityTier.light);
    expect(capability.recommendedDataSaverLevel, ReceiptDataSaverLevel.maximum);
  });

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
        _attachment(
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
      _attachment(
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
      _attachment(
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
          _attachment(
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
          _attachment(
            kind: ReceiptAttachmentKind.pdf,
            byteSize: 14 * 1024 * 1024,
            pageCount: 20,
          ),
          _attachment(
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

  test('hardware diagnostics labels unknown and concrete signals clearly', () {
    const unknown = ReceiptHardwareProfile();
    const detected = ReceiptHardwareProfile(
      platformName: 'android',
      platformVersion: 'Android 15',
      availableRamMb: 12288,
      cpuCores: 8,
      androidSdk: 35,
      androidPerformanceClass: 34,
      freeStorageMb: 6144,
      lowPowerMode: true,
      hasOnDeviceAcceleration: true,
      cameraPermissionGranted: true,
      cameraCount: 4,
      hasRearCamera: true,
      maxStillWidth: 4032,
      maxStillHeight: 3024,
    );

    expect(unknown.platformLabel, 'Unknown');
    expect(unknown.availableRamLabel, 'Unknown');
    expect(unknown.androidSdkLabel, 'Unavailable');
    expect(unknown.accelerationLabel, 'Not detected');

    expect(detected.platformLabel, 'android');
    expect(detected.platformVersionLabel, 'Android 15');
    expect(detected.availableRamLabel, '12.0 GB');
    expect(detected.cpuCoresLabel, '8 cores');
    expect(detected.androidSdkLabel, 'Android SDK 35');
    expect(detected.androidPerformanceClassLabel, '34');
    expect(detected.freeStorageLabel, '6.0 GB');
    expect(detected.lowPowerModeLabel, 'On');
    expect(detected.accelerationLabel, 'Detected');
    expect(detected.maxStillMegapixels, 12);
    expect(detected.cameraLabel, '4 cameras detected');
  });

  test(
    'camera defaults scale by capability without exposing raw hardware UI',
    () {
      const light = ReceiptDeviceCapability.olderPhone();
      const standard = ReceiptDeviceCapability.standard();
      const heavy = ReceiptDeviceCapability.highCapacity();

      expect(light.cameraResolutionTier, ReceiptCameraResolutionTier.medium);
      expect(light.assistedCameraShotCount, 2);
      expect(light.bestShotCandidateCount, 1);
      expect(light.liveAnalysisGapMs, greaterThan(700));

      expect(standard.cameraResolutionTier, ReceiptCameraResolutionTier.high);
      expect(standard.assistedCameraShotCount, 4);
      expect(standard.bestShotCandidateCount, 3);

      expect(heavy.cameraResolutionTier, ReceiptCameraResolutionTier.max);
      expect(heavy.assistedCameraShotCount, 5);
      expect(heavy.bestShotCandidateCount, 5);
      expect(heavy.liveAnalysisGapMs, lessThan(standard.liveAnalysisGapMs));
      expect(
        light.stitchLimits.maxOutputPixels,
        lessThan(standard.stitchLimits.maxOutputPixels),
      );
      expect(
        standard.stitchLimits.maxOutputPixels,
        lessThan(heavy.stitchLimits.maxOutputPixels),
      );
    },
  );

  test('large photos stay readable but force review on older phones', () {
    final decision =
        const ReceiptAssistancePolicy(
          device: ReceiptDeviceCapability.olderPhone(),
        ).decideForAttachment(
          _attachment(
            kind: ReceiptAttachmentKind.photo,
            byteSize: 9 * 1024 * 1024,
          ),
        );

    expect(decision.mode, ReceiptAssistanceMode.localReadWithReview);
    expect(decision.shouldReadLocally, isTrue);
    expect(decision.reason, contains('large for Older phone'));
    expect(decision.warnings.join(' '), contains('slower on older phones'));
  });
}

ReceiptAttachmentRecord _attachment({
  required ReceiptAttachmentKind kind,
  String importedText = '',
  int? byteSize,
  int? pageCount,
  List<String> riskFlags = const [],
  String idSuffix = '',
}) {
  return ReceiptAttachmentRecord(
    id: 'att-${kind.name}$idSuffix',
    path:
        kind == ReceiptAttachmentKind.photo || kind == ReceiptAttachmentKind.pdf
        ? '/tmp/receipt'
        : '',
    kind: kind,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 22),
    importedText: importedText,
    byteSize: byteSize,
    pageCount: pageCount,
    pageCountStatus: pageCount == null
        ? ReceiptPdfPageCountStatus.unknown
        : ReceiptPdfPageCountStatus.estimated,
    validationStatus: ReceiptPdfValidationStatus.valid,
    riskFlags: riskFlags,
  );
}
