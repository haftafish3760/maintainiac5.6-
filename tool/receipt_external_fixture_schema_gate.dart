import 'dart:convert';
import 'dart:io';

const _schemaPath =
    'test/fixtures/receipt_qa/receipt_qa_fixture_v1.schema.json';
const _inventoryPath = 'test/fixtures/receipt_qa/fixture_pack_inventory.json';
const _manifestPath = 'tool/receipt_qa_fixture_manifest.dart';
const _schemaId = 'maintainiac.receipt_qa_fixture_v1';
const _schemaName = 'receipt_qa_fixture_v1';
const _inventorySchemaName = 'receipt_qa_fixture_pack_inventory_v1';
const _fixtureRoot = 'test/fixtures/receipt_qa';
const _textPolicy = 'raw_text_allowed_only_in_fixture_files_not_reports';
const _realFixtureStatus = 'schema_ready_no_real_samples';
const _realFixturePrivacyPolicy = 'synthetic_or_redacted_only';
const _artifactPolicy = 'original_capture_preserved_derived_artifacts_separate';
const _externalLoaded = 'external_loaded_schema_validated';
const _plannedPacks = {
  'adjustment',
  'contractor_supply',
  'damaged_ocr',
  'device_tiers',
  'fuel',
  'long_receipt',
  'maintenance',
  'noisy',
  'privacy_admin',
  'retail',
};

void main() {
  final failures = <String>[];
  final schemaFile = File(_schemaPath);
  final inventoryFile = File(_inventoryPath);
  final manifestFile = File(_manifestPath);

  if (!schemaFile.existsSync()) {
    failures.add('Missing external receipt QA fixture schema: $_schemaPath');
  }
  if (!inventoryFile.existsSync()) {
    failures.add('Missing external receipt QA pack inventory: $_inventoryPath');
  }
  if (!manifestFile.existsSync()) {
    failures.add('Missing receipt QA fixture manifest source: $_manifestPath');
  }
  if (failures.isEmpty) {
    _checkSchema(schemaFile, failures);
    _checkInventory(inventoryFile, failures);
    _checkManifest(manifestFile, failures);
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Receipt external fixture schema gate failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Receipt external fixture schema gate: PASS schema=$_schemaName',
  );
}

void _checkSchema(File schemaFile, List<String> failures) {
  final schema = jsonDecode(schemaFile.readAsStringSync());
  if (schema is! Map<String, Object?>) {
    failures.add('Schema root must be a JSON object.');
    return;
  }
  _expectEquals(schema, r'$id', _schemaId, failures);
  _expectEquals(schema, 'type', 'object', failures);
  _expectEquals(schema, 'additionalProperties', false, failures);
  _expectListContainsAll(schema, 'required', [
    'schema',
    'pack',
    'fixtures',
  ], failures);

  final properties = _mapAt(schema, 'properties', failures);
  final schemaProperty = _mapAt(properties, 'schema', failures);
  _expectEquals(schemaProperty, 'const', _schemaName, failures);

  final defs = _mapAt(schema, r'$defs', failures);
  final fixture = _mapAt(defs, 'fixture', failures);
  _expectEquals(fixture, 'additionalProperties', false, failures);
  _expectListContainsAll(fixture, 'required', [
    'name',
    'merchantNeedle',
    'text',
    'expected',
  ], failures);
  final fixtureProperties = _mapAt(fixture, 'properties', failures);
  for (final field in const [
    'fixtureKind',
    'sourcePolicy',
    'redaction',
    'degradationTags',
    'expectedEditable',
    'artifactManifestId',
    'imageArtifacts',
  ]) {
    if (!fixtureProperties.containsKey(field)) {
      failures.add('Fixture schema missing real/synthetic support `$field`.');
    }
  }

  final redaction = _mapAt(defs, 'redaction', failures);
  _expectEquals(redaction, 'additionalProperties', false, failures);
  _expectListContainsAll(redaction, 'required', [
    'status',
    'sensitiveFieldsRemoved',
  ], failures);

  final imageArtifacts = _mapAt(defs, 'imageArtifacts', failures);
  _expectEquals(imageArtifacts, 'additionalProperties', false, failures);
  _expectListContainsAll(imageArtifacts, 'required', [
    'originalPreserved',
    'sourceTruth',
  ], failures);

  final expected = _mapAt(defs, 'expected', failures);
  final expectedProperties = _mapAt(expected, 'properties', failures);
  for (final field in const [
    'merchantName',
    'dateIso',
    'subtotal',
    'tax',
    'total',
    'lineCount',
    'lineCategories',
    'lineFamilies',
    'lineUses',
  ]) {
    if (!expectedProperties.containsKey(field)) {
      failures.add('Expected-field schema missing `$field`.');
    }
  }

  final raw = schema.toString();
  for (final blocked in const [
    'receiptImagePath',
    'sourceImageBytes',
    'rawText',
    'ocrText',
    'cardNumber',
    'customerName',
  ]) {
    if (raw.contains(blocked)) {
      failures.add(
        'Schema must not expose summary/report-only field `$blocked`.',
      );
    }
  }
}

void _checkManifest(File manifestFile, List<String> failures) {
  final manifest = manifestFile.readAsStringSync();
  for (final required in const [
    _schemaName,
    _schemaPath,
    _fixtureRoot,
    _textPolicy,
    'summaryReportExcludes',
    'sourceImageBytes',
  ]) {
    if (!manifest.contains(required)) {
      failures.add('Manifest external fixture plan missing `$required`.');
    }
  }
  for (final pack in _plannedPacks) {
    if (!manifest.contains("'$pack'")) {
      failures.add('Manifest external fixture plan missing pack `$pack`.');
    }
  }
  if (!manifest.contains(
    "pack: '\$_receiptQaExternalFixtureRoot/\$pack.json'",
  )) {
    failures.add('Manifest external fixture plan must derive pack JSON paths.');
  }
}

void _checkInventory(File inventoryFile, List<String> failures) {
  final inventory = jsonDecode(inventoryFile.readAsStringSync());
  if (inventory is! Map<String, Object?>) {
    failures.add('Inventory root must be a JSON object.');
    return;
  }
  _expectEquals(inventory, 'schema', _inventorySchemaName, failures);
  _expectEquals(inventory, 'fixtureSchema', _schemaName, failures);
  _expectEquals(inventory, 'fixtureRoot', _fixtureRoot, failures);
  _expectEquals(inventory, 'textPolicy', _textPolicy, failures);
  _expectEquals(inventory, 'externalFixtureFilesReady', true, failures);
  final realFixtureSupport = _mapAt(inventory, 'realFixtureSupport', failures);
  _expectEquals(realFixtureSupport, 'status', _realFixtureStatus, failures);
  _expectEquals(
    realFixtureSupport,
    'privacyPolicy',
    _realFixturePrivacyPolicy,
    failures,
  );
  _expectEquals(realFixtureSupport, 'expectedOutputsEditable', true, failures);
  _expectEquals(
    realFixtureSupport,
    'sensitiveThirdPartyDataAllowed',
    false,
    failures,
  );
  _expectEquals(
    realFixtureSupport,
    'artifactPolicy',
    _artifactPolicy,
    failures,
  );

  final packs = _mapAt(inventory, 'packs', failures);
  final actualPacks = packs.keys.toSet();
  if (actualPacks.length != _plannedPacks.length ||
      !actualPacks.containsAll(_plannedPacks)) {
    failures.add(
      'Inventory packs must exactly match planned packs: '
      '${_plannedPacks.join(', ')}.',
    );
  }
  for (final pack in _plannedPacks) {
    final packEntry = _mapAt(packs, pack, failures);
    final expectedPath = '$_fixtureRoot/$pack.json';
    _expectEquals(packEntry, 'file', expectedPath, failures);
    _expectEquals(packEntry, 'status', _externalLoaded, failures);
    _checkExternalPack(File(expectedPath), pack, packEntry, failures);
  }

  final raw = inventory.toString();
  for (final blocked in const [
    'MERCH TOTAL',
    'LOWE',
    'cardNumber',
    'sourceImageBytes',
    'receiptImagePath',
  ]) {
    if (raw.contains(blocked)) {
      failures.add('Inventory must not contain raw receipt token `$blocked`.');
    }
  }
}

void _checkExternalPack(
  File file,
  String expectedPack,
  Map<String, Object?> inventoryEntry,
  List<String> failures,
) {
  if (!file.existsSync()) {
    failures.add('Externally loaded pack is missing: ${file.path}.');
    return;
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    failures.add('External pack root must be an object: ${file.path}.');
    return;
  }
  _expectEquals(decoded, 'schema', _schemaName, failures);
  _expectEquals(decoded, 'pack', expectedPack, failures);
  final fixtures = decoded['fixtures'];
  if (fixtures is! List || fixtures.isEmpty) {
    failures.add('External pack fixtures must be non-empty: ${file.path}.');
    return;
  }
  _expectEquals(inventoryEntry, 'fixtureCount', fixtures.length, failures);
  for (var index = 0; index < fixtures.length; index++) {
    final fixture = fixtures[index];
    if (fixture is! Map<String, Object?>) {
      failures.add('$expectedPack fixture $index must be an object.');
      continue;
    }
    for (final key in const ['name', 'merchantNeedle', 'text', 'expected']) {
      if (!fixture.containsKey(key)) {
        failures.add('$expectedPack fixture $index is missing `$key`.');
      }
    }
    _expectEquals(fixture, 'sourcePolicy', _realFixturePrivacyPolicy, failures);
    final redaction = _mapAt(fixture, 'redaction', failures);
    _expectEquals(redaction, 'sensitiveFieldsRemoved', true, failures);
    _expectEquals(fixture, 'expectedEditable', true, failures);
  }
}

Map<String, Object?> _mapAt(
  Map<String, Object?> parent,
  String key,
  List<String> failures,
) {
  final value = parent[key];
  if (value is Map<String, Object?>) return value;
  failures.add('Expected `$key` to be a JSON object.');
  return const {};
}

void _expectEquals(
  Map<String, Object?> parent,
  String key,
  Object? expected,
  List<String> failures,
) {
  if (parent[key] != expected) {
    failures.add('Expected `$key` to equal `$expected`, got `${parent[key]}`.');
  }
}

void _expectListContainsAll(
  Map<String, Object?> parent,
  String key,
  List<String> expected,
  List<String> failures,
) {
  final value = parent[key];
  if (value is! List<Object?>) {
    failures.add('Expected `$key` to be a JSON list.');
    return;
  }
  for (final item in expected) {
    if (!value.contains(item)) {
      failures.add('Expected `$key` to contain `$item`.');
    }
  }
}
