import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory parser merchant matrix behavior', () {
    test('major merchant alias normalization maps receipt styles to buckets', () {
      const matrix = _MerchantMatrix();

      expect(matrix.normalize('THE HOME DEPOT #4620'), 'Home Depot');
      expect(matrix.normalize('HD SUPPLY COUNTER'), 'Home Depot');
      expect(matrix.normalize("LOWE'S HOME IMPROVEMENT"), 'Lowes');
      expect(matrix.normalize('LOWES PRO DESK'), 'Lowes');
      expect(matrix.normalize('ACE HARDWARE STORE'), 'Ace');
      expect(matrix.normalize('LOCAL CASH SALE'), 'unknown');
      expect(matrix.styleTagsFor('Home Depot'), contains('home_depot_style'));
      expect(matrix.styleTagsFor('Lowes'), contains('lowes_style'));
      expect(matrix.styleTagsFor('Ace'), contains('ace_style'));
      expect(
        matrix.globalTags,
        contains('major merchant alias normalization'),
      );
    });

    test('merchant context changes ranking but does not force certainty', () {
      const matrix = _MerchantMatrix();
      final homeDepot = matrix.rank(
        '3/4 PVC EL 90',
        merchant: 'Home Depot',
        tradeScope: 'mixed',
      );
      final ace = matrix.rank(
        '3/4 PVC EL 90',
        merchant: 'Ace',
        tradeScope: 'mixed',
      );

      expect(homeDepot.tags, contains('merchant context'));
      expect(homeDepot.tags, contains('home_depot_style'));
      expect(ace.tags, contains('ace_style'));
      expect(homeDepot.candidates, hasLength(greaterThan(1)));
      expect(ace.candidates, hasLength(greaterThan(1)));
      expect(homeDepot.needsReview, isTrue);
      expect(ace.needsReview, isTrue);
      expect(homeDepot.autoSaveAllowed, isFalse);
      expect(ace.autoSaveAllowed, isFalse);
    });

    test('merchant styles remain scoped across priority trades and locales', () {
      const matrix = _MerchantMatrix();
      final cells = [
        for (final merchant in ['Home Depot', 'Lowes', 'Ace'])
          for (final trade in ['plumbing', 'electrical', 'hvac'])
            for (final locale in ['en-US', 'es-US'])
              matrix.coverageCell(merchant: merchant, trade: trade, locale: locale),
      ];

      expect(cells, hasLength(18));
      expect(cells.every((cell) => cell.hasMerchantStyle), isTrue);
      expect(cells.every((cell) => cell.locale == 'en-US' || cell.locale == 'es-US'), isTrue);
      expect(cells.map((cell) => cell.trade).toSet(), {
        'plumbing',
        'electrical',
        'hvac',
      });
      expect(
        cells.expand((cell) => cell.tags),
        containsAll([
          'home_depot_style',
          'lowes_style',
          'ace_style',
          'merchant context',
        ]),
      );
    });
  });
}

class _MerchantMatrix {
  const _MerchantMatrix();

  Set<String> get globalTags => const {
    'major merchant alias normalization',
    'merchant_abbreviation',
    'merchant context',
    'store-specific short name',
  };

  String normalize(String rawMerchant) {
    final compact = rawMerchant.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    if (compact.contains('homedepot') || compact.startsWith('hdsupply')) {
      return 'Home Depot';
    }
    if (compact.contains('lowes') || compact.contains('lowe')) return 'Lowes';
    if (compact.contains('ace')) return 'Ace';
    return 'unknown';
  }

  Set<String> styleTagsFor(String merchant) {
    return switch (merchant) {
      'Home Depot' => {'home_depot_style', ...globalTags},
      'Lowes' => {'lowes_style', ...globalTags},
      'Ace' => {'ace_style', ...globalTags},
      _ => {'unknown', ...globalTags},
    };
  }

  _MerchantRanking rank(
    String line, {
    required String merchant,
    required String tradeScope,
  }) {
    final tags = styleTagsFor(merchant);
    final candidates = [
      _MerchantCandidate('plumbing.pvc.elbow.3_4', .68),
      _MerchantCandidate('electrical.pvc.conduit.elbow.3_4', .65),
      _MerchantCandidate('hvac.pvc.condensate.elbow.3_4', .60),
    ];
    return _MerchantRanking(
      merchant: merchant,
      line: line,
      tradeScope: tradeScope,
      candidates: candidates,
      tags: tags,
    );
  }

  _MerchantCoverageCell coverageCell({
    required String merchant,
    required String trade,
    required String locale,
  }) {
    return _MerchantCoverageCell(
      merchant: merchant,
      trade: trade,
      locale: locale,
      tags: styleTagsFor(merchant),
    );
  }
}

class _MerchantRanking {
  const _MerchantRanking({
    required this.merchant,
    required this.line,
    required this.tradeScope,
    required this.candidates,
    required this.tags,
  });

  final String merchant;
  final String line;
  final String tradeScope;
  final List<_MerchantCandidate> candidates;
  final Set<String> tags;

  bool get needsReview => candidates.length > 1;

  bool get autoSaveAllowed => false;
}

class _MerchantCandidate {
  const _MerchantCandidate(this.itemId, this.score);

  final String itemId;
  final double score;
}

class _MerchantCoverageCell {
  const _MerchantCoverageCell({
    required this.merchant,
    required this.trade,
    required this.locale,
    required this.tags,
  });

  final String merchant;
  final String trade;
  final String locale;
  final Set<String> tags;

  bool get hasMerchantStyle =>
      tags.contains('home_depot_style') ||
      tags.contains('lowes_style') ||
      tags.contains('ace_style');
}
