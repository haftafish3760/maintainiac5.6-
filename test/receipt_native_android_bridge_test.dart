import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test('iOS receipt camera bridge reports the same settings contract', () async {
    final controller = await readIosReceiptCameraUnit();

    expect(controller, contains('AVCaptureSession'));
    expect(controller, contains('AVCapturePhotoOutput'));
    expect(controller, contains('Receipt camera settings'));
    expect(controller, contains('settingsStatusStrip'));
    expect(controller, contains('settingsStatusText'));
    expect(controller, contains('settingsOpenCount += 1'));
    expect(controller, contains('settingsResetCount += 1'));
    expect(controller, contains('"settingsButtonPlacement": "top_bar_right"'));
    expect(
      controller,
      contains('"settingsContractVersion": settingsContractVersion'),
    );
    expect(controller, contains('"settingsOpenCount": settingsOpenCount'));
    expect(controller, contains('"settingsResetCount": settingsResetCount'));
    expect(controller, contains('"settingsControlExpected": true'));
    expect(controller, contains('"visibleControlSet": visibleControlSet()'));
    expect(controller, contains('"settings"'));
    expect(
      controller,
      contains(
        'Maintainiac receipt camera: this uses the phone\'s native camera baseline with Maintainiac receipt workflow controls layered on top.',
      ),
    );
    expect(
      controller,
      contains('arguments["settingsContractVersion"] as? String'),
    );
  });
}
