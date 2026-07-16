import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual receipt edits retain original evidence until review is safe', () {
    final edits = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
    ).readAsStringSync();
    final cleanup = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart',
    ).readAsStringSync();
    final save = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsStringSync();

    expect(edits, contains("updatedDiagnostics['userEditedPhoto'] = true"));
    expect(
      edits,
      contains("updatedDiagnostics['photoEditReplacedOriginal'] = previousPath != path"),
    );
    expect(
      cleanup,
      contains('final generatedPaths = _generatedEditPaths.toList'),
    );
    expect(cleanup, isNot(contains('File(previousPath).delete')));
    expect(
      save,
      contains('_generatedEditPaths.isEmpty'),
      reason:
          'Only an unedited photo may bypass the persistence/preparation route.',
    );
  });
}
