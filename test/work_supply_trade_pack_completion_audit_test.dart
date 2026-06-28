import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_completion_audit.dart';

void main() {
  test('completion audit reports realistic remaining trade pack work', () {
    final audit = auditWorkSupplyTradePackCompletion();
    final gapByTrade = {for (final gap in audit.tradeGaps) gap.tradeName: gap};

    expect(audit.currentItemCount, greaterThanOrEqualTo(13000));
    expect(audit.targetedItemsRemaining, greaterThan(20000));
    expect(audit.likelyTargetedCompletionPasses, greaterThanOrEqualTo(15));
    expect(gapByTrade['Plumbing']!.coreItemsRemaining, 0);
    expect(gapByTrade['Plumbing']!.isActiveTrade, isTrue);
    expect(
      gapByTrade['Plumbing']!.priority,
      WorkSupplyTradePackPriority.activeService,
    );
    expect(gapByTrade['Plumbing']!.targetItems, 15000);
    expect(gapByTrade['Plumbing']!.targetCompletionPercent, greaterThan(70));
    expect(gapByTrade['Plumbing']!.targetItemsRemaining, greaterThan(0));
    expect(gapByTrade['Electrical']!.currentItems, greaterThanOrEqualTo(10000));
    expect(
      gapByTrade['Electrical']!.priority,
      WorkSupplyTradePackPriority.majorService,
    );
    expect(gapByTrade['Electrical']!.coreItemsRemaining, 0);
    expect(audit.weakestTrades.first.currentItems, greaterThanOrEqualTo(500));
  });
}
