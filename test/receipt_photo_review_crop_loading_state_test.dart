import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crop loading and recovery states are clear and non-crashing', () async {
    final surface = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_surfaces.dart',
    ).readAsString();
    final actions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
    ).readAsString();

    expect(surface, contains("'Opening crop tools…'"));
    expect(surface, contains('CircularProgressIndicator()'));
    expect(actions, contains('} catch (_) {\n      bytes = Uint8List(0);'));
    expect(
      actions,
      contains("'This receipt photo could not be loaded for cropping.'"),
    );
  });
}
