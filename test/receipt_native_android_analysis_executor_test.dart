import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test('Android receipt analysis stays off the UI thread', () async {
    final camera =
        (await readAndroidReceiptCameraBridgeSources()).cameraActivity;

    expect(camera, contains('Executors.newSingleThreadExecutor()'));
    expect(camera, contains('setAnalyzer(cameraAnalysisExecutor)'));
    expect(camera, isNot(contains('setAnalyzer(mainExecutor())')));
    expect(camera, contains('sampleLiveLumaGrid(image)'));
    expect(camera, contains('estimateReceiptFraming(image)'));
    expect(
      camera,
      contains('mainExecutor().execute { applyAnalyzedLiveFrame(signals) }'),
    );
    expect(camera, contains('finally {\n        image.close()'));
    expect(camera, contains('cameraAnalysisExecutor.shutdownNow()'));
  });
}
