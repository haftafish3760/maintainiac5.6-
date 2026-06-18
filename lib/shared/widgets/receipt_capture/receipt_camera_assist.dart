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
    title: 'Assisted Mode',
    message: 'Aim at the receipt. Maintaniac will guide light and focus.',
    icon: Icons.crop_free_rounded,
    color: Color(0xFFFFD166),
  );

  static const steady = _ReceiptCameraAssistState(
    title: 'Hold Still',
    message: 'Maintaniac is letting the camera settle before capture.',
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
        message: 'Keep the whole receipt inside the guide.',
        icon: Icons.pan_tool_alt_rounded,
        color: Color(0xFFFFD166),
      ),
      1 => const _ReceiptCameraAssistState(
        title: 'Checking Focus',
        message: 'Tap the receipt text if the image looks soft.',
        icon: Icons.center_focus_strong_rounded,
        color: Color(0xFFA9DFFF),
      ),
      2 => const _ReceiptCameraAssistState(
        title: 'Watch Glare',
        message: 'Tilt the phone or receipt if bright spots cover the print.',
        icon: Icons.light_mode_rounded,
        color: Color(0xFFFFD166),
      ),
      3 => const _ReceiptCameraAssistState(
        title: 'Keep It Flat',
        message: 'Flatten long receipts so the lines stay readable.',
        icon: Icons.straighten_rounded,
        color: Color(0xFFA9DFFF),
      ),
      _ => const _ReceiptCameraAssistState(
        title: 'Final Check',
        message: 'Stay still while Maintaniac keeps the clearest shots.',
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
    if (quality.focusScore < 8) {
      return const _ReceiptCameraAssistState(
        title: 'Too Blurry',
        message: 'Hold still, tap the receipt text, and try Best Shot again.',
        icon: Icons.blur_on_rounded,
        color: Color(0xFFFF8FA3),
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
        title: 'Not Ready: Low Light',
        message: 'Turn on the light or move to a brighter spot.',
        icon: Icons.flashlight_on_rounded,
        color: Color(0xFFFF4D5E),
      );
    }
    if (quality.isTooBright) {
      return const _ReceiptCameraAssistState(
        title: 'Not Ready: Glare',
        message: 'Tilt the receipt or move away from direct shine.',
        icon: Icons.light_mode_rounded,
        color: Color(0xFFFF4D5E),
      );
    }
    if (quality.isPoorlyFramed) {
      return const _ReceiptCameraAssistState(
        title: 'Not Ready: Frame It',
        message: 'Put the receipt inside the guide and fill more of it.',
        icon: Icons.crop_free_rounded,
        color: Color(0xFFFF4D5E),
      );
    }
    if (quality.isSoft) {
      return const _ReceiptCameraAssistState(
        title: 'Not Ready: Focus',
        message: 'Tap printed lines and hold the phone still.',
        icon: Icons.center_focus_strong_rounded,
        color: Color(0xFFFF4D5E),
      );
    }
    if (quality.isLowContrast) {
      return const _ReceiptCameraAssistState(
        title: 'Almost Ready: Contrast',
        message: 'Move closer or improve light so printed lines stand out.',
        icon: Icons.zoom_in_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isMissingEdges) {
      return const _ReceiptCameraAssistState(
        title: 'Almost Ready: Edges',
        message: 'Show the receipt edges so the app can judge the document.',
        icon: Icons.document_scanner_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isMissingLineBands) {
      return const _ReceiptCameraAssistState(
        title: 'Almost Ready: Lines',
        message: 'Move closer until the printed receipt lines are visible.',
        icon: Icons.subject_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.isSkewed) {
      return const _ReceiptCameraAssistState(
        title: 'Almost Ready: Angle',
        message: 'Square up the phone with the receipt.',
        icon: Icons.straighten_rounded,
        color: Color(0xFFFFD166),
      );
    }
    if (quality.readiness == _ReceiptCameraReadiness.almostReady) {
      return const _ReceiptCameraAssistState(
        title: 'Almost Ready: Hold',
        message: 'Keep it steady for a moment, then capture.',
        icon: Icons.pan_tool_alt_rounded,
        color: Color(0xFFFFD166),
      );
    }
    return const _ReceiptCameraAssistState(
      title: 'Ready',
      message: 'Receipt looks readable. Tap capture when ready.',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF8EF6A4),
    );
  }

  static _ReceiptCameraAssistState needsRetake(
    ReceiptPhotoQualityCheck quality,
  ) {
    if (quality.focusScore < 8) {
      return const _ReceiptCameraAssistState(
        title: 'Retake Needed',
        message:
            'The sharpest photo still looks blurry. Tap receipt text, turn on the light, and try again.',
        icon: Icons.replay_rounded,
        color: Color(0xFFFF8FA3),
      );
    }
    return const _ReceiptCameraAssistState(
      title: 'Retake Needed',
      message:
          'The receipt did not have enough readable detail. Move closer and fill the guide.',
      icon: Icons.zoom_in_rounded,
      color: Color(0xFFFFD166),
    );
  }
}

class _ReceiptCameraAssistCard extends StatelessWidget {
  const _ReceiptCameraAssistCard({required this.state});

  final _ReceiptCameraAssistState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: state.visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xDD050607),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: state.color, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Icon(state.icon, color: state.color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
