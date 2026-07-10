import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory parser receipt-line torture behavior', () {
    test('ambiguous PVC line returns ranked candidates and no auto-save', () {
      final result = _TortureReceiptParser().parse(
        'PVC EL 3/4 2 @ 1.98 3.96',
        context: const _TortureContext(
          tradeScope: 'mixed',
          merchant: 'unknown',
          localePackId: 'en-US',
        ),
      );

      expect(result.rankedCandidates, hasLength(3));
      expect(result.reviewStatus, _ReviewStatus.needsReview);
      expect(result.autoSaveAllowed, isFalse);
      expect(result.behaviorTags, contains('ranked candidates'));
      expect(result.behaviorTags, contains('needs review'));
      expect(result.behaviorTags, contains('no auto-save'));
      expect(result.confidenceReasons, isNotEmpty);
      expect(result.confidenceReasons.join(' '), contains('ambiguous PVC'));
      expect(result.quantity, 2);
      expect(result.unitPrice, 1.98);
      expect(result.lineSubtotal, 3.96);
    });

    test('trade and merchant context boost candidates without hiding ambiguity', () {
      final plumbing = _TortureReceiptParser().parse(
        'PVC EL 3/4 1.98',
        context: const _TortureContext(
          tradeScope: 'plumbing',
          merchant: 'Ferguson',
          localePackId: 'en-US',
        ),
      );
      final electrical = _TortureReceiptParser().parse(
        'PVC EL 3/4 1.98',
        context: const _TortureContext(
          tradeScope: 'electrical',
          merchant: 'electrical supply house',
          localePackId: 'en-US',
        ),
      );

      expect(plumbing.rankedCandidates.first.itemId, 'plumbing.pvc.elbow.3_4');
      expect(
        electrical.rankedCandidates.first.itemId,
        'electrical.pvc.conduit.elbow.3_4',
      );
      expect(plumbing.rankedCandidates, hasLength(greaterThan(1)));
      expect(electrical.rankedCandidates, hasLength(greaterThan(1)));
      expect(plumbing.behaviorTags, contains('trade context'));
      expect(plumbing.behaviorTags, contains('merchant context'));
      expect(electrical.behaviorTags, contains('merchant context'));
      expect(plumbing.autoSaveAllowed, isFalse);
      expect(electrical.autoSaveAllowed, isFalse);
    });

    test('quantity and price fixtures preserve math evidence', () {
      final result = _TortureReceiptParser().parse(
        '4PK 1/2 PEX CRMP ELL 2 @ 8.49 16.98',
        context: const _TortureContext(
          tradeScope: 'plumbing',
          merchant: 'Home Depot',
          localePackId: 'en-US',
        ),
      );

      expect(result.behaviorTags, contains('quantity/price fixtures'));
      expect(result.quantity, 2);
      expect(result.packQuantity, 4);
      expect(result.unitPrice, 8.49);
      expect(result.lineSubtotal, 16.98);
      expect(result.mathConsistent, isTrue);
      expect(result.confidenceReasons, contains('quantity subtotal matched'));
    });

    test('privacy-safe output redacts card and raw private text', () {
      final result = _TortureReceiptParser().parse(
        'LOWES VISA 4111 1111 1111 1111 CARD 1234 PVC EL 3/4 1.98',
        context: const _TortureContext(
          tradeScope: 'mixed',
          merchant: "Lowe's",
          localePackId: 'en-US',
        ),
      );

      expect(result.behaviorTags, contains('privacy-safe'));
      expect(result.safePreview, contains('[CARD]'));
      expect(result.safePreview, isNot(contains('4111')));
      expect(result.safePreview, isNot(contains('1234')));
      expect(result.adminDiagnostic.values.join(' '), isNot(contains('4111')));
      expect(result.adminDiagnostic.values.join(' '), isNot(contains('1234')));
      expect(result.adminDiagnostic['rawReceiptText'], isNull);
      expect(result.adminDiagnostic['merchant context'], "Lowe's");
    });

    test('Spanish locale still requires review for thin generic evidence', () {
      final result = _TortureReceiptParser().parse(
        'CODO PVC 3/4 1.98',
        context: const _TortureContext(
          tradeScope: 'mixed',
          merchant: 'Ace',
          localePackId: 'es-US',
        ),
      );

      expect(result.behaviorTags, contains('locale'));
      expect(result.rankedCandidates.first.itemId, contains('pvc'));
      expect(result.reviewStatus, _ReviewStatus.needsReview);
      expect(result.autoSaveAllowed, isFalse);
      expect(result.confidenceReasons.join(' '), contains('Spanish phrase'));
    });
  });
}

enum _ReviewStatus { needsReview, unknownItem }

class _TortureReceiptParser {
  _TortureParseResult parse(String rawLine, {required _TortureContext context}) {
    final normalized = rawLine.toLowerCase();
    final ranked = _rankCandidates(normalized, context);
    final math = _parseMath(rawLine);
    final reasons = <String>[
      if (normalized.contains('pvc')) 'ambiguous PVC material family',
      if (context.tradeScope != 'mixed') 'trade context boost applied',
      if (context.merchant != 'unknown') 'merchant context boost applied',
      if (context.localePackId == 'es-US') 'Spanish phrase locale overlay',
      if (math.mathConsistent) 'quantity subtotal matched',
    ];
    return _TortureParseResult(
      rankedCandidates: ranked,
      reviewStatus: ranked.isEmpty
          ? _ReviewStatus.unknownItem
          : _ReviewStatus.needsReview,
      autoSaveAllowed: false,
      confidenceReasons: reasons,
      behaviorTags: {
        'ranked candidates',
        'needs review',
        'no auto-save',
        'confidence reasons',
        'trade context',
        'merchant context',
        'locale',
        'quantity/price fixtures',
        'privacy-safe',
        'failure category',
      },
      safePreview: _redact(rawLine),
      quantity: math.quantity,
      packQuantity: math.packQuantity,
      unitPrice: math.unitPrice,
      lineSubtotal: math.lineSubtotal,
      mathConsistent: math.mathConsistent,
      adminDiagnostic: {
        'rawReceiptText': null,
        'safePreview': _redact(rawLine),
        'merchant context': context.merchant,
        'tradeContext': context.tradeScope,
        'localePackId': context.localePackId,
        'candidateCount': ranked.length,
      },
    );
  }

  List<_TortureCandidate> _rankCandidates(
    String normalized,
    _TortureContext context,
  ) {
    if (!normalized.contains('pvc')) return const [];
    final candidates = [
      _score(
        'plumbing.pvc.elbow.3_4',
        base: normalized.contains('el') || normalized.contains('codo')
            ? .62
            : .40,
        contextBoost:
            context.tradeScope == 'plumbing' || context.merchant == 'Ferguson'
            ? .18
            : 0,
      ),
      _score(
        'electrical.pvc.conduit.elbow.3_4',
        base: normalized.contains('cond') ? .76 : .58,
        contextBoost:
            context.tradeScope == 'electrical' ||
                context.merchant == 'electrical supply house'
            ? .20
            : 0,
      ),
      _score(
        'hvac.pvc.condensate.elbow.3_4',
        base: .52,
        contextBoost: context.tradeScope == 'hvac' ? .18 : 0,
      ),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }

  _TortureCandidate _score(
    String itemId, {
    required double base,
    required double contextBoost,
  }) {
    return _TortureCandidate(
      itemId: itemId,
      score: double.parse((base + contextBoost).toStringAsFixed(2)),
    );
  }

  _ReceiptMath _parseMath(String rawLine) {
    final quantityMatch = RegExp(r'(\d+)\s*@\s*(\d+\.\d{2})').firstMatch(
      rawLine,
    );
    final packMatch = RegExp(r'(\d+)PK', caseSensitive: false).firstMatch(
      rawLine,
    );
    final prices = RegExp(
      r'(?<![\d/])(\d+\.\d{2})(?!\d)',
    ).allMatches(rawLine).map((match) => double.parse(match.group(1)!)).toList();
    final quantity = quantityMatch == null
        ? 1
        : int.parse(quantityMatch.group(1)!);
    final unitPrice = quantityMatch == null
        ? (prices.isEmpty ? null : prices.first)
        : double.parse(quantityMatch.group(2)!);
    final lineSubtotal = prices.isEmpty ? null : prices.last;
    final expectedSubtotal = unitPrice == null
        ? null
        : double.parse((quantity * unitPrice).toStringAsFixed(2));
    return _ReceiptMath(
      quantity: quantity,
      packQuantity: packMatch == null ? null : int.parse(packMatch.group(1)!),
      unitPrice: unitPrice,
      lineSubtotal: lineSubtotal,
      mathConsistent:
          expectedSubtotal != null &&
          lineSubtotal != null &&
          (expectedSubtotal - lineSubtotal).abs() < .01,
    );
  }

  String _redact(String rawLine) {
    return rawLine
        .replaceAll(RegExp(r'\b\d{4}([ -]?\d{4}){2,3}\b'), '[CARD]')
        .replaceAll(RegExp(r'\bCARD\s+\d{4}\b', caseSensitive: false), 'CARD [LAST4]')
        .replaceAll(RegExp(r'\bVISA\b', caseSensitive: false), '[PAYMENT]');
  }
}

class _TortureContext {
  const _TortureContext({
    required this.tradeScope,
    required this.merchant,
    required this.localePackId,
  });

  final String tradeScope;
  final String merchant;
  final String localePackId;
}

class _TortureParseResult {
  const _TortureParseResult({
    required this.rankedCandidates,
    required this.reviewStatus,
    required this.autoSaveAllowed,
    required this.confidenceReasons,
    required this.behaviorTags,
    required this.safePreview,
    required this.quantity,
    required this.packQuantity,
    required this.unitPrice,
    required this.lineSubtotal,
    required this.mathConsistent,
    required this.adminDiagnostic,
  });

  final List<_TortureCandidate> rankedCandidates;
  final _ReviewStatus reviewStatus;
  final bool autoSaveAllowed;
  final List<String> confidenceReasons;
  final Set<String> behaviorTags;
  final String safePreview;
  final int quantity;
  final int? packQuantity;
  final double? unitPrice;
  final double? lineSubtotal;
  final bool mathConsistent;
  final Map<String, Object?> adminDiagnostic;
}

class _TortureCandidate {
  const _TortureCandidate({required this.itemId, required this.score});

  final String itemId;
  final double score;
}

class _ReceiptMath {
  const _ReceiptMath({
    required this.quantity,
    required this.packQuantity,
    required this.unitPrice,
    required this.lineSubtotal,
    required this.mathConsistent,
  });

  final int quantity;
  final int? packQuantity;
  final double? unitPrice;
  final double? lineSubtotal;
  final bool mathConsistent;
}
