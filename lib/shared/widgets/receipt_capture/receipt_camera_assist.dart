part of 'receipt_camera_screen.dart';

class _ReceiptCameraAssistState {
  const _ReceiptCameraAssistState({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.visible = true,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final bool visible;

  static const idle = _ReceiptCameraAssistState(
    title: 'Ready',
    message: 'Standard mode is ready. Aim, tap focus if needed, then capture.',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFFFD166),
    visible: false,
  );

  static const starting = _ReceiptCameraAssistState(
    title: 'Receipt Assist',
    message:
        'Aim at the receipt. Maintainiac will guide light, focus, and fit.',
    icon: Icons.crop_free_rounded,
    color: Color(0xFFFFD166),
  );

  static const steady = _ReceiptCameraAssistState(
    title: 'Hold Still',
    message: 'Hold steady while the camera settles.',
    icon: Icons.timer_rounded,
    color: Color(0xFFA9DFFF),
  );

  static const lowStorage = _ReceiptCameraAssistState(
    title: 'Storage Needed',
    message: 'Free up space before taking receipt photos.',
    icon: Icons.sd_storage_rounded,
    color: Color(0xFFFF8FA3),
  );

  static const noPhoto = _ReceiptCameraAssistState(
    title: 'Try Again',
    message: 'No receipt photo was captured. Hold steady and try again.',
    icon: Icons.replay_rounded,
    color: Color(0xFFFF8FA3),
  );

  static const finished = _ReceiptCameraAssistState(
    title: 'Good Capture',
    message: 'Receipt photos are ready for review.',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF8EF6A4),
  );

  static _ReceiptCameraAssistState forCapture(int index) {
    return switch (index) {
      0 => const _ReceiptCameraAssistState(
        title: 'Hold Still',
        message: 'Keep the receipt centered and easy to read.',
        icon: Icons.pan_tool_alt_rounded,
        color: Color(0xFFFFD166),
      ),
      1 => const _ReceiptCameraAssistState(
        title: 'Check Focus',
        message: 'Tap the receipt text if the image looks soft.',
        icon: Icons.center_focus_strong_rounded,
        color: Color(0xFFA9DFFF),
      ),
      2 => const _ReceiptCameraAssistState(
        title: 'Watch Glare',
        message: 'Tilt the phone or receipt if shine covers the print.',
        icon: Icons.light_mode_rounded,
        color: Color(0xFFFFD166),
      ),
      3 => const _ReceiptCameraAssistState(
        title: 'Long Receipt',
        message: 'Take readable photos instead of squeezing tiny text.',
        icon: Icons.straighten_rounded,
        color: Color(0xFFA9DFFF),
      ),
      _ => const _ReceiptCameraAssistState(
        title: 'Final Shot',
        message: 'Stay still while Maintainiac keeps the clearest photo.',
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFF8EF6A4),
      ),
    };
  }

  static _ReceiptCameraAssistState fromQuality(
    ReceiptPhotoQualityCheck quality, {
    required int captureIndex,
  }) {
    if (quality.width == 0 || quality.height == 0) {
      return const _ReceiptCameraAssistState(
        title: 'Could Not Check Photo',
        message: 'Try again with the receipt flat and fully visible.',
        icon: Icons.error_outline_rounded,
        color: Color(0xFFFF8FA3),
      );
    }
    if (quality.isTooDark) {
      return const _ReceiptCameraAssistState(
        title: 'Too Dark',
        message: 'Turn on the light or move the receipt into brighter light.',
        icon: Icons.flashlight_on_rounded,
        color: Color(0xFFFF8FA3),
      );
    }
    if (quality.isTooBright) {
      return const _ReceiptCameraAssistState(
        title: 'Glare',
        message: 'Tilt the phone or receipt so shine leaves the printed text.',
        icon: Icons.light_mode_rounded,
        color: Color(0xFFFF8FA3),
      );
    }
    if (quality.focusScore < 8) {
      return const _ReceiptCameraAssistState(
        title: 'Too Blurry',
        message:
            'Hold still, tap the receipt text, and try Guided Capture again.',
        icon: Icons.blur_on_rounded,
        color: Color(0xFFFF8FA3),
      );
    }
    if (quality.isPoorlyFramed) {
      return const _ReceiptCameraAssistState(
        title: 'Check Framing',
        message: 'If all receipt text is visible, you can continue.',
        icon: Icons.crop_free_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isLowContrast || quality.isMissingTextBands) {
      return const _ReceiptCameraAssistState(
        title: 'Text Too Weak',
        message: 'Move closer or improve light so receipt lines stand out.',
        icon: Icons.subject_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.width < 900 || quality.height < 900) {
      return const _ReceiptCameraAssistState(
        title: 'Move Closer',
        message:
            'The receipt is too small in the photo. Fill more of the guide.',
        icon: Icons.zoom_in_rounded,
        color: Color(0xFFFFD166),
      );
    }
    return _ReceiptCameraAssistState(
      title: 'Frame ${captureIndex + 1} Looks Good',
      message: 'Keep holding steady while the app checks the next shot.',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF8EF6A4),
    );
  }

  static _ReceiptCameraAssistState fromLiveFrame(
    _ReceiptLiveFrameQuality quality,
  ) {
    if (quality.isTooDark) {
      return const _ReceiptCameraAssistState(
        title: 'Add Light',
        message: 'Turn on the light or move to a brighter spot.',
        icon: Icons.flashlight_on_rounded,
        color: Color(0xFFFF4D5E),
      );
    }
    if (quality.isTooBright) {
      return const _ReceiptCameraAssistState(
        title: 'Reduce Glare',
        message: 'Tilt the phone or receipt so shine leaves the print.',
        icon: Icons.light_mode_rounded,
        color: Color(0xFFFF4D5E),
      );
    }
    if (quality.isPoorlyFramed) {
      return const _ReceiptCameraAssistState(
        title: 'Check Full Receipt',
        message: 'Keep all receipt text visible. Capture still works.',
        icon: Icons.crop_free_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isSoft) {
      return const _ReceiptCameraAssistState(
        title: 'Tap To Focus',
        message: 'Tap printed lines and hold the phone still.',
        icon: Icons.center_focus_strong_rounded,
        color: Color(0xFFFF4D5E),
      );
    }
    if (quality.mayBeCutOffAtBottom) {
      return const _ReceiptCameraAssistState(
        title: 'Show More Receipt',
        message: 'The receipt may continue below the view. Move back slightly.',
        icon: Icons.vertical_align_bottom_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isLowContrast) {
      return const _ReceiptCameraAssistState(
        title: 'Improve Contrast',
        message: 'Move closer or improve light so printed lines stand out.',
        icon: Icons.zoom_in_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isMissingEdges) {
      return const _ReceiptCameraAssistState(
        title: 'Fill The View',
        message: 'Center the receipt with readable space around it.',
        icon: Icons.document_scanner_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isMissingLineBands) {
      return const _ReceiptCameraAssistState(
        title: 'Move Closer',
        message: 'Move closer until the receipt text is easy to read.',
        icon: Icons.subject_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isSkewed) {
      return const _ReceiptCameraAssistState(
        title: 'Square It Up',
        message: 'Square up the phone with the receipt.',
        icon: Icons.straighten_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.readiness == _ReceiptCameraReadiness.almostReady) {
      return const _ReceiptCameraAssistState(
        title: 'Hold Steady',
        message: 'Keep it steady for a moment. Capture still works.',
        icon: Icons.pan_tool_alt_rounded,
        color: Color(0xFFFFD166),
      );
    }
    return const _ReceiptCameraAssistState(
      title: 'Ready',
      message: 'Receipt looks readable. Hold steady or tap capture.',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF8EF6A4),
    );
  }
}
