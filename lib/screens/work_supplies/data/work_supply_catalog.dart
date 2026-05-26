import '../categories/carpentry/carpentry_supplies.dart';
import '../categories/electrical/electrical_supplies.dart';
import '../categories/hvac/hvac_supplies.dart';
import '../categories/plumbing/plumbing_supplies.dart';
import 'work_supply_models.dart';

const workSupplyTrades = <WorkSupplyTrade>[
  plumbingTrade,
  electricalTrade,
  hvacTrade,
  carpentryTrade,
];

List<WorkSupplyItem> get allWorkSupplyItems {
  return [
    for (final trade in workSupplyTrades)
      for (final group in trade.groups) ...[
        ...group.items,
        for (final material in group.materials) ...material.items,
      ],
  ];
}

List<WorkSupplyItem> searchWorkSupplies(String query) {
  final normalized = _normalize(query);
  if (normalized.isEmpty) return allWorkSupplyItems.take(12).toList();
  final scored = <({WorkSupplyItem item, int score})>[];
  for (final item in allWorkSupplyItems) {
    final haystack = [
      item.name,
      item.trade,
      item.group,
      item.unit,
      ...item.keywords,
      ...item.sizes,
    ].map(_normalize).join(' ');
    var score = 0;
    for (final token in normalized.split(' ')) {
      if (token.isEmpty) continue;
      if (haystack.contains(token)) score += token.length;
      if (_normalize(item.name).contains(token)) score += token.length * 2;
    }
    if (score > 0) scored.add((item: item, score: score));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));
  return [for (final match in scored.take(24)) match.item];
}

String _normalize(String input) {
  return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ').trim();
}
