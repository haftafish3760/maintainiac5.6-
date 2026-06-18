part of 'receipt_camera_screen.dart';

extension _ReceiptCameraSetup on _ReceiptCameraScreenState {
  Future<CameraController> _createInitializedController(
    CameraDescription camera,
  ) async {
    CameraException? lastCameraError;
    Object? lastOtherError;
    for (final preset in const [
      ResolutionPreset.max,
      ResolutionPreset.high,
      ResolutionPreset.medium,
    ]) {
      final controller = CameraController(
        camera,
        preset,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      try {
        await controller.initialize();
        return controller;
      } on CameraException catch (error) {
        lastCameraError = error;
        await controller.dispose();
      } catch (error) {
        lastOtherError = error;
        await controller.dispose();
      }
    }
    if (lastCameraError != null) throw lastCameraError;
    throw CameraException(
      'camera_initialize_failed',
      lastOtherError?.toString() ?? 'The receipt camera could not be opened.',
    );
  }

  String _cameraErrorMessage(CameraException error) {
    final code = error.code.toLowerCase();
    if (code.contains('access') || code.contains('permission')) {
      return 'Camera permission is needed to photograph a receipt.';
    }
    final description = error.description?.trim();
    return description == null || description.isEmpty
        ? 'The receipt camera could not be opened.'
        : description;
  }
}
