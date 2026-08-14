import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stitching bounds private camera working copies before crop and combine', () async {
    final api = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart',
    ).readAsString();
    final resize = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_resize_helpers.dart',
    ).readAsString();
    final sources = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_sources.dart',
    ).readAsString();
    final helpers = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_helpers.dart',
    ).readAsString();
    final support = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_support.dart',
    ).readAsString();
    final fastPath = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_fast_path.dart',
    ).readAsString();

    expect(api, contains('maxTargetWidth: maxTargetWidth'));
    expect(api, contains('allowUprightFastPath: true'));
    expect(support, contains('receiptStitchTextSafelyAcceleratesGeometry('));
    expect(helpers, contains('bool allowUprightFastPath = false'));
    expect(helpers, contains('final uprightFastPath = allowUprightFastPath'));
    expect(fastPath, contains('continuity.isProven'));
    expect(
      fastPath,
      contains('_receiptGeometryEvidenceSupportsCandidate(geometry)'),
    );
    expect(fastPath, contains('final materializedGeometry ='));
    expect(
      fastPath,
      contains(
        '_receiptGeometryEvidenceSupportsCandidate(materializedGeometry)',
      ),
    );
    expect(
      api,
      contains('final evidenceDecision = evaluateReceiptStitchEvidence('),
    );
    expect(
      sources,
      contains('final workingWidth = _stitchWorkingWidth(targetWidth);'),
    );
    expect(
      sources,
      contains('_resizeForStitchWorkingWidth(upright, workingWidth)'),
    );
    expect(sources, contains('final effectiveTargetWidth = decoded'));
    expect(sources, contains('.fold(targetWidth, math.min)'));
    expect(
      sources,
      contains('_resizeToWidth(image, effectiveTargetWidth)'),
      reason: 'The stitcher must never enlarge a lower-resolution receipt.',
    );
    expect(sources, contains('final sourceHashes = <String>[];'));
    expect(sources, isNot(contains('decodedSources.add(upright)')));
    expect(
      sources,
      contains('User source\n    // photos remain unchanged'),
      reason: 'The performance bound must not silently alter saved originals.',
    );
    expect(
      resize,
      contains(
        'int _stitchTargetWidth(int photoCount, {int maxTargetWidth = 1400})',
      ),
    );
    expect(resize, contains('math.min(desired, maxTargetWidth)'));
    expect(
      resize,
      contains('if (source.width <= workingWidth) return source;'),
    );
  });
}
