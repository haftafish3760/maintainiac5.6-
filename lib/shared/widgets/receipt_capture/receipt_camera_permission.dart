import 'package:permission_handler/permission_handler.dart';

class ReceiptCameraPermissionResult {
  const ReceiptCameraPermissionResult({
    required this.status,
    required this.requestedPermission,
  });

  final PermissionStatus status;
  final bool requestedPermission;

  bool get canUseCamera => status.isGranted || status.isLimited;

  bool get needsSystemSettings =>
      status.isPermanentlyDenied || status.isRestricted;

  String get userMessage {
    if (canUseCamera) return '';
    if (needsSystemSettings) {
      return 'Camera permission is blocked. Open your phone settings, allow camera access for Maintainiac, then try Capture Receipt Photo again.';
    }
    return 'Camera permission is needed before Maintainiac can photograph a receipt.';
  }
}

class ReceiptCameraPermission {
  const ReceiptCameraPermission();

  Future<ReceiptCameraPermissionResult> ensureReady() async {
    var status = await Permission.camera.status;
    var requested = false;
    if (!status.isGranted &&
        !status.isLimited &&
        !status.isPermanentlyDenied &&
        !status.isRestricted) {
      status = await Permission.camera.request();
      requested = true;
    }
    return ReceiptCameraPermissionResult(
      status: status,
      requestedPermission: requested,
    );
  }
}
