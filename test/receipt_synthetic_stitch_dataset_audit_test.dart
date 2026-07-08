import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('synthetic stitch dataset manifest template documents safe contract', () {
    final template = File(
      'test/fixtures/receipt_qa/synthetic_stitch_dataset_manifest.template.json',
    );
    expect(template.existsSync(), isTrue);
    final decoded = jsonDecode(template.readAsStringSync()) as Map;

    expect(
      decoded['schema'],
      'maintainiac_synthetic_receipt_stitch_dataset_v1',
    );
    expect(decoded['expectedReceiptCount'], 10000);
    expect(decoded['commercialSafeOriginalGenerationOnly'], isTrue);
    expect(decoded['containsRealReceipts'], isFalse);
    expect(decoded['containsCopyrightedReceipts'], isFalse);
    expect(decoded['containsLogosOrTrademarks'], isFalse);
    expect(decoded['containsRealAddressesOrPhones'], isFalse);
    expect(decoded['requiredCaptureSetsPerReceipt'], [2, 3, 4, 5]);
    expect((decoded['lengthClassItemRanges'] as Map)['extreme'], [150, 300]);
  });

  test(
    'synthetic stitch dataset audit accepts generated original manifest',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_synthetic_stitch_dataset_',
      );
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      _writeSyntheticDatasetFiles(root);
      final manifest = File('${root.path}/manifest.json')
        ..writeAsStringSync(jsonEncode(_validManifest()));

      final result = await _runAudit(manifest);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(
        result.stdout.toString(),
        contains('Receipt synthetic stitch dataset audit: PASS'),
      );
    },
  );

  test(
    'synthetic stitch dataset audit rejects unsafe receipt sources',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_synthetic_stitch_dataset_bad_',
      );
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      _writeSyntheticDatasetFiles(root);
      final manifestData = _validManifest()
        ..['containsRealReceipts'] = true
        ..['containsLogosOrTrademarks'] = true;
      final manifest = File('${root.path}/manifest.json')
        ..writeAsStringSync(jsonEncode(manifestData));

      final result = await _runAudit(manifest);

      expect(result.exitCode, 1);
      expect(result.stderr.toString(), contains('containsRealReceipts'));
      expect(result.stderr.toString(), contains('containsLogosOrTrademarks'));
    },
  );

  test(
    'synthetic stitch dataset audit rejects incomplete capture sets',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_synthetic_stitch_dataset_incomplete_',
      );
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      _writeSyntheticDatasetFiles(root);
      final manifestData = _validManifest();
      final receipt = (manifestData['receipts'] as List).first as Map;
      receipt['captures'] = (receipt['captures'] as List).take(1).toList();
      final manifest = File('${root.path}/manifest.json')
        ..writeAsStringSync(jsonEncode(manifestData));

      final result = await _runAudit(manifest);

      expect(result.exitCode, 1);
      expect(
        result.stderr.toString(),
        contains('captures must contain 2, 3, 4, and 5 image sets'),
      );
    },
  );

  test(
    'synthetic stitch dataset audit enforces receipt length classes',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_synthetic_stitch_dataset_length_',
      );
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      _writeSyntheticDatasetFiles(root);
      final manifestData = _validManifest();
      final receipt = (manifestData['receipts'] as List).first as Map;
      receipt['lengthClass'] = 'extreme';
      final manifest = File('${root.path}/manifest.json')
        ..writeAsStringSync(jsonEncode(manifestData));

      final result = await _runAudit(manifest);

      expect(result.exitCode, 1);
      expect(result.stderr.toString(), contains('extreme receipts must have'));
    },
  );

  test('synthetic stitch dataset audit rejects weak stitch metadata', () async {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_synthetic_stitch_dataset_stress_',
    );
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    _writeSyntheticDatasetFiles(root);
    final manifestData = _validManifest();
    final receipt = (manifestData['receipts'] as List).first as Map;
    receipt.remove('degradationTags');
    final capture = (receipt['captures'] as List).first as Map;
    capture['expectedOverlaps'] = [
      {'fromIndex': 0, 'toIndex': 3, 'overlapPercent': 95, 'overlapPixels': 0},
    ];
    final manifest = File('${root.path}/manifest.json')
      ..writeAsStringSync(jsonEncode(manifestData));

    final result = await _runAudit(manifest);

    expect(result.exitCode, 1);
    expect(result.stderr.toString(), contains('degradationTags'));
    expect(result.stderr.toString(), contains('adjacent images'));
    expect(result.stderr.toString(), contains('overlapPercent'));
    expect(result.stderr.toString(), contains('overlapPixels'));
  });

  test(
    'synthetic stitch dataset audit rejects unordered capture transforms',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'maintainiac_synthetic_stitch_dataset_transform_',
      );
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });
      _writeSyntheticDatasetFiles(root);
      final manifestData = _validManifest();
      final receipt = (manifestData['receipts'] as List).first as Map;
      final capture = (receipt['captures'] as List).first as Map;
      final images = capture['images'] as List;
      final firstImage = images.first as Map;
      firstImage['index'] = 1;
      firstImage['transform'] = {'jpegQuality': 10};
      capture['expectedImageOrdering'] = [0, 0];
      final manifest = File('${root.path}/manifest.json')
        ..writeAsStringSync(jsonEncode(manifestData));

      final result = await _runAudit(manifest);

      expect(result.exitCode, 1);
      expect(result.stderr.toString(), contains('preserve segment order'));
      expect(result.stderr.toString(), contains('duplicate 0'));
      expect(result.stderr.toString(), contains('rotationDegrees'));
      expect(result.stderr.toString(), contains('jpegQuality'));
      expect(result.stderr.toString(), contains('lightingProfile'));
    },
  );
}

Future<ProcessResult> _runAudit(File manifest) {
  return Process.run('dart', [
    'tool/receipt_synthetic_stitch_dataset_audit.dart',
    manifest.path,
  ]);
}

void _writeSyntheticDatasetFiles(Directory root) {
  for (final path in _fixturePaths()) {
    final file = File('${root.path}/$path')..createSync(recursive: true);
    file.writeAsBytesSync([1, 2, 3, 4]);
  }
}

List<String> _fixturePaths() => [
  'receipts/r001/original.jpg',
  'receipts/r001/expected_stitched.jpg',
  for (final count in [2, 3, 4, 5])
    for (var index = 0; index < count; index++)
      'receipts/r001/${count}_part_$index.jpg',
];

Map<String, Object?> _validManifest() => {
  'schema': 'maintainiac_synthetic_receipt_stitch_dataset_v1',
  'expectedReceiptCount': 1,
  'commercialSafeOriginalGenerationOnly': true,
  'containsRealReceipts': false,
  'containsCopyrightedReceipts': false,
  'containsLogosOrTrademarks': false,
  'containsRealAddressesOrPhones': false,
  'generationPolicy': {
    'businessNames': 'fictional_only',
    'items': 'fictional_or_generic_only',
    'images': 'procedurally_generated_only',
  },
  'receipts': [
    {
      'id': 'r001',
      'lengthClass': 'long',
      'originalReceiptPath': 'receipts/r001/original.jpg',
      'expectedStitchedPath': 'receipts/r001/expected_stitched.jpg',
      'degradationTags': ['wrinkles', 'rotation', 'uneven_lighting'],
      'groundTruth': {
        'storeName': 'Blue Ridge Tool Depot',
        'items': [
          for (var index = 0; index < 80; index++)
            {'description': 'Synthetic Item $index', 'price': 2.48},
        ],
        'subtotal': 2.48,
        'tax': 0.13,
        'total': 2.61,
        'ocrText': 'BLUE RIDGE TOOL DEPOT\nCOPPER ELBOW HALF INCH 2.48',
      },
      'captures': [
        for (final count in [2, 3, 4, 5])
          {
            'imageCount': count,
            'images': [
              for (var index = 0; index < count; index++)
                {
                  'index': index,
                  'path': 'receipts/r001/${count}_part_$index.jpg',
                  'transform': _captureTransform(index),
                },
            ],
            'expectedImageOrdering': [
              for (var index = 0; index < count; index++) index,
            ],
            'expectedOverlaps': [
              for (var index = 0; index < count - 1; index++)
                {
                  'fromIndex': index,
                  'toIndex': index + 1,
                  'overlapPercent': 18,
                  'overlapPixels': 270,
                },
            ],
          },
      ],
    },
  ],
};

Map<String, Object?> _captureTransform(int index) => {
  'rotationDegrees': index.isEven ? -2.5 : 3.0,
  'scale': 1.0,
  'perspectiveX': index.isEven ? -0.04 : 0.05,
  'perspectiveY': index.isEven ? 0.03 : -0.02,
  'blurRadius': index == 0 ? 0.8 : 1.4,
  'motionBlurPixels': index == 0 ? 0 : 2,
  'jpegQuality': 82,
  'brightnessDelta': index.isEven ? -0.08 : 0.06,
  'shadowStrength': index.isEven ? 0.18 : 0.05,
  'glareStrength': index.isEven ? 0.02 : 0.12,
  'lightingProfile': index.isEven ? 'shadowed' : 'uneven',
};
