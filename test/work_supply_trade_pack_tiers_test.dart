import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('plumbing trade pack offers popularity-based install tiers', () {
    final options = buildWorkSupplyTradePackOptions('Plumbing');

    expect(
      options.map((option) => option.tier),
      containsAll([
        WorkSupplyTradePackTier.core,
        WorkSupplyTradePackTier.expanded,
        WorkSupplyTradePackTier.professional,
        WorkSupplyTradePackTier.full,
      ]),
    );
    final core = options.firstWhere(
      (option) => option.tier == WorkSupplyTradePackTier.core,
    );
    final standard = options.firstWhere(
      (option) => option.tier == WorkSupplyTradePackTier.expanded,
    );
    final professional = options.firstWhere(
      (option) => option.tier == WorkSupplyTradePackTier.professional,
    );
    final full = options.firstWhere(
      (option) => option.tier == WorkSupplyTradePackTier.full,
    );

    expect(core.itemCount, greaterThan(100));
    expect(standard.itemCount, greaterThan(core.itemCount));
    expect(professional.itemCount, greaterThan(standard.itemCount));
    expect(full.itemCount, greaterThan(professional.itemCount));
    expect(
      full.estimatedCompressedBytes,
      greaterThan(core.estimatedCompressedBytes),
    );
    expect(full.storagePath, endsWith('/complete.json.gz'));
  });

  test('trade pack option manifest stays Firestore-lightweight', () {
    final plumbing = buildWorkSupplyTradePackOptions('Plumbing');
    final manifestOptions = [
      for (final option in plumbing) option.toManifestMap(),
    ];

    expect(manifestOptions, isNotEmpty);
    expect(
      manifestOptions.every((option) => option.containsKey('items') == false),
      isTrue,
    );
    expect(
      manifestOptions.every(
        (option) => option['deliveryMode'] == 'storage_gzip_chunk',
      ),
      isTrue,
    );
    expect(
      manifestOptions.every(
        (option) => option['storagePath'].toString().endsWith('.json.gz'),
      ),
      isTrue,
    );
  });

  test('trade pack option keys are stable for local install state', () {
    final plumbing = buildWorkSupplyTradePackOptions('Plumbing');
    final keys = plumbing.map(workSupplyTradePackOptionKey).toSet();

    expect(keys, hasLength(plumbing.length));
    expect(keys, contains('plumbing:core'));
    expect(keys, contains('plumbing:standard'));
    expect(keys, contains('plumbing:professional'));
    expect(keys, contains('plumbing:complete'));
  });

  test('trade pack trade keys match option keys for names with symbols', () {
    final trade = 'Tools & Safety';
    final options = buildWorkSupplyTradePackOptions(trade);
    final tradeKey = workSupplyTradePackTradeKey(trade);

    expect(tradeKey, 'tools-and-safety');
    expect(
      options.every(
        (option) =>
            workSupplyTradePackOptionKey(option).startsWith('$tradeKey:'),
      ),
      isTrue,
    );
  });

  test('trade pack summaries expose selected trades for settings UI', () {
    final summaries = buildWorkSupplyTradePackSummaries();
    final plumbing = summaries.firstWhere(
      (summary) => summary.tradeName == 'Plumbing',
    );

    expect(summaries.length, greaterThan(3));
    expect(plumbing.itemCount, greaterThan(1000));
    expect(plumbing.optionCount, 4);
    expect(plumbing.estimatedCompressedBytes, greaterThan(0));
  });
}
