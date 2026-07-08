import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleaned Android receipt camera files do not regain copied import blocks', () {
    const expectedImportsByPath = <String, Set<String>>{
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt': {
        'android.app.Activity',
        'android.os.Bundle',
        'android.view.KeyEvent',
        'android.view.ScaleGestureDetector',
        'android.view.View',
        'android.widget.Button',
        'android.widget.FrameLayout',
        'android.widget.ImageButton',
        'android.widget.ImageView',
        'android.widget.LinearLayout',
        'android.widget.SeekBar',
        'android.widget.TextView',
        'android.window.OnBackInvokedCallback',
        'androidx.camera.core.Camera',
        'androidx.camera.core.ImageCapture',
        'androidx.camera.lifecycle.ProcessCameraProvider',
        'androidx.camera.view.PreviewView',
        'androidx.core.content.ContextCompat',
        'androidx.core.view.WindowCompat',
        'androidx.lifecycle.Lifecycle',
        'androidx.lifecycle.LifecycleOwner',
        'androidx.lifecycle.LifecycleRegistry',
        'java.util.concurrent.Executor',
      },
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysis.kt': {
        'android.hardware.camera2.CaptureRequest',
        'androidx.camera.camera2.interop.Camera2Interop',
        'androidx.camera.camera2.interop.ExperimentalCamera2Interop',
        'android.view.Surface',
        'android.widget.Toast',
        'androidx.camera.core.CameraSelector',
        'androidx.camera.core.ImageAnalysis',
        'androidx.camera.core.ImageCapture',
        'androidx.camera.core.ImageProxy',
        'androidx.camera.core.Preview',
        'androidx.camera.lifecycle.ProcessCameraProvider',
        'kotlin.math.min',
      },
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraCaptureClose.kt':
          {
            'android.os.SystemClock',
            'android.widget.Toast',
            'androidx.camera.core.ImageCapture',
            'androidx.camera.core.ImageCaptureException',
            'java.io.File',
            'java.time.Instant',
          },
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControls.kt': {
        'android.view.MotionEvent',
        'android.view.ScaleGestureDetector',
        'android.view.View',
        'kotlin.math.roundToInt',
      },
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsPayload.kt':
          {},
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsLabels.kt':
          {
            'android.graphics.Color',
            'android.graphics.drawable.GradientDrawable',
            'android.util.Range',
            'android.view.Gravity',
            'android.view.ViewGroup',
            'android.widget.ImageButton',
            'android.widget.LinearLayout',
            'android.widget.TextView',
            'kotlin.math.ceil',
            'kotlin.math.floor',
            'kotlin.math.max',
            'kotlin.math.min',
          },
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraPhotoQuality.kt':
          {
            'android.app.Activity',
            'android.content.Intent',
            'android.graphics.BitmapFactory',
            'androidx.lifecycle.Lifecycle',
            'java.io.File',
          },
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraReviewSettings.kt':
          {
            'android.app.Activity',
            'android.content.Intent',
            'android.os.SystemClock',
            'android.view.View',
            'java.io.File',
            'java.time.Instant',
            'java.util.UUID',
          },
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSessionArguments.kt':
          {
            'android.os.Build',
            'android.window.OnBackInvokedCallback',
            'android.window.OnBackInvokedDispatcher',
          },
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraUiChrome.kt': {
        'android.graphics.Color',
        'android.graphics.Typeface',
        'android.graphics.drawable.GradientDrawable',
        'android.text.TextUtils',
        'android.view.Gravity',
        'android.view.View',
        'android.view.ViewGroup',
        'android.widget.Button',
        'android.widget.FrameLayout',
        'android.widget.ImageButton',
        'android.widget.LinearLayout',
        'android.widget.SeekBar',
        'android.widget.TextView',
        'androidx.camera.view.PreviewView',
        'androidx.core.view.ViewCompat',
        'androidx.core.view.WindowInsetsCompat',
        'androidx.core.view.updateLayoutParams',
        'androidx.core.view.updatePadding',
      },
    };

    for (final entry in expectedImportsByPath.entries) {
      final imports = _kotlinImports(entry.key);
      expect(
        imports,
        entry.value,
        reason:
            '${entry.key} must not regain the generated receipt camera import block.',
      );
    }
  });
}

Set<String> _kotlinImports(String path) {
  final source = File(path).readAsStringSync();
  final importPattern = RegExp(r'^import\s+([^\s]+)', multiLine: true);
  return {
    for (final match in importPattern.allMatches(source)) match.group(1)!,
  };
}
