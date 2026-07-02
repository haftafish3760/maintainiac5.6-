import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS receipt camera bridge is wired to custom AVFoundation controller',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final appDelegate = sources.appDelegate;
      final cameraController = sources.cameraController;
      final xcodeProject = sources.xcodeProject;

      expect(appDelegate, contains('maintainiac/receipt_camera'));
      expect(appDelegate, contains('ReceiptCameraViewController'));
      expect(cameraController, contains('AVCaptureSession'));
      expect(cameraController, contains('AVCapturePhotoOutput'));
      expect(cameraController, isNot(contains('UIImagePickerController')));
      expect(xcodeProject, contains('ReceiptCameraViewController.swift'));
    },
  );
}
