import 'work_supply_catalog_audit.dart';

const workSupplyTradePackCoreTargetItemCount = 5000;
const workSupplyTradePackProTargetItemCount = 15000;
const workSupplyTradePackGeneratedItemsPerPass = 1500;
const workSupplyTradePackPolishPassesPerWeakTrade = 2;
const workSupplyActiveTradePackName = 'Plumbing';

class WorkSupplyTradePackCompletionAudit {
  const WorkSupplyTradePackCompletionAudit({
    required this.currentItemCount,
    required this.coreTargetItemCount,
    required this.proTargetItemCount,
    required this.coreItemsRemaining,
    required this.proItemsRemaining,
    required this.coreGenerationPasses,
    required this.proGenerationPasses,
    required this.parserPolishPasses,
    required this.targetedItemsRemaining,
    required this.targetedGenerationPasses,
    required this.tradeGaps,
  });

  final int currentItemCount;
  final int coreTargetItemCount;
  final int proTargetItemCount;
  final int coreItemsRemaining;
  final int proItemsRemaining;
  final int coreGenerationPasses;
  final int proGenerationPasses;
  final int parserPolishPasses;
  final int targetedItemsRemaining;
  final int targetedGenerationPasses;
  final List<WorkSupplyTradePackTradeGap> tradeGaps;

  int get likelyCoreCompletionPasses =>
      coreGenerationPasses + parserPolishPasses;
  int get likelyProCompletionPasses => proGenerationPasses + parserPolishPasses;
  int get likelyTargetedCompletionPasses =>
      targetedGenerationPasses + parserPolishPasses;

  List<WorkSupplyTradePackTradeGap> get weakestTrades {
    final sorted = [...tradeGaps]
      ..sort((a, b) {
        final core = b.coreItemsRemaining.compareTo(a.coreItemsRemaining);
        if (core != 0) return core;
        return a.tradeName.compareTo(b.tradeName);
      });
    return sorted.take(6).toList(growable: false);
  }
}

class WorkSupplyTradePackTradeGap {
  const WorkSupplyTradePackTradeGap({
    required this.tradeName,
    required this.currentItems,
    required this.currentReadiness,
    required this.priority,
    required this.targetItems,
    required this.coreItemsRemaining,
    required this.proItemsRemaining,
    required this.targetItemsRemaining,
    required this.needsParserPolish,
  });

  final String tradeName;
  final int currentItems;
  final String currentReadiness;
  final WorkSupplyTradePackPriority priority;
  final int targetItems;
  final int coreItemsRemaining;
  final int proItemsRemaining;
  final int targetItemsRemaining;
  final bool needsParserPolish;

  bool get isActiveTrade => tradeName == workSupplyActiveTradePackName;
  bool get isCoreReady => coreItemsRemaining == 0 && !needsParserPolish;
  bool get isProReady => proItemsRemaining == 0 && !needsParserPolish;
  bool get isTargetReady => targetItemsRemaining == 0 && !needsParserPolish;
  double get targetCompletionRatio =>
      targetItems <= 0 ? 1 : (currentItems / targetItems).clamp(0, 1);
  int get targetCompletionPercent => (targetCompletionRatio * 100).round();
}

enum WorkSupplyTradePackPriority {
  activeService,
  majorService,
  secondaryService,
  projectTrade,
  support,
}

WorkSupplyTradePackCompletionAudit auditWorkSupplyTradePackCompletion({
  WorkSupplyCatalogAuditSummary? catalogAudit,
}) {
  final audit = catalogAudit ?? auditWorkSupplyCatalog();
  final tradeGaps = [
    for (final trade in audit.tradeCoverage)
      WorkSupplyTradePackTradeGap(
        tradeName: trade.tradeName,
        currentItems: trade.itemCount,
        currentReadiness: trade.parserReadinessLabel,
        priority: _priorityForTrade(trade.tradeName),
        targetItems: _targetItemsForTrade(trade.tradeName),
        coreItemsRemaining: _remaining(
          workSupplyTradePackCoreTargetItemCount,
          trade.itemCount,
        ),
        proItemsRemaining: _remaining(
          workSupplyTradePackProTargetItemCount,
          trade.itemCount,
        ),
        targetItemsRemaining: _remaining(
          _targetItemsForTrade(trade.tradeName),
          trade.itemCount,
        ),
        needsParserPolish: trade.parserReadinessLabel != 'Strong',
      ),
  ];
  final coreRemaining = tradeGaps.fold<int>(
    0,
    (sum, gap) => sum + gap.coreItemsRemaining,
  );
  final proRemaining = tradeGaps.fold<int>(
    0,
    (sum, gap) => sum + gap.proItemsRemaining,
  );
  final polishPasses =
      tradeGaps.where((gap) => gap.needsParserPolish).length *
      workSupplyTradePackPolishPassesPerWeakTrade;
  final targetedRemaining = tradeGaps.fold<int>(
    0,
    (sum, gap) => sum + gap.targetItemsRemaining,
  );
  return WorkSupplyTradePackCompletionAudit(
    currentItemCount: audit.itemCount,
    coreTargetItemCount:
        audit.tradeCoverage.length * workSupplyTradePackCoreTargetItemCount,
    proTargetItemCount:
        audit.tradeCoverage.length * workSupplyTradePackProTargetItemCount,
    coreItemsRemaining: coreRemaining,
    proItemsRemaining: proRemaining,
    coreGenerationPasses: _passesFor(coreRemaining),
    proGenerationPasses: _passesFor(proRemaining),
    parserPolishPasses: polishPasses,
    targetedItemsRemaining: targetedRemaining,
    targetedGenerationPasses: _passesFor(targetedRemaining),
    tradeGaps: List.unmodifiable(tradeGaps),
  );
}

int _remaining(int target, int current) {
  final remaining = target - current;
  return remaining < 0 ? 0 : remaining;
}

int _passesFor(int remainingItems) {
  if (remainingItems <= 0) return 0;
  return (remainingItems / workSupplyTradePackGeneratedItemsPerPass).ceil();
}

WorkSupplyTradePackPriority _priorityForTrade(String tradeName) {
  return switch (tradeName) {
    workSupplyActiveTradePackName => WorkSupplyTradePackPriority.activeService,
    'Electrical' || 'HVAC' => WorkSupplyTradePackPriority.majorService,
    'Appliance Installation and Repair' ||
    'Garage Doors and Openers' ||
    'Well Septic and Water Treatment' ||
    'Windows and Doors' ||
    'Landscaping' => WorkSupplyTradePackPriority.secondaryService,
    'Tools and Safety' => WorkSupplyTradePackPriority.support,
    _ => WorkSupplyTradePackPriority.projectTrade,
  };
}

int _targetItemsForTrade(String tradeName) {
  return switch (_priorityForTrade(tradeName)) {
    WorkSupplyTradePackPriority.activeService => 15000,
    WorkSupplyTradePackPriority.majorService => 15000,
    WorkSupplyTradePackPriority.secondaryService => 5000,
    WorkSupplyTradePackPriority.projectTrade => 3000,
    WorkSupplyTradePackPriority.support => 2500,
  };
}
