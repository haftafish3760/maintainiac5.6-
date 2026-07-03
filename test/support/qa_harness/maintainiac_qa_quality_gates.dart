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

class MaintainiacQualityGateMatrix {
  const MaintainiacQualityGateMatrix({
    required this.sync,
    required this.security,
    required this.financial,
    required this.performance,
  });

  factory MaintainiacQualityGateMatrix.releaseOne() {
    return MaintainiacQualityGateMatrix(
      sync: MaintainiacSyncScenario.values.toSet(),
      security: MaintainiacSecurityScenario.values.toSet(),
      financial: MaintainiacFinancialScenario.values.toSet(),
      performance: MaintainiacPerformanceScenario.values.toSet(),
    );
  }

  final Set<MaintainiacSyncScenario> sync;
  final Set<MaintainiacSecurityScenario> security;
  final Set<MaintainiacFinancialScenario> financial;
  final Set<MaintainiacPerformanceScenario> performance;

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
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'sync': sync.map((value) => value.name).toList()..sort(),
      'security': security.map((value) => value.name).toList()..sort(),
      'financial': financial.map((value) => value.name).toList()..sort(),
      'performance': performance.map((value) => value.name).toList()..sort(),
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
