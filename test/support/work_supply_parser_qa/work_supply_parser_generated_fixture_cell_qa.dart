import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserGeneratedFixtureCellSuite extends QaSuite {
  const WorkSupplyParserGeneratedFixtureCellSuite()
    : super('inventory.generated_fixture_cell_contract');

  static const _fixtureRoot = String.fromEnvironment(
    'PARSER_QA_GENERATED_FIXTURE_ROOT',
    defaultValue: 'build/parser_qa_generated/work_supply_parser',
  );
  static const _tradeFilter = String.fromEnvironment(
    'PARSER_QA_GENERATED_FIXTURE_TRADES',
  );
  static const _tierFilter = String.fromEnvironment(
    'PARSER_QA_GENERATED_FIXTURE_TIERS',
  );
  static const _localeFilter = String.fromEnvironment(
    'PARSER_QA_GENERATED_FIXTURE_LOCALES',
  );
  static const _priorityTrades = ['plumbing', 'electrical', 'hvac'];
  static const _tiers = ['core', 'standard', 'professional', 'complete'];
  static const _locales = ['en-US', 'es-US'];
  static const _expectedCountPerCell = int.fromEnvironment(
    'PARSER_QA_GENERATED_FIXTURE_EXPECTED_COUNT',
    defaultValue: 500,
  );
  static const _maxRawLineLength = 96;

  static const _requiredJsonFields = {
    'id',
    'caseType',
    'merchant',
    'riskTags',
    'rawLine',
    'expectedTrade',
    'expectedNameContains',
    'tradeScope',
    'sourceType',
    'sourceOwner',
    'reviewStatus',
  };

  static const _allowedCaseTypes = {
    'clear_match',
    'dangerous_generic',
    'receipt_noise',
    'ambiguous_review',
    'negative_match',
    'quantity_price',
  };

  static const _requiredMerchants = {
    'Home Depot',
    'Lowes',
    'Ace',
    'Ferguson',
    'Grainger',
    'Menards',
    'True Value',
    'Walmart',
    'Supply House',
    'unknown',
  };

  static const _requiredRiskTags = {
    'merchant_abbreviation',
    'dangerous_word',
    'noise_line',
    'negative_match',
    'quantity',
    'spanish',
    'locale_pack',
    'return_line',
    'discount_line',
    'mixed_trade_receipt',
    'supply_house',
    'generated_batch',
  };

  static const _dangerousWords = {
    'PVC',
    'TAPE',
    'FILTER',
    'BOX',
    'ADAPTER',
    'COUPLING',
    'ELBOW',
    'TEE',
    'CAP',
    'PLUG',
    'PIPE',
    'WIRE',
    'CONDUIT',
    'CEMENT',
    'PRIMER',
    'VALVE',
    'FITTING',
    'CONNECTOR',
    'KIT',
    'SUPPLY',
    'BLACK',
    'WHITE',
  };

  static const _spanishTokens = {
    'ACOPLE',
    'ADAPTADOR',
    'CAJA',
    'CABLE',
    'CINTA',
    'CODO',
    'CONECTOR',
    'CONDUCTO',
    'FILTRO',
    'TAPON',
    'TUBO',
    'VALVULA',
    'TORNILLO',
    'TUERCA',
    'ARANDELA',
    'ABRAZADERA',
    'VARILLA',
    'ROSCADA',
  };

  static const _privacyPatterns = [
    _PrivacyPattern('email', r'\b[\w.+%-]+@[\w.-]+\.[A-Za-z]{2,}\b'),
    _PrivacyPattern('phone', r'\b\d{3}[-.]\d{3}[-.]\d{4}\b'),
    _PrivacyPattern('card_like_number', r'\b\d{12,19}\b'),
    _PrivacyPattern(
      'address',
      r'\b\d{1,6}\s+[A-Za-z0-9 .#-]{2,40}\s+(?:st|street|rd|road|ave|avenue|blvd|lane|ln|dr|drive|ct|court)\b',
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final cellMetrics = <Map<String, Object?>>[];
    var checked = 0;

    for (final cell in _expectedCells()) {
      final result = _checkCell(cell, failures);
      checked += result.checked;
      cellMetrics.add(result.metrics);
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixtureRoot': _fixtureRoot,
        'expectedCells': _expectedCells().length,
        'tradeFilter': _tradeFilter,
        'tierFilter': _tierFilter,
        'localeFilter': _localeFilter,
        'expectedCountPerCell': _expectedCountPerCell,
        'cells': cellMetrics,
        'contract':
            'Generated residential fixture cells must be complete, local-only, privacy-safe, locale-aware, merchant-diverse, and surgical-rerun friendly.',
      },
    );
  }

  _CellResult _checkCell(_FixtureCell cell, List<QaFailure> failures) {
    final fixtures = _readFixtures(cell, failures);
    final ids = <String>{};
    final rawLines = <String>{};
    final caseTypes = <String, int>{};
    final merchants = <String, int>{};
    final riskTags = <String, int>{};
    final expectedNames = <String, int>{};
    var checked = 1;

    if (fixtures.length != _expectedCountPerCell) {
      failures.add(
        _failure(
          cell,
          'wrong_fixture_count',
          'Generated fixture cell has the wrong fixture count.',
          '$_expectedCountPerCell fixtures',
          '${fixtures.length} fixtures',
          'Regenerate or complete this cell before relying on its parser coverage.',
          category: QaFailureTriage.fixture,
        ),
      );
    }

    for (final fixture in fixtures) {
      checked += 24;
      _checkRequiredFields(cell, fixture, failures);
      _checkStableIdentity(cell, fixture, ids, failures);
      _checkRawLine(cell, fixture, rawLines, failures);
      _checkExpectedRouting(cell, fixture, failures);
      _checkReviewAndSource(cell, fixture, failures);
      _checkPrivacy(cell, fixture, failures);
      _checkLocale(cell, fixture, failures);
      _checkRiskShape(cell, fixture, failures);
      _checkDangerousWordReview(cell, fixture, failures);
      _count(caseTypes, fixture.caseType);
      _count(merchants, fixture.merchant);
      for (final tag in fixture.riskTags) {
        _count(riskTags, tag);
      }
      _count(expectedNames, fixture.expectedNameContains);
    }

    _checkCellCoverage(
      cell,
      fixtures,
      caseTypes,
      merchants,
      riskTags,
      failures,
    );

    return _CellResult(checked, {
      'cellId': cell.id,
      'fixturePath': cell.path,
      'fixtureCount': fixtures.length,
      'caseTypes': caseTypes,
      'merchantCount': merchants.length,
      'riskTagCount': riskTags.length,
      'expectedNameFamilies': expectedNames.length,
    });
  }

  List<_GeneratedFixture> _readFixtures(
    _FixtureCell cell,
    List<QaFailure> failures,
  ) {
    final file = File(cell.path);
    if (!file.existsSync()) {
      failures.add(
        _failure(
          cell,
          'missing_fixture_file',
          'Generated fixture cell file is missing.',
          cell.path,
          'not found',
          'Generate this fixture cell before running release-one parser evidence.',
          category: QaFailureTriage.fixture,
        ),
      );
      return const [];
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! List) {
        failures.add(
          _failure(
            cell,
            'fixture_file_not_list',
            'Generated fixture cell file must contain a JSON list.',
            'JSON list',
            decoded.runtimeType.toString(),
            'Rewrite this generated fixture artifact with the standard fixture schema.',
            category: QaFailureTriage.fixture,
          ),
        );
        return const [];
      }
      return [
        for (var index = 0; index < decoded.length; index++)
          _GeneratedFixture.fromJson(
            cell: cell,
            index: index,
            json: (decoded[index] as Map).cast<String, Object?>(),
          ),
      ];
    } catch (error) {
      failures.add(
        _failure(
          cell,
          'fixture_json_decode_failed',
          'Generated fixture cell could not be decoded.',
          'valid generated fixture JSON',
          error.toString(),
          'Fix or regenerate the corrupted fixture artifact.',
          category: QaFailureTriage.fixture,
        ),
      );
      return const [];
    }
  }

  void _checkRequiredFields(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    List<QaFailure> failures,
  ) {
    final missing = [
      for (final field in _requiredJsonFields)
        if (!fixture.raw.containsKey(field)) field,
    ];
    if (missing.isEmpty) return;
    failures.add(
      _fixtureFailure(
        cell,
        fixture,
        'missing_required_fields',
        'Generated fixture is missing required parser QA fields.',
        _requiredJsonFields.join(', '),
        'missing ${missing.join(', ')}',
        'Keep generated fixtures rich enough for surgical parser failure triage.',
        category: QaFailureTriage.schema,
      ),
    );
  }

  void _checkStableIdentity(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    Set<String> ids,
    List<QaFailure> failures,
  ) {
    final expectedPrefix =
        '${cell.trade}_${cell.scope}_${cell.tier}_${cell.localeSafe}_';
    if (!fixture.id.startsWith(expectedPrefix)) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'bad_fixture_id_prefix',
          'Fixture id does not encode trade/scope/tier/locale cell.',
          expectedPrefix,
          fixture.id,
          'Use deterministic cell-prefixed fixture ids so failures can rerun surgically.',
          category: QaFailureTriage.schema,
        ),
      );
    }
    if (!ids.add(fixture.id)) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'duplicate_fixture_id',
          'Generated fixture id is duplicated inside its cell.',
          'unique fixture id',
          fixture.id,
          'Fix generator identity before trusting coverage totals.',
          category: QaFailureTriage.schema,
        ),
      );
    }
  }

  void _checkRawLine(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    Set<String> rawLines,
    List<QaFailure> failures,
  ) {
    if (fixture.rawLine.trim().isEmpty) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'empty_raw_line',
          'Fixture rawLine is empty.',
          'non-empty receipt-style parser input',
          'empty',
          'Every generated fixture must feed one realistic parser line.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
    if (fixture.rawLine.length > _maxRawLineLength) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'raw_line_too_long',
          'Fixture rawLine is too long for compact receipt-line coverage.',
          '<= $_maxRawLineLength characters',
          '${fixture.rawLine.length} characters',
          'Keep generated receipt lines compact and add long-line torture coverage separately.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
    final normalized = _normalizeLine(fixture.rawLine);
    if (!rawLines.add(normalized)) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'duplicate_raw_line',
          'Generated fixture rawLine is duplicated inside its cell.',
          'unique normalized rawLine',
          fixture.rawLine,
          'Generate a different merchant, size, abbreviation, locale, or risk variation.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
  }

  void _checkExpectedRouting(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    List<QaFailure> failures,
  ) {
    if (!_equalsIgnoreCase(fixture.expectedTrade, _title(cell.trade))) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'wrong_expected_trade',
          'Fixture expectedTrade does not match the fixture cell trade.',
          _title(cell.trade),
          fixture.expectedTrade,
          'Keep trade routing explicit so mixed-trade receipts can be triaged.',
          category: QaFailureTriage.category,
        ),
      );
    }
    if (!_equalsIgnoreCase(fixture.tradeScope, _title(cell.trade))) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'wrong_trade_scope',
          'Fixture tradeScope does not match the fixture cell trade.',
          _title(cell.trade),
          fixture.tradeScope,
          'Keep fixture trade scope aligned with the parser pack under test.',
          category: QaFailureTriage.category,
        ),
      );
    }
    if (fixture.expectedNameContains.trim().length < 2 &&
        fixture.caseType != 'receipt_noise' &&
        fixture.caseType != 'ambiguous_review') {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'weak_expected_name',
          'Fixture has no useful expected item-family signal.',
          'expectedNameContains length >= 2',
          fixture.expectedNameContains,
          'Generated parser fixtures must identify the intended item family or explicitly require review.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
  }

  void _checkReviewAndSource(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    List<QaFailure> failures,
  ) {
    if (fixture.sourceType != 'synthetic') {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'fixture_not_synthetic',
          'Generated fixture sourceType must stay synthetic.',
          'synthetic',
          fixture.sourceType,
          'Do not mix real/private receipt evidence into generated fixture cells.',
          category: QaFailureTriage.privacy,
        ),
      );
    }
    if (!fixture.sourceOwner.toLowerCase().contains('mainteniac')) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'missing_source_owner',
          'Generated fixture source owner is not explicit.',
          'Mainteniac QA generator',
          fixture.sourceOwner,
          'Keep fixture provenance obvious for future release audits.',
          category: QaFailureTriage.governance,
        ),
      );
    }
    if (fixture.reviewStatus != 'generated-not-release-approved') {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'bad_review_status',
          'Generated fixture reviewStatus is not conservative.',
          'generated-not-release-approved',
          fixture.reviewStatus,
          'Generated fixtures should require explicit release approval before being treated as ground truth.',
          category: QaFailureTriage.reviewSafety,
        ),
      );
    }
  }

  void _checkPrivacy(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    List<QaFailure> failures,
  ) {
    for (final pattern in _privacyPatterns) {
      if (!RegExp(
        pattern.regex,
        caseSensitive: false,
      ).hasMatch(fixture.rawLine)) {
        continue;
      }
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'private_raw_line_${pattern.name}',
          'Generated fixture rawLine looks like it contains private user data.',
          'synthetic material line with no private data',
          fixture.rawLine,
          'Remove emails, phone numbers, addresses, card-like numbers, and private receipt identifiers from generated parser fixtures.',
          category: QaFailureTriage.privacy,
        ),
      );
    }
  }

  void _checkLocale(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    List<QaFailure> failures,
  ) {
    if (cell.locale == 'es-US') {
      if (fixture.localePackId != 'es-US') {
        failures.add(
          _fixtureFailure(
            cell,
            fixture,
            'missing_spanish_locale_pack_id',
            'Spanish generated fixture must declare localePackId.',
            'es-US',
            fixture.localePackId,
            'Keep Spanish pack evidence separate from English pack evidence.',
            category: QaFailureTriage.locale,
          ),
        );
      }
      final line = fixture.rawLine.toUpperCase();
      final hasSpanishSignal =
          _spanishTokens.any(line.contains) ||
          fixture.riskTags.contains('spanish') ||
          fixture.riskTags.contains('locale_pack');
      if (!hasSpanishSignal) {
        failures.add(
          _fixtureFailure(
            cell,
            fixture,
            'spanish_fixture_without_spanish_signal',
            'Spanish fixture has no Spanish alias or locale signal.',
            'Spanish rawLine token or spanish/locale_pack risk tag',
            fixture.rawLine,
            'Add Spanish trade wording, Spanglish, or explicit locale-pack risk tags.',
            category: QaFailureTriage.locale,
          ),
        );
      }
    } else {
      if (fixture.localePackId.isNotEmpty &&
          fixture.localePackId != cell.locale) {
        failures.add(
          _fixtureFailure(
            cell,
            fixture,
            'unexpected_locale_pack_id',
            'English fixture has an unexpected localePackId.',
            'blank or ${cell.locale}',
            fixture.localePackId,
            'Do not mix Spanish locale overlay evidence into English cells.',
            category: QaFailureTriage.locale,
          ),
        );
      }
    }
  }

  void _checkRiskShape(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    List<QaFailure> failures,
  ) {
    if (!_allowedCaseTypes.contains(fixture.caseType)) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'unknown_case_type',
          'Fixture caseType is not one of the governed parser QA categories.',
          _allowedCaseTypes.join(', '),
          fixture.caseType,
          'Use governed case types so coverage metrics remain comparable across cells.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
    if (!fixture.riskTags.contains('generated_batch')) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'missing_generated_batch_tag',
          'Generated fixture is missing generated_batch risk tag.',
          'generated_batch',
          fixture.riskTags.join(', '),
          'Tag generated fixture rows so generated coverage can be separated from hand-written golden fixtures.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
    if (!fixture.riskTags.contains(cell.tier)) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'missing_tier_risk_tag',
          'Generated fixture is missing its pack-tier risk tag.',
          cell.tier,
          fixture.riskTags.join(', '),
          'Risk tags should allow surgical reruns by tier.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
    if (!fixture.riskTags.contains(cell.locale)) {
      failures.add(
        _fixtureFailure(
          cell,
          fixture,
          'missing_locale_risk_tag',
          'Generated fixture is missing its locale risk tag.',
          cell.locale,
          fixture.riskTags.join(', '),
          'Risk tags should allow surgical reruns by locale.',
          category: QaFailureTriage.locale,
        ),
      );
    }
  }

  void _checkDangerousWordReview(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    List<QaFailure> failures,
  ) {
    final line = fixture.rawLine.toUpperCase();
    final risky = _dangerousWords.where(line.contains).toList();
    if (risky.isEmpty) return;
    final hasSpecificEvidence =
        RegExp(r'\b\d+(/\d+)?\b').hasMatch(line) ||
        fixture.riskTags.contains('size') ||
        fixture.riskTags.contains('negative_match') ||
        fixture.caseType == 'ambiguous_review' ||
        fixture.caseType == 'dangerous_generic' ||
        fixture.caseType == 'negative_match';
    if (hasSpecificEvidence) return;
    failures.add(
      _fixtureFailure(
        cell,
        fixture,
        'dangerous_word_without_specific_evidence',
        'Fixture contains dangerous generic material wording without enough disambiguating evidence.',
        'size, negative-match, or review case type',
        'dangerous=${risky.take(4).join(', ')} rawLine=${fixture.rawLine}',
        'Generated fixtures should prove ambiguity handling instead of implying generic words are enough.',
        category: QaFailureTriage.conflict,
      ),
    );
  }

  void _checkCellCoverage(
    _FixtureCell cell,
    List<_GeneratedFixture> fixtures,
    Map<String, int> caseTypes,
    Map<String, int> merchants,
    Map<String, int> riskTags,
    List<QaFailure> failures,
  ) {
    if (fixtures.isEmpty) return;
    for (final required in const ['clear_match', 'ambiguous_review']) {
      if (caseTypes.containsKey(required)) continue;
      failures.add(
        _failure(
          cell,
          'missing_cell_case_type_$required',
          'Generated fixture cell is missing a required case type.',
          required,
          caseTypes.keys.join(', '),
          'Each release-one cell needs clear matches plus review/ambiguity pressure.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
    for (final merchant in _requiredMerchants) {
      if (merchants.containsKey(merchant)) continue;
      failures.add(
        _failure(
          cell,
          'missing_cell_merchant_${_safeId(merchant)}',
          'Generated fixture cell is missing major merchant coverage.',
          merchant,
          merchants.keys.join(', '),
          'Add non-proprietary synthetic receipt wording for this merchant family.',
          category: QaFailureTriage.merchantRule,
        ),
      );
    }
    final requiredTags = {
      'generated_batch',
      cell.tier,
      cell.locale,
      if (cell.locale == 'es-US') ...['spanish', 'locale_pack'],
      if (cell.trade == 'plumbing') ...['pvc', 'valve'],
      if (cell.trade == 'electrical') ...['wire', 'box'],
      if (cell.trade == 'hvac') ...['filter', 'tape'],
    };
    for (final tag in requiredTags) {
      if (riskTags.containsKey(tag)) continue;
      failures.add(
        _failure(
          cell,
          'missing_cell_risk_tag_${_safeId(tag)}',
          'Generated fixture cell is missing required risk-tag coverage.',
          tag,
          riskTags.keys.join(', '),
          'Add fixture variants for this risk tag so failures can be grouped and rerun surgically.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
    final recommendedHitCount = _requiredRiskTags
        .where(riskTags.containsKey)
        .length;
    if (recommendedHitCount < 7) {
      failures.add(
        _failure(
          cell,
          'thin_cell_risk_tag_matrix',
          'Generated fixture cell has thin risk-tag diversity.',
          'at least 7 governed risk tags',
          '$recommendedHitCount tags from governed matrix',
          'Broaden this cell with merchant abbreviation, dangerous-word, noise, quantity, negative-match, return/discount, or supply-house fixtures.',
          category: QaFailureTriage.fixture,
        ),
      );
    }
  }

  QaFailure _failure(
    _FixtureCell cell,
    String id,
    String message,
    String expected,
    String actual,
    String fix, {
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: '$id:${cell.id}',
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {
        'triageCategory': category,
        'cellId': cell.id,
        'trade': cell.trade,
        'tier': cell.tier,
        'localePackId': cell.locale,
      },
    );
  }

  QaFailure _fixtureFailure(
    _FixtureCell cell,
    _GeneratedFixture fixture,
    String id,
    String message,
    String expected,
    String actual,
    String fix, {
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: '$id:${fixture.id}',
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {
        'triageCategory': category,
        'cellId': cell.id,
        'fixtureId': fixture.id,
        'fixtureIndex': fixture.index,
        'trade': cell.trade,
        'tier': cell.tier,
        'localePackId': cell.locale,
      },
    );
  }
}

Iterable<_FixtureCell> _expectedCells() sync* {
  final trades = _filterOrDefault(
    WorkSupplyParserGeneratedFixtureCellSuite._tradeFilter,
    WorkSupplyParserGeneratedFixtureCellSuite._priorityTrades,
  );
  final tiers = _filterOrDefault(
    WorkSupplyParserGeneratedFixtureCellSuite._tierFilter,
    WorkSupplyParserGeneratedFixtureCellSuite._tiers,
  );
  final locales = _filterOrDefault(
    WorkSupplyParserGeneratedFixtureCellSuite._localeFilter,
    WorkSupplyParserGeneratedFixtureCellSuite._locales,
  );
  for (final trade in trades) {
    for (final tier in tiers) {
      for (final locale in locales) {
        yield _FixtureCell(
          trade: trade,
          scope: 'residential',
          tier: tier,
          locale: locale,
        );
      }
    }
  }
}

class _FixtureCell {
  const _FixtureCell({
    required this.trade,
    required this.scope,
    required this.tier,
    required this.locale,
  });

  final String trade;
  final String scope;
  final String tier;
  final String locale;

  String get localeSafe => locale.replaceAll('-', '_');

  String get id => '${trade}_${scope}_${tier}_$localeSafe';

  String get path {
    final root = WorkSupplyParserGeneratedFixtureCellSuite._fixtureRoot;
    final direct = '$root/$trade/$scope/$tier/$locale/generated_fixtures.json';
    if (File(direct).existsSync()) return direct;
    final queueCell =
        '$root/$trade/$scope/$tier/$locale/fixtures/work_supply_parser/'
        '$trade/$scope/$tier/$locale/generated_fixtures.json';
    if (File(queueCell).existsSync()) return queueCell;
    return direct;
  }
}

class _GeneratedFixture {
  const _GeneratedFixture({
    required this.cell,
    required this.index,
    required this.raw,
    required this.id,
    required this.caseType,
    required this.merchant,
    required this.riskTags,
    required this.rawLine,
    required this.expectedTrade,
    required this.expectedNameContains,
    required this.tradeScope,
    required this.localePackId,
    required this.sourceType,
    required this.sourceOwner,
    required this.reviewStatus,
  });

  final _FixtureCell cell;
  final int index;
  final Map<String, Object?> raw;
  final String id;
  final String caseType;
  final String merchant;
  final List<String> riskTags;
  final String rawLine;
  final String expectedTrade;
  final String expectedNameContains;
  final String tradeScope;
  final String localePackId;
  final String sourceType;
  final String sourceOwner;
  final String reviewStatus;

  static _GeneratedFixture fromJson({
    required _FixtureCell cell,
    required int index,
    required Map<String, Object?> json,
  }) {
    return _GeneratedFixture(
      cell: cell,
      index: index,
      raw: json,
      id: json['id']?.toString() ?? '${cell.id}_missing_id_$index',
      caseType: json['caseType']?.toString() ?? '',
      merchant: json['merchant']?.toString() ?? '',
      riskTags: [
        for (final tag in json['riskTags'] as List<dynamic>? ?? const [])
          tag.toString(),
      ],
      rawLine: json['rawLine']?.toString() ?? '',
      expectedTrade: json['expectedTrade']?.toString() ?? '',
      expectedNameContains: json['expectedNameContains']?.toString() ?? '',
      tradeScope: json['tradeScope']?.toString() ?? '',
      localePackId: json['localePackId']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      sourceOwner: json['sourceOwner']?.toString() ?? '',
      reviewStatus: json['reviewStatus']?.toString() ?? '',
    );
  }
}

class _CellResult {
  const _CellResult(this.checked, this.metrics);

  final int checked;
  final Map<String, Object?> metrics;
}

class _PrivacyPattern {
  const _PrivacyPattern(this.name, this.regex);

  final String name;
  final String regex;
}

String _normalizeLine(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/.\-\s]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _equalsIgnoreCase(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

String _title(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

void _count(Map<String, int> counts, String rawKey) {
  final key = rawKey.trim();
  if (key.isEmpty) return;
  counts.update(key, (count) => count + 1, ifAbsent: () => 1);
}

List<String> _filterOrDefault(String csv, List<String> defaults) {
  final requested = csv
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toSet();
  if (requested.isEmpty) return defaults;
  return [
    for (final value in defaults)
      if (requested.contains(value)) value,
  ];
}
