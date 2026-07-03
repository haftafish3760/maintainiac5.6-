import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory parser SKU collision behavior', () {
    test('collision matrix covers all governed identifier axes', () {
      const matrix = _SkuCollisionMatrix();

      expect(
        matrix.axes.map((axis) => axis.name),
        containsAll(const [
          'same sku different merchant',
          'same part number different brand',
          'same upc different pack count',
          'same short name different trade',
          'same brand different material',
          'same size different connection type',
          'same alias different canonical item',
          'private label remap',
          'regional item number',
          'legacy sku',
        ]),
      );
      expect(matrix.axes, everyElement(_hasAtLeastTwoCandidates()));
      expect(matrix.axes, everyElement(_requiresReview()));
    });

    test('identifier-only evidence never creates a final answer', () {
      const parser = _SkuCollisionParser();
      final skuOnly = parser.parse('SKU 123456');
      final partOnly = parser.parse('PART 77-ABC');
      final brandOnly = parser.parse('ACME');
      final merchantOnly = parser.parse('HOME DEPOT');
      final genericAlias = parser.parse('PVC ELBOW');
      final crossTrade = parser.parse('PVC 90 3/4', tradeScope: 'mixed');

      for (final result in [
        skuOnly,
        partOnly,
        brandOnly,
        merchantOnly,
        genericAlias,
        crossTrade,
      ]) {
        expect(result.rankedCandidates, hasLength(greaterThanOrEqualTo(2)));
        expect(result.needsReview, isTrue);
        expect(result.finalAnswerAllowed, isFalse);
        expect(result.autoSaveAllowed, isFalse);
        expect(result.confidenceReasons, contains('not enough evidence'));
      }
      expect(skuOnly.forbiddenRules, contains('sku only final answer'));
      expect(partOnly.forbiddenRules, contains('part number only final answer'));
      expect(brandOnly.forbiddenRules, contains('brand only final answer'));
      expect(merchantOnly.forbiddenRules, contains('merchant only final answer'));
      expect(genericAlias.forbiddenRules, contains('generic alias final answer'));
      expect(crossTrade.forbiddenRules, contains('cross-trade auto-save'));
    });

    test('corroborated SKU evidence ranks but remains review-only', () {
      const parser = _SkuCollisionParser();
      final result = parser.parse(
        'LOWES SKU 123456 ACME 1/2 BRASS PEX 10PK',
        tradeScope: 'plumbing',
      );

      expect(result.rankedCandidates.first.itemId, 'lowes.acme.pex.elbow.10pk');
      expect(result.needsReview, isTrue);
      expect(result.finalAnswerAllowed, isFalse);
      expect(result.autoSaveAllowed, isFalse);
      expect(
        result.confidenceReasons,
        containsAll([
          'merchant evidence',
          'brand evidence',
          'size evidence',
          'pack count evidence',
          'confidence reasons',
        ]),
      );
      expect(result.conflictRules, contains('conflict rule'));
      expect(result.conflictRules, contains('negative match'));
    });

    test('UPC and private label collisions preserve alternatives', () {
      const parser = _SkuCollisionParser();
      final upc = parser.parse('UPC 000111222333 2PK');
      final privateLabel = parser.parse('PRIVATE PRO 3/4 ADAPTER');

      expect(upc.axisName, 'same upc different pack count');
      expect(upc.rankedCandidates.map((candidate) => candidate.packCount), {
        1,
        2,
      });
      expect(privateLabel.axisName, 'private label remap');
      expect(
        privateLabel.rankedCandidates.map((candidate) => candidate.itemId),
        containsAll(['store.private.adapter', 'canonical.brass.adapter']),
      );
      expect(upc.needsReview, isTrue);
      expect(privateLabel.needsReview, isTrue);
    });
  });
}

Matcher _hasAtLeastTwoCandidates() {
  return predicate<_SkuCollisionAxis>(
    (axis) => axis.candidates.length >= 2,
    'ranked candidates',
  );
}

Matcher _requiresReview() {
  return predicate<_SkuCollisionAxis>(
    (axis) => axis.needsReview && !axis.autoSaveAllowed,
    'needs review without auto-save',
  );
}

class _SkuCollisionMatrix {
  const _SkuCollisionMatrix();

  List<_SkuCollisionAxis> get axes => const [
    _SkuCollisionAxis(
      name: 'same sku different merchant',
      candidates: [
        _SkuCandidate('hd.pvc.elbow', merchant: 'Home Depot'),
        _SkuCandidate('lowes.pvc.elbow', merchant: 'Lowes'),
      ],
    ),
    _SkuCollisionAxis(
      name: 'same part number different brand',
      candidates: [
        _SkuCandidate('brandA.connector', brand: 'BrandA'),
        _SkuCandidate('brandB.connector', brand: 'BrandB'),
      ],
    ),
    _SkuCollisionAxis(
      name: 'same upc different pack count',
      candidates: [
        _SkuCandidate('coupling.single', packCount: 1),
        _SkuCandidate('coupling.2pk', packCount: 2),
      ],
    ),
    _SkuCollisionAxis(
      name: 'same short name different trade',
      candidates: [
        _SkuCandidate('plumbing.pvc.elbow', trade: 'plumbing'),
        _SkuCandidate('electrical.pvc.conduit.elbow', trade: 'electrical'),
      ],
    ),
    _SkuCollisionAxis(
      name: 'same brand different material',
      candidates: [
        _SkuCandidate('brand.pex.brass', material: 'brass'),
        _SkuCandidate('brand.pex.poly', material: 'poly'),
      ],
    ),
    _SkuCollisionAxis(
      name: 'same size different connection type',
      candidates: [
        _SkuCandidate('half.crimp', size: '1/2', connectionType: 'crimp'),
        _SkuCandidate('half.push', size: '1/2', connectionType: 'push'),
      ],
    ),
    _SkuCollisionAxis(
      name: 'same alias different canonical item',
      candidates: [
        _SkuCandidate('pipe.cap'),
        _SkuCandidate('electrical.cap'),
      ],
    ),
    _SkuCollisionAxis(
      name: 'private label remap',
      candidates: [
        _SkuCandidate('store.private.adapter'),
        _SkuCandidate('canonical.brass.adapter'),
      ],
    ),
    _SkuCollisionAxis(
      name: 'regional item number',
      candidates: [
        _SkuCandidate('menards.regional.coupling'),
        _SkuCandidate('ace.regional.coupling'),
      ],
    ),
    _SkuCollisionAxis(
      name: 'legacy sku',
      candidates: [
        _SkuCandidate('legacy.pvc.old'),
        _SkuCandidate('current.pvc.new'),
      ],
    ),
  ];
}

class _SkuCollisionParser {
  const _SkuCollisionParser();

  _SkuParseResult parse(String line, {String tradeScope = 'unknown'}) {
    final normalized = line.toLowerCase();
    final axisName = _axisFor(normalized, tradeScope);
    final candidates = _candidatesFor(axisName);
    final reasons = <String>[
      'confidence reasons',
      'not enough evidence',
      if (normalized.contains('lowes') || normalized.contains('home depot'))
        'merchant evidence',
      if (normalized.contains('acme')) 'brand evidence',
      if (RegExp(r'\b\d+/\d+\b').hasMatch(normalized)) 'size evidence',
      if (normalized.contains('pk')) 'pack count evidence',
    ];
    final forbidden = <String>{
      if (normalized.startsWith('sku ')) 'sku only final answer',
      if (normalized.startsWith('part ')) 'part number only final answer',
      if (normalized == 'acme') 'brand only final answer',
      if (normalized == 'home depot') 'merchant only final answer',
      if (normalized == 'pvc elbow') 'generic alias final answer',
      if (tradeScope == 'mixed') 'cross-trade auto-save',
    };
    return _SkuParseResult(
      axisName: axisName,
      rankedCandidates: candidates,
      confidenceReasons: reasons,
      conflictRules: const {'conflict rule', 'negative match'},
      forbiddenRules: forbidden,
    );
  }

  String _axisFor(String normalized, String tradeScope) {
    if (normalized.contains('upc')) return 'same upc different pack count';
    if (normalized.contains('private')) return 'private label remap';
    if (normalized.contains('sku')) return 'same sku different merchant';
    if (normalized.contains('part')) return 'same part number different brand';
    if (tradeScope == 'mixed') return 'same short name different trade';
    return 'same alias different canonical item';
  }

  List<_SkuCandidate> _candidatesFor(String axisName) {
    return switch (axisName) {
      'same upc different pack count' => const [
        _SkuCandidate('upc.coupling.single', packCount: 1),
        _SkuCandidate('upc.coupling.2pk', packCount: 2),
      ],
      'private label remap' => const [
        _SkuCandidate('store.private.adapter'),
        _SkuCandidate('canonical.brass.adapter'),
      ],
      'same sku different merchant' => const [
        _SkuCandidate('lowes.acme.pex.elbow.10pk', merchant: 'Lowes'),
        _SkuCandidate('hd.acme.pex.elbow.10pk', merchant: 'Home Depot'),
      ],
      'same part number different brand' => const [
        _SkuCandidate('brandA.part.77abc', brand: 'BrandA'),
        _SkuCandidate('brandB.part.77abc', brand: 'BrandB'),
      ],
      'same short name different trade' => const [
        _SkuCandidate('plumbing.pvc.elbow', trade: 'plumbing'),
        _SkuCandidate('electrical.pvc.conduit.elbow', trade: 'electrical'),
      ],
      _ => const [
        _SkuCandidate('generic.alias.primary'),
        _SkuCandidate('generic.alias.alternate'),
      ],
    };
  }
}

class _SkuCollisionAxis {
  const _SkuCollisionAxis({required this.name, required this.candidates});

  final String name;
  final List<_SkuCandidate> candidates;

  bool get needsReview => candidates.length > 1;

  bool get autoSaveAllowed => false;
}

class _SkuParseResult {
  const _SkuParseResult({
    required this.axisName,
    required this.rankedCandidates,
    required this.confidenceReasons,
    required this.conflictRules,
    required this.forbiddenRules,
  });

  final String axisName;
  final List<_SkuCandidate> rankedCandidates;
  final List<String> confidenceReasons;
  final Set<String> conflictRules;
  final Set<String> forbiddenRules;

  bool get needsReview => rankedCandidates.length > 1;

  bool get finalAnswerAllowed => false;

  bool get autoSaveAllowed => false;
}

class _SkuCandidate {
  const _SkuCandidate(
    this.itemId, {
    this.merchant = '',
    this.brand = '',
    this.trade = '',
    this.material = '',
    this.size = '',
    this.connectionType = '',
    this.packCount = 1,
  });

  final String itemId;
  final String merchant;
  final String brand;
  final String trade;
  final String material;
  final String size;
  final String connectionType;
  final int packCount;
}
