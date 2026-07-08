import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final manifestPath = args.isNotEmpty
      ? args.first
      : Platform.environment['RECEIPT_SYNTHETIC_STITCH_MANIFEST'];
  final failures = <String>[];
  if (manifestPath == null || manifestPath.trim().isEmpty) {
    failures.add(
      'Provide a synthetic stitch dataset manifest path as arg0 or '
      'RECEIPT_SYNTHETIC_STITCH_MANIFEST.',
    );
  } else {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      failures.add('Missing synthetic stitch dataset manifest: $manifestPath');
    } else {
      _auditManifest(file, failures);
    }
  }

  if (failures.isNotEmpty) {
    stderr.writeln('Receipt synthetic stitch dataset audit failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln('Receipt synthetic stitch dataset audit: PASS');
}

void _auditManifest(File file, List<String> failures) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    failures.add('Manifest root must be an object.');
    return;
  }
  _expectString(
    decoded,
    'schema',
    'maintainiac_synthetic_receipt_stitch_dataset_v1',
    failures,
  );
  _expectBool(decoded, 'commercialSafeOriginalGenerationOnly', true, failures);
  _expectBool(decoded, 'containsRealReceipts', false, failures);
  _expectBool(decoded, 'containsCopyrightedReceipts', false, failures);
  _expectBool(decoded, 'containsLogosOrTrademarks', false, failures);
  _expectBool(decoded, 'containsRealAddressesOrPhones', false, failures);

  final policy = decoded['generationPolicy'];
  if (policy is! Map<String, Object?>) {
    failures.add('generationPolicy must be an object.');
  } else {
    _expectString(policy, 'businessNames', 'fictional_only', failures);
    _expectString(policy, 'items', 'fictional_or_generic_only', failures);
    _expectString(policy, 'images', 'procedurally_generated_only', failures);
  }

  final receipts = decoded['receipts'];
  if (receipts is! List) {
    failures.add('receipts must be a list.');
    return;
  }
  if (receipts.isEmpty) {
    failures.add('receipts must not be empty.');
  }
  final expectedCount = decoded['expectedReceiptCount'];
  if (expectedCount is int && expectedCount != receipts.length) {
    failures.add(
      'expectedReceiptCount $expectedCount does not match receipts length '
      '${receipts.length}.',
    );
  }
  for (var index = 0; index < receipts.length; index++) {
    final receipt = receipts[index];
    if (receipt is! Map<String, Object?>) {
      failures.add('receipts[$index] must be an object.');
      continue;
    }
    _auditReceipt(file.parent, receipt, index, failures);
  }
}

void _auditReceipt(
  Directory manifestDir,
  Map<String, Object?> receipt,
  int index,
  List<String> failures,
) {
  final id = _stringValue(receipt['id']);
  final prefix = id == null ? 'receipts[$index]' : 'receipt $id';
  if (id == null || id.isEmpty) failures.add('$prefix needs non-empty id.');
  _expectOneOf(
    receipt,
    'lengthClass',
    const {'very_short', 'short', 'medium', 'long', 'extreme'},
    failures,
    prefix,
  );
  _expectRelativeFile(
    manifestDir,
    receipt,
    'originalReceiptPath',
    failures,
    prefix,
  );
  _expectRelativeFile(
    manifestDir,
    receipt,
    'expectedStitchedPath',
    failures,
    prefix,
  );

  final groundTruth = receipt['groundTruth'];
  if (groundTruth is! Map<String, Object?>) {
    failures.add('$prefix groundTruth must be an object.');
  } else {
    for (final key in const [
      'storeName',
      'subtotal',
      'tax',
      'total',
      'ocrText',
    ]) {
      if (!groundTruth.containsKey(key)) {
        failures.add('$prefix groundTruth missing $key.');
      }
    }
    final items = groundTruth['items'];
    if (items is! List || items.isEmpty) {
      failures.add('$prefix groundTruth.items must be a non-empty list.');
    }
  }

  final captures = receipt['captures'];
  if (captures is! List || captures.length != 4) {
    failures.add('$prefix captures must contain 2, 3, 4, and 5 image sets.');
    return;
  }
  final seenCounts = <int>{};
  for (final capture in captures) {
    if (capture is! Map<String, Object?>) {
      failures.add('$prefix capture entries must be objects.');
      continue;
    }
    final count = capture['imageCount'];
    if (count is! int) {
      failures.add('$prefix capture.imageCount must be an int.');
      continue;
    }
    seenCounts.add(count);
    if (count < 2 || count > 5) {
      failures.add('$prefix capture.imageCount must be 2, 3, 4, or 5.');
    }
    final images = capture['images'];
    if (images is! List || images.length != count) {
      failures.add(
        '$prefix capture $count images length must equal imageCount.',
      );
    } else {
      for (final image in images) {
        if (image is Map<String, Object?>) {
          _expectRelativeFile(manifestDir, image, 'path', failures, prefix);
        } else {
          failures.add('$prefix capture $count images must be objects.');
        }
      }
    }
    final overlaps = capture['expectedOverlaps'];
    if (overlaps is! List || overlaps.length != count - 1) {
      failures.add(
        '$prefix capture $count expectedOverlaps must have ${count - 1} entries.',
      );
    }
    final order = capture['expectedImageOrdering'];
    if (order is! List || order.length != count) {
      failures.add(
        '$prefix capture $count expectedImageOrdering length mismatch.',
      );
    }
  }
  if (!seenCounts.containsAll(const {2, 3, 4, 5})) {
    failures.add('$prefix captures must include imageCount 2, 3, 4, and 5.');
  }
}

void _expectRelativeFile(
  Directory manifestDir,
  Map<String, Object?> map,
  String key,
  List<String> failures,
  String prefix,
) {
  final value = _stringValue(map[key]);
  if (value == null || value.isEmpty) {
    failures.add('$prefix missing $key.');
    return;
  }
  if (value.startsWith('/') || value.contains('..')) {
    failures.add('$prefix $key must be a relative path without traversal.');
    return;
  }
  if (!File('${manifestDir.path}/$value').existsSync()) {
    failures.add('$prefix $key file missing: $value.');
  }
}

void _expectString(
  Map<String, Object?> map,
  String key,
  String expected,
  List<String> failures,
) {
  if (map[key] != expected) failures.add('$key must be $expected.');
}

void _expectBool(
  Map<String, Object?> map,
  String key,
  bool expected,
  List<String> failures,
) {
  if (map[key] != expected) failures.add('$key must be $expected.');
}

void _expectOneOf(
  Map<String, Object?> map,
  String key,
  Set<String> allowed,
  List<String> failures,
  String prefix,
) {
  final value = _stringValue(map[key]);
  if (value == null || !allowed.contains(value)) {
    failures.add('$prefix $key must be one of ${allowed.join(', ')}.');
  }
}

String? _stringValue(Object? value) => value is String ? value.trim() : null;
