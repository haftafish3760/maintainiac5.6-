part of 'work_supply_catalog.dart';

List<WorkSupplyItem> searchWorkSupplies(String query) {
  final tokens = query
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty && !_ignoredSearchToken(token))
      .toList();
  if (tokens.isEmpty) return workSupplyCatalogItems.take(25).toList();
  final scored = <({WorkSupplyItem item, int score})>[];
  for (final item in workSupplyCatalogItems) {
    final haystack = _normalizedSearchText(item.searchableText);
    var score = 0;
    for (final token in tokens) {
      if (_tokenAlternates(token).any(haystack.contains)) score++;
    }
    if (score == tokens.length) {
      if (_wantsHalfInch(tokens) && item.variant == '1/2 in') score += 10;
      if (_wantsThreeQuarter(tokens) && item.variant == '3/4 in') score += 10;
      if (_wantsQuarter(tokens) && item.variant == '1/4 in') score += 10;
      scored.add((item: item, score: score));
    }
  }
  scored.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final aExpanded = _isExpandedCatalogItem(a.item);
    final bExpanded = _isExpandedCatalogItem(b.item);
    if (aExpanded != bExpanded) return aExpanded ? 1 : -1;
    return a.item.name.compareTo(b.item.name);
  });
  return scored.map((entry) => entry.item).take(100).toList();
}

bool _isExpandedCatalogItem(WorkSupplyItem item) {
  return item.itemType.contains('Expanded');
}

bool _wantsHalfInch(List<String> tokens) {
  return tokens.contains('half') || tokens.contains('1/2');
}

bool _wantsThreeQuarter(List<String> tokens) {
  return tokens.contains('3/4') ||
      (tokens.contains('three') && tokens.contains('quarter'));
}

bool _wantsQuarter(List<String> tokens) {
  return tokens.contains('quarter') || tokens.contains('1/4');
}

bool _ignoredSearchToken(String token) {
  return switch (token) {
    'a' || 'an' || 'the' || 'by' || 'x' => true,
    _ => false,
  };
}

String _normalizedSearchText(String text) {
  return text
      .replaceAll(' in ', ' inch ')
      .replaceAll(' in', ' inch')
      .replaceAll(' x ', ' ')
      .replaceAll('1/2', '1/2 half')
      .replaceAll('1/4', '1/4 quarter')
      .replaceAll('3/4', '3/4 three-quarter three quarter')
      .replaceAll('1-1/4', '1-1/4 inch and a quarter')
      .replaceAll('1-1/2', '1-1/2 inch and a half')
      .replaceAll('90', '90 ninety')
      .replaceAll('45', '45 forty-five forty five');
}

List<String> _tokenAlternates(String token) {
  return switch (token) {
    'half' => const ['half', '1/2'],
    'quarter' => const ['quarter', '1/4'],
    'three-quarter' => const ['three-quarter', '3/4'],
    'three' => const ['three'],
    'inch' => const ['inch', 'in'],
    'in' => const ['inch', 'in'],
    'ninety' => const ['ninety', '90'],
    'forty-five' => const ['forty-five', '45'],
    _ => [token],
  };
}
