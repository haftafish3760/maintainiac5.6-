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
  final lengthClass = _expectOneOf(
    receipt,
    'lengthClass',
    _lengthClassRanges.keys.toSet(),
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
  _expectDegradationTags(receipt, failures, prefix);

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
    } else if (lengthClass != null) {
      final range = _lengthClassRanges[lengthClass]!;
      if (items.length < range.min || items.length > range.max) {
        failures.add(
          '$prefix $lengthClass receipts must have ${range.min}-${range.max} '
          'items, found ${items.length}.',
        );
      }
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
    final order = _auditExpectedOrder(capture, count, failures, prefix);
    final images = capture['images'];
    if (images is! List || images.length != count) {
      failures.add(
        '$prefix capture $count images length must equal imageCount.',
      );
    } else {
      for (var imageIndex = 0; imageIndex < images.length; imageIndex++) {
        final image = images[imageIndex];
        if (image is Map<String, Object?>) {
          _auditCaptureImage(
            manifestDir,
            image,
            imageIndex,
            order,
            failures,
            prefix,
          );
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
    } else {
      _auditOverlaps(overlaps, count, failures, prefix);
    }
  }
  if (!seenCounts.containsAll(const {2, 3, 4, 5})) {
    failures.add('$prefix captures must include imageCount 2, 3, 4, and 5.');
  }
}

Set<int> _auditExpectedOrder(
  Map<String, Object?> capture,
  int count,
  List<String> failures,
  String prefix,
) {
  final order = capture['expectedImageOrdering'];
  final values = <int>{};
  if (order is! List || order.length != count) {
    failures.add(
      '$prefix capture $count expectedImageOrdering length mismatch.',
    );
    return values;
  }
  for (var index = 0; index < order.length; index++) {
    final value = order[index];
    if (value is! int || value < 0 || value >= count) {
      failures.add(
        '$prefix capture $count expectedImageOrdering[$index] is invalid.',
      );
      continue;
    }
    if (!values.add(value)) {
      failures.add(
        '$prefix capture $count expectedImageOrdering has duplicate $value.',
      );
    }
  }
  for (var index = 0; index < count; index++) {
    if (!values.contains(index)) {
      failures.add(
        '$prefix capture $count expectedImageOrdering missing image $index.',
      );
    }
  }
  return values;
}

void _auditCaptureImage(
  Directory manifestDir,
  Map<String, Object?> image,
  int imageIndex,
  Set<int> expectedOrder,
  List<String> failures,
  String prefix,
) {
  _expectRelativeFile(manifestDir, image, 'path', failures, prefix);
  final index = image['index'];
  if (index is! int) {
    failures.add('$prefix capture image $imageIndex index must be an int.');
  } else {
    if (index != imageIndex) {
      failures.add(
        '$prefix capture image $imageIndex index must preserve segment order.',
      );
    }
    if (expectedOrder.isNotEmpty && !expectedOrder.contains(index)) {
      failures.add(
        '$prefix capture image $imageIndex index must appear in ordering.',
      );
    }
  }
  final transform = image['transform'];
  if (transform is! Map<String, Object?>) {
    failures.add('$prefix capture image $imageIndex transform must be object.');
    return;
  }
  _expectNumber(transform, 'rotationDegrees', -45, 45, failures, prefix);
  _expectNumber(transform, 'scale', 0.6, 1.4, failures, prefix);
  _expectNumber(transform, 'perspectiveX', -0.35, 0.35, failures, prefix);
  _expectNumber(transform, 'perspectiveY', -0.35, 0.35, failures, prefix);
  _expectNumber(transform, 'blurRadius', 0, 12, failures, prefix);
  _expectNumber(transform, 'motionBlurPixels', 0, 80, failures, prefix);
  _expectNumber(transform, 'jpegQuality', 30, 100, failures, prefix);
  _expectNumber(transform, 'brightnessDelta', -1, 1, failures, prefix);
  _expectNumber(transform, 'shadowStrength', 0, 1, failures, prefix);
  _expectNumber(transform, 'glareStrength', 0, 1, failures, prefix);
  _expectOneOf(
    transform,
    'lightingProfile',
    _allowedLightingProfiles,
    failures,
    prefix,
  );
}

void _expectDegradationTags(
  Map<String, Object?> receipt,
  List<String> failures,
  String prefix,
) {
  final tags = receipt['degradationTags'];
  if (tags is! List || tags.isEmpty) {
    failures.add('$prefix degradationTags must be a non-empty list.');
    return;
  }
  final normalized = <String>{};
  for (final tag in tags) {
    final value = _stringValue(tag);
    if (value == null || value.isEmpty) {
      failures.add(
        '$prefix degradationTags must contain only non-empty strings.',
      );
      continue;
    }
    normalized.add(value);
  }
  if (!normalized.any(_requiredStitchStressTags.contains)) {
    failures.add(
      '$prefix degradationTags must include at least one stitch stress tag: '
      '${_requiredStitchStressTags.join(', ')}.',
    );
  }
}

void _auditOverlaps(
  List<Object?> overlaps,
  int imageCount,
  List<String> failures,
  String prefix,
) {
  for (var index = 0; index < overlaps.length; index++) {
    final overlap = overlaps[index];
    if (overlap is! Map<String, Object?>) {
      failures.add('$prefix overlap $index must be an object.');
      continue;
    }
    final fromIndex = overlap['fromIndex'];
    final toIndex = overlap['toIndex'];
    if (fromIndex is! int || toIndex is! int || toIndex != fromIndex + 1) {
      failures.add('$prefix overlap $index must connect adjacent images.');
    }
    if (fromIndex is int && (fromIndex < 0 || fromIndex >= imageCount - 1)) {
      failures.add('$prefix overlap $index fromIndex is outside image range.');
    }
    if (toIndex is int && (toIndex < 1 || toIndex >= imageCount)) {
      failures.add('$prefix overlap $index toIndex is outside image range.');
    }
    final percent = overlap['overlapPercent'];
    if (percent is! num || percent <= 0 || percent >= 60) {
      failures.add(
        '$prefix overlap $index overlapPercent must be > 0 and < 60.',
      );
    }
    final pixels = overlap['overlapPixels'];
    if (pixels is! int || pixels <= 0) {
      failures.add('$prefix overlap $index overlapPixels must be positive.');
    }
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

String? _expectOneOf(
  Map<String, Object?> map,
  String key,
  Set<String> allowed,
  List<String> failures,
  String prefix,
) {
  final value = _stringValue(map[key]);
  if (value == null || !allowed.contains(value)) {
    failures.add('$prefix $key must be one of ${allowed.join(', ')}.');
    return null;
  }
  return value;
}

void _expectNumber(
  Map<String, Object?> map,
  String key,
  num min,
  num max,
  List<String> failures,
  String prefix,
) {
  final value = map[key];
  if (value is! num || value < min || value > max) {
    failures.add('$prefix $key must be numeric from $min to $max.');
  }
}

String? _stringValue(Object? value) => value is String ? value.trim() : null;

const _lengthClassRanges = <String, _IntRange>{
  'very_short': _IntRange(8, 15),
  'short': _IntRange(15, 35),
  'medium': _IntRange(35, 75),
  'long': _IntRange(75, 150),
  'extreme': _IntRange(150, 300),
};

const _requiredStitchStressTags = <String>{
  'curl',
  'wrinkles',
  'folds',
  'tears',
  'stains',
  'smudges',
  'camera_blur',
  'motion_blur',
  'jpeg_compression',
  'perspective_distortion',
  'rotation',
  'shadows',
  'low_light',
  'flash_glare',
  'uneven_lighting',
  'noise',
};

const _allowedLightingProfiles = <String>{
  'normal',
  'low_light',
  'uneven',
  'flash_glare',
  'shadowed',
};

class _IntRange {
  const _IntRange(this.min, this.max);

  final int min;
  final int max;
}
