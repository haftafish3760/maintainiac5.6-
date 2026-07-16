import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'an already-open native camera keeps its existing receipt session',
    () async {
      final flow = await File(
        'lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart',
      ).readAsString();

      expect(
        flow,
        contains('on ReceiptNativeCameraBusyException catch (error)'),
      );
      expect(flow, contains('ReceiptCaptureFlowResult.canceled('));
      expect(flow, contains("reason: 'native_camera_already_open'"));
      expect(
        flow,
        contains(
          "'nativeCaptureFallbackPolicy': 'keep_existing_camera_session'",
        ),
      );
      expect(
        flow,
        contains("'userNextStep': 'finish_or_cancel_the_open_receipt_camera'"),
      );
    },
  );
}
