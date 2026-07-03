import 'maintainiac_qa_environment.dart';

enum MaintainiacSyncScenario {
  localWrite,
  dirtyMarker,
  onlineSync,
  failedSync,
  retryBackoff,
  manualSync,
  scheduledSync,
  wifiOnly,
  cellularAllowed,
  roamingBlocked,
  batterySaverPause,
  restartBeforeSync,
  restartAfterPartialSync,
  sameFieldConflict,
  differentFieldMerge,
  pastDayEditVersioning,
  localWinsDaytimePolicy,
  firestoreMirrorPayload,
}

enum MaintainiacSecurityScenario {
  userIsolation,
  profileIsolation,
  vehicleIsolation,
  companyEmployeeScoping,
  receiptOwnership,
  exportOwnership,
  noVinStorage,
  noPlateStorage,
  noPassengerData,
  noPatientData,
  noSecretsInRepo,
  permissionDeniedFlow,
  deletedFileCleanup,
  noCrossAccountBleed,
}

enum MaintainiacFinancialScenario {
  expenseTotals,
  businessPersonalTotals,
  dailyRecapMath,
  extendedRecapMath,
  invoiceTotals,
  estimateTotals,
  taxes,
  discounts,
  refunds,
  negativeAdjustments,
  inventoryConsumptionCosts,
  decimalSafeMoney,
  roundingConsistency,
}

enum MaintainiacPerformanceScenario {
  catalog100k,
  largeInventoryMovementHistory,
  largeReceiptFixtureSet,
  multiYearDayLogs,
  largeExports,
  startupLoad,
  searchIndexPerformance,
  syncPayloadGeneration,
  importValidation,
  memorySafety,
}

enum MaintainiacRegressionScenario {
  masterCoverageMatrix,
  goldenRegressionCorpus,
  differentialRegression,
  mutationTesting,
  propertyFuzzTesting,
  focusedRerunCommands,
  releaseSignoff,
}

enum MaintainiacPersistenceChaosScenario {
  appKilledMidWrite,
  appKilledMidReview,
  lowStorage,
  localDatabaseCorruption,
  interruptedImport,
  interruptedExport,
  interruptedPackDownload,
  duplicateInstall,
  duplicateReceiptImport,
  offlineWrite,
  staleMirror,
  syncRetry,
  rollbackToLastKnownGood,
}

enum MaintainiacReleaseEvidenceScenario {
  coverageMatrixStatus,
  fixtureSource,
  expectedBehavior,
  focusedRerunCommand,
  lastVerifiedDate,
  releaseOwner,
  nonApplicableReason,
}

enum MaintainiacAccessibilityLocalizationScenario {
  screenReaderLabels,
  colorContrast,
  touchTargetSize,
  keyboardNavigation,
  reduceMotion,
  textScaling,
  englishLocale,
  spanishLocale,
  frenchLocale,
  metricUnits,
  imperialUnits,
  translatedReviewReasons,
}

enum MaintainiacCostQuotaScenario {
  noLiveFirebaseInLocalQa,
  batchedFirestoreReads,
  batchedFirestoreWrites,
  cloudAssistOptIn,
  offlineCacheHit,
  packDownloadResume,
  quotaBudgetPerRun,
  noRawReceiptTelemetry,
  emulatorBeforeLive,
  adminReportReadLimit,
}

class MaintainiacQualityGateMatrix {
  const MaintainiacQualityGateMatrix({
    required this.sync,
    required this.security,
    required this.financial,
    required this.performance,
    required this.regression,
    required this.persistenceChaos,
    required this.releaseEvidence,
    required this.accessibilityLocalization,
    required this.costQuota,
  });

  factory MaintainiacQualityGateMatrix.releaseOne() {
    return MaintainiacQualityGateMatrix(
      sync: MaintainiacSyncScenario.values.toSet(),
      security: MaintainiacSecurityScenario.values.toSet(),
      financial: MaintainiacFinancialScenario.values.toSet(),
      performance: MaintainiacPerformanceScenario.values.toSet(),
      regression: MaintainiacRegressionScenario.values.toSet(),
      persistenceChaos: MaintainiacPersistenceChaosScenario.values.toSet(),
      releaseEvidence: MaintainiacReleaseEvidenceScenario.values.toSet(),
      accessibilityLocalization: MaintainiacAccessibilityLocalizationScenario
          .values
          .toSet(),
      costQuota: MaintainiacCostQuotaScenario.values.toSet(),
    );
  }

  final Set<MaintainiacSyncScenario> sync;
  final Set<MaintainiacSecurityScenario> security;
  final Set<MaintainiacFinancialScenario> financial;
  final Set<MaintainiacPerformanceScenario> performance;
  final Set<MaintainiacRegressionScenario> regression;
  final Set<MaintainiacPersistenceChaosScenario> persistenceChaos;
  final Set<MaintainiacReleaseEvidenceScenario> releaseEvidence;
  final Set<MaintainiacAccessibilityLocalizationScenario>
  accessibilityLocalization;
  final Set<MaintainiacCostQuotaScenario> costQuota;

  List<String> validate() {
    final failures = <String>[];
    _requireAll(
      failures,
      'sync',
      MaintainiacSyncScenario.values.map((value) => value.name).toSet(),
      sync.map((value) => value.name).toSet(),
    );
    _requireAll(
      failures,
      'security',
      MaintainiacSecurityScenario.values.map((value) => value.name).toSet(),
      security.map((value) => value.name).toSet(),
    );
    _requireAll(
      failures,
      'financial',
      MaintainiacFinancialScenario.values.map((value) => value.name).toSet(),
      financial.map((value) => value.name).toSet(),
    );
    _requireAll(
      failures,
      'performance',
      MaintainiacPerformanceScenario.values.map((value) => value.name).toSet(),
      performance.map((value) => value.name).toSet(),
    );
    _requireAll(
      failures,
      'regression',
      MaintainiacRegressionScenario.values.map((value) => value.name).toSet(),
      regression.map((value) => value.name).toSet(),
    );
    _requireAll(
      failures,
      'persistenceChaos',
      MaintainiacPersistenceChaosScenario.values
          .map((value) => value.name)
          .toSet(),
      persistenceChaos.map((value) => value.name).toSet(),
    );
    _requireAll(
      failures,
      'releaseEvidence',
      MaintainiacReleaseEvidenceScenario.values
          .map((value) => value.name)
          .toSet(),
      releaseEvidence.map((value) => value.name).toSet(),
    );
    _requireAll(
      failures,
      'accessibilityLocalization',
      MaintainiacAccessibilityLocalizationScenario.values
          .map((value) => value.name)
          .toSet(),
      accessibilityLocalization.map((value) => value.name).toSet(),
    );
    _requireAll(
      failures,
      'costQuota',
      MaintainiacCostQuotaScenario.values.map((value) => value.name).toSet(),
      costQuota.map((value) => value.name).toSet(),
    );
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'sync': sync.map((value) => value.name).toList()..sort(),
      'security': security.map((value) => value.name).toList()..sort(),
      'financial': financial.map((value) => value.name).toList()..sort(),
      'performance': performance.map((value) => value.name).toList()..sort(),
      'regression': regression.map((value) => value.name).toList()..sort(),
      'persistenceChaos': persistenceChaos.map((value) => value.name).toList()
        ..sort(),
      'releaseEvidence': releaseEvidence.map((value) => value.name).toList()
        ..sort(),
      'accessibilityLocalization':
          accessibilityLocalization.map((value) => value.name).toList()..sort(),
      'costQuota': costQuota.map((value) => value.name).toList()..sort(),
    };
  }
}

class MaintainiacSyncPolicyProbe {
  const MaintainiacSyncPolicyProbe();

  bool shouldSync({
    required MaintainiacNetworkState network,
    required bool wifiOnly,
    required bool cellularAllowed,
    required bool batterySaver,
  }) {
    if (batterySaver) return false;
    return switch (network) {
      MaintainiacNetworkState.offline => false,
      MaintainiacNetworkState.blocked => false,
      MaintainiacNetworkState.roaming => false,
      MaintainiacNetworkState.wifi => true,
      MaintainiacNetworkState.cellular => !wifiOnly && cellularAllowed,
    };
  }
}

class MaintainiacMoneyProbe {
  const MaintainiacMoneyProbe();

  int lineTotalCents({
    required int unitCents,
    required int quantity,
    int taxCents = 0,
    int discountCents = 0,
    int refundCents = 0,
  }) {
    return unitCents * quantity + taxCents - discountCents - refundCents;
  }

  int allocateTaxPerUnit({required int taxCents, required int quantity}) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    }
    return (taxCents / quantity).round();
  }
}

class MaintainiacPrivacyProbe {
  const MaintainiacPrivacyProbe();

  static final _forbidden = [
    RegExp(r'\b[A-HJ-NPR-Z0-9]{17}\b', caseSensitive: false),
    RegExp(r'\b[A-Z]{1,3}[- ]?\d{3,5}\b'),
    RegExp(
      r'\b(patient|passenger|ssn|social security|tax id)\b',
      caseSensitive: false,
    ),
    RegExp(r'\b(?:\d[ -]*?){13,19}\b'),
  ];

  List<String> forbiddenMatches(String text) {
    final matches = <String>[];
    for (final pattern in _forbidden) {
      if (pattern.hasMatch(text)) {
        matches.add(pattern.pattern);
      }
    }
    return matches;
  }
}

void _requireAll(
  List<String> failures,
  String area,
  Set<String> required,
  Set<String> present,
) {
  final missing = required.difference(present);
  if (missing.isNotEmpty) {
    failures.add('$area missing ${missing.toList()..sort()}');
  }
}
