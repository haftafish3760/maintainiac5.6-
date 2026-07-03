import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_catalog_item_batch_status.dart';

void main() {
  test('item batch status reports present, missing, and resume cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_item_batch_status_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeManifest(
      'blueprints/work_supply_catalog/plumbing/residential/core/en-US',
      {
        'trade': 'plumbing',
        'marketScope': 'residential',
        'tier': 'core',
        'localePackId': 'en-US',
        'requestedLimit': 500,
        'generatedCount': 500,
        'promotionMode': 'review-required',
        'writesProductionCatalog': false,
        'liveServicesAllowed': false,
        'firebaseWritesAllowed': false,
      },
    );

    final stdout = _MemorySink();
    final exit = runWorkSupplyCatalogItemBatchStatus(
      const [
        '--blueprint-root',
        'blueprints',
        '--trades',
        'plumbing',
        '--scopes',
        'residential',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--output',
        'reports/item_batch_status.json',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_CATALOG_ITEM_BATCH_STATUS'));
    final status = _readJson('reports/item_batch_status.json');
    expect(status['expectedCells'], 2);
    expect(status['presentCells'], 1);
    expect(status['missingCells'], 1);
    expect(status['unsafeCells'], 0);
    expect(status['generatedItemCount'], 500);
    expect(status['manualReviewRequiredCells'], 1);
    expect(status['liveServicesAllowed'], isFalse);
    expect(status['writesProductionCatalog'], isFalse);
    expect(status['firebaseWritesAllowed'], isFalse);
    expect(status['ocrCameraExpensesTouched'], isFalse);
    expect(
      status.toString(),
      contains('work_supply_catalog_blueprint_generator.dart'),
    );
  });

  test('item batch status fails incomplete required matrices', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_item_batch_required_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    final exit = runWorkSupplyCatalogItemBatchStatus(
      const [
        '--blueprint-root',
        'blueprints',
        '--trades',
        'plumbing',
        '--tiers',
        'core',
        '--locales',
        'en-US',
        '--require-complete',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 2);
  });

  test('item batch status blocks unsafe blueprint manifests', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_item_batch_unsafe_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    _writeManifest(
      'blueprints/work_supply_catalog/hvac/residential/core/en-US',
      {
        'trade': 'hvac',
        'marketScope': 'residential',
        'tier': 'core',
        'localePackId': 'en-US',
        'requestedLimit': 50,
        'generatedCount': 50,
        'promotionMode': 'review-required',
        'writesProductionCatalog': false,
        'liveServicesAllowed': true,
        'firebaseWritesAllowed': false,
      },
    );

    final exit = runWorkSupplyCatalogItemBatchStatus(
      const [
        '--blueprint-root',
        'blueprints',
        '--trades',
        'hvac',
        '--tiers',
        'core',
        '--locales',
        'en-US',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
  });
}

void _writeManifest(String root, Map<String, Object?> manifest) {
  final directory = Directory(root)..createSync(recursive: true);
  File(
    '${directory.path}/manifest.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  File('${directory.path}/item_blueprints.json').writeAsStringSync('[]');
}

Map<String, Object?> _readJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
