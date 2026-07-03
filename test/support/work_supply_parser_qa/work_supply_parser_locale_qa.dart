import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_locale_pack.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserLocaleContractSuite extends QaSuite {
  const WorkSupplyParserLocaleContractSuite()
    : super('inventory.locale_contract');

  static const _requiredPriorityLocaleIds = {
    'en-US',
    'es-US',
    'en-CA',
    'fr-CA',
  };

  static const _releaseOneFixtureLocaleIds = {'es-US'};

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final localePacks = {
      for (final pack in workSupplyPriorityLocalePacks) pack.id: pack,
    };
    final fixtures = _loadFixtures();
    final fixtureLocaleCounts = <String, int>{};

    for (final localeId in _requiredPriorityLocaleIds) {
      if (localePacks.containsKey(localeId)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_priority_locale:$localeId',
          message: 'Priority locale pack is missing.',
          expected: localeId,
          actual: localePacks.keys.join(', '),
          suggestedFix:
              'Add the locale pack before claiming release coverage for that country/language.',
        ),
      );
    }

    for (final pack in localePacks.values) {
      _requireText(failures, pack.id, 'missing_locale_id:${pack.label}');
      _requireText(failures, pack.languageCode, 'missing_language:${pack.id}');
      _requireText(
        failures,
        pack.measurementSystem,
        'missing_measurement_system:${pack.id}',
      );
      _requireText(
        failures,
        pack.receiptLanguage,
        'missing_receipt_language:${pack.id}',
      );
      if (pack.countryCodes.isEmpty) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_country_codes:${pack.id}',
            message: 'Locale pack has no country codes.',
            actual: pack.label,
            suggestedFix:
                'Set at least one ISO-style country code so pack delivery can target users correctly.',
          ),
        );
      }
    }

    for (final fixture in fixtures) {
      if (fixture.localePackId.isEmpty) continue;
      fixtureLocaleCounts.update(
        fixture.localePackId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (!localePacks.containsKey(fixture.localePackId)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_unknown_locale:${fixture.id}',
            message: 'Fixture references an unknown locale pack.',
            expected: localePacks.keys.join(', '),
            actual: fixture.localePackId,
            suggestedFix:
                'Use a supported localePackId or add the locale pack before adding fixtures for it.',
          ),
        );
      }
      if (fixture.localePackId != workSupplyLocalePackEnUsId &&
          !fixture.riskTags.contains('locale_pack')) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'fixture_locale_missing_risk_tag:${fixture.id}',
            message: 'Localized fixture is missing locale_pack risk tag.',
            expected: 'locale_pack',
            actual: fixture.riskTags.join(', '),
            suggestedFix:
                'Tag localized fixtures so coverage reports prove language-pack coverage.',
          ),
        );
      }
    }

    for (final localeId in _releaseOneFixtureLocaleIds) {
      if ((fixtureLocaleCounts[localeId] ?? 0) > 0) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_fixture_locale:$localeId',
          message: 'Release-one locale has no parser fixture coverage.',
          expected: localeId,
          actual: fixtureLocaleCounts.keys.join(', '),
          suggestedFix:
              'Add at least one fixture for this locale before release-one parser claims.',
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked:
          _requiredPriorityLocaleIds.length +
          (workSupplyPriorityLocalePacks.length * 5) +
          fixtures.length +
          _releaseOneFixtureLocaleIds.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'priorityLocaleCount': workSupplyPriorityLocalePacks.length,
        'fixtureLocaleCounts': fixtureLocaleCounts,
      },
    );
  }

  void _requireText(List<QaFailure> failures, String value, String id) {
    if (value.trim().isNotEmpty) return;
    failures.add(
      QaFailure(
        suite: name,
        id: id,
        message: 'Locale pack is missing required text metadata.',
        suggestedFix:
            'Fill locale metadata so pack delivery and parser reports stay explainable.',
      ),
    );
  }
}

class _LocaleFixture {
  const _LocaleFixture({
    required this.id,
    required this.localePackId,
    required this.riskTags,
  });

  final String id;
  final String localePackId;
  final List<String> riskTags;

  static _LocaleFixture fromJson(Map<String, Object?> json) {
    return _LocaleFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      localePackId: json['localePackId'] as String? ?? '',
      riskTags: [
        for (final tag in json['riskTags'] as List<dynamic>? ?? const [])
          tag.toString(),
      ],
    );
  }
}

List<_LocaleFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _LocaleFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}
