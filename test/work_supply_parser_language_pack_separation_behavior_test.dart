import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_locale_pack.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  group('inventory parser language pack separation behavior', () {
    test('priority locale packs keep US and Canada language axes separate', () {
      final packsById = {
        for (final pack in workSupplyPriorityLocalePacks) pack.id: pack,
      };

      expect(packsById.keys, containsAll(['en-US', 'es-US', 'en-CA', 'fr-CA']));
      expect(packsById['en-US']!.receiptLanguage, 'english');
      expect(packsById['es-US']!.receiptLanguage, 'spanish');
      expect(packsById['en-CA']!.receiptLanguage, 'english');
      expect(packsById['fr-CA']!.receiptLanguage, 'french');
      expect(packsById['en-US']!.measurementSystem, 'us-customary');
      expect(packsById['es-US']!.measurementSystem, 'us-customary');
      expect(packsById['en-CA']!.measurementSystem, contains('metric'));
      expect(packsById['fr-CA']!.measurementSystem, contains('metric'));
      expect(packsById['es-US']!.countryCodes, contains('US'));
      expect(packsById['fr-CA']!.countryCodes, ['CA']);
    });

    test('English and Spanish pack manifests use separate storage keys', () {
      final english = _coreOption(workSupplyLocalePackEnUs);
      final spanish = _coreOption(workSupplyLocalePackEsUs);

      expect(english.localePackId, 'en-US');
      expect(spanish.localePackId, 'es-US');
      expect(workSupplyTradePackOptionKey(english), 'plumbing:core');
      expect(workSupplyTradePackOptionKey(spanish), 'plumbing:es-us:core');
      expect(english.storagePath, endsWith('/plumbing/core.json.gz'));
      expect(spanish.storagePath, endsWith('/plumbing/es-US/core.json.gz'));
      expect(english.storagePath, isNot(spanish.storagePath));
      expect(english.toManifestMap()['localePackId'], 'en-US');
      expect(spanish.toManifestMap()['localePackId'], 'es-US');
    });

    test('locale packs share canonical item counts without duplicating items', () {
      final english = _coreOption(workSupplyLocalePackEnUs);
      final spanish = _coreOption(workSupplyLocalePackEsUs);
      final englishItems = buildWorkSupplyTradePackItems(
        'Plumbing',
        WorkSupplyTradePackTier.core,
      );
      final spanishItems = buildWorkSupplyTradePackItems(
        'Plumbing',
        WorkSupplyTradePackTier.core,
      );

      expect(spanish.itemCount, english.itemCount);
      expect(
        spanish.estimatedRawBytes,
        greaterThanOrEqualTo(english.estimatedRawBytes),
        reason: 'Spanish alias overlay must not duplicate canonical items.',
      );
      expect(spanishItems.map((item) => item.id), englishItems.map((item) => item.id));
    });

    test('Spanish US receipt aliases match same canonical identity', () {
      final english = matchReceiptLineToCatalog(
        '1/2 PEX CRIMP 90',
        tradeScope: 'Plumbing',
        localePackId: 'en-US',
        maxCandidates: 320,
      );
      final spanish = matchReceiptLineToCatalog(
        '1/2 CODO PEX 90',
        tradeScope: 'Plumbing',
        localePackId: 'es-US',
        maxCandidates: 320,
      );

      expect(english, isNotNull);
      expect(spanish, isNotNull);
      expect(spanish!.item.id, english!.item.id);
      expect(spanish.needsReview, isTrue);
      expect(spanish.confidence, greaterThanOrEqualTo(.74));
    });

    test('locale context boosts but does not force ambiguous matches', () {
      final spanish = matchReceiptLineToCatalog(
        'CODO PEX 90',
        tradeScope: 'Plumbing',
        localePackId: 'es-US',
        maxCandidates: 320,
      );
      final english = matchReceiptLineToCatalog(
        'CODO PEX 90',
        tradeScope: 'Plumbing',
        localePackId: 'en-US',
        maxCandidates: 320,
      );

      expect(spanish, isNotNull);
      expect(spanish!.needsReview, isTrue);
      expect(
        english == null || spanish.confidence >= english.confidence,
        isTrue,
      );
    });

    test('missing requested locale falls back conservatively', () {
      final selection = _selectLocaleForRegion(
        requestedLocale: 'fr-US',
        regionCode: 'US',
        installedLocaleIds: const {'en-US', 'es-US'},
      );

      expect(selection.localePackId, 'en-US');
      expect(selection.requiresReview, isTrue);
      expect(selection.reason, contains('missing locale pack'));
    });
  });
}

WorkSupplyTradePackOption _coreOption(WorkSupplyLocalePack localePack) {
  return buildWorkSupplyTradePackOptions(
    'Plumbing',
    localePack: localePack,
  ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.core);
}

_LocaleSelection _selectLocaleForRegion({
  required String requestedLocale,
  required String regionCode,
  required Set<String> installedLocaleIds,
}) {
  if (installedLocaleIds.contains(requestedLocale)) {
    return _LocaleSelection(
      localePackId: requestedLocale,
      requiresReview: false,
      reason: 'exact locale pack installed',
    );
  }
  final regionalDefault = switch (regionCode.toUpperCase()) {
    'US' => 'en-US',
    'CA' => 'en-CA',
    _ => 'en-US',
  };
  final fallback = installedLocaleIds.contains(regionalDefault)
      ? regionalDefault
      : installedLocaleIds.first;
  return _LocaleSelection(
    localePackId: fallback,
    requiresReview: true,
    reason: 'missing locale pack; conservative fallback selected',
  );
}

class _LocaleSelection {
  const _LocaleSelection({
    required this.localePackId,
    required this.requiresReview,
    required this.reason,
  });

  final String localePackId;
  final bool requiresReview;
  final String reason;
}
