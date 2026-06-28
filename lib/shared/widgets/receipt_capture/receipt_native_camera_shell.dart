import 'package:flutter/material.dart';

import 'receipt_capture_models.dart';
import 'receipt_native_camera_contract.dart';

class ReceiptNativeCameraShell extends StatelessWidget {
  const ReceiptNativeCameraShell({
    super.key,
    required this.preview,
    required this.capabilities,
    required this.settings,
    required this.onBack,
    required this.onCapture,
    required this.onSettings,
    this.onTorch,
    this.torchOn = false,
    this.capturing = false,
    this.guidanceTitle = 'Line up the receipt',
    this.guidanceMessage = 'Fill the screen with readable receipt text.',
    this.guidanceStatus,
    this.previousSectionPreview,
    this.sectionLabel,
    this.qualityLabel,
    this.children = const [],
  });

  final Widget preview;
  final ReceiptNativeCameraCapabilities capabilities;
  final ReceiptNativeCameraSettings settings;
  final VoidCallback onBack;
  final VoidCallback onCapture;
  final VoidCallback onSettings;
  final VoidCallback? onTorch;
  final bool torchOn;
  final bool capturing;
  final String guidanceTitle;
  final String guidanceMessage;
  final String? guidanceStatus;
  final Widget? previousSectionPreview;
  final String? sectionLabel;
  final String? qualityLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF050607),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: preview),
          if (previousSectionPreview != null)
            _ReceiptPreviousSectionGhost(preview: previousSectionPreview!),
          const Positioned.fill(
            child: IgnorePointer(child: _ReceiptCameraVignette()),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _ReceiptNativeCameraTopBar(
              torchOn: torchOn,
              torchSupported: capabilities.supportsTorch,
              onBack: onBack,
              onTorch: onTorch,
              onSettings: onSettings,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.viewPaddingOf(context).top + 68,
            child: _ReceiptNativeCameraGuidance(
              title: guidanceTitle,
              message: guidanceMessage,
              status: guidanceStatus,
              sectionLabel: sectionLabel,
            ),
          ),
          ...children,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ReceiptNativeCameraBottomBar(
              capturing: capturing,
              settings: settings,
              qualityLabel: qualityLabel,
              onCapture: onCapture,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptNativeCameraTopBar extends StatelessWidget {
  const _ReceiptNativeCameraTopBar({
    required this.torchOn,
    required this.torchSupported,
    required this.onBack,
    required this.onSettings,
    this.onTorch,
  });

  final bool torchOn;
  final bool torchSupported;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback? onTorch;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(
          children: [
            _ReceiptNativeCameraIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              onPressed: onBack,
            ),
            const Spacer(),
            _ReceiptNativeCameraIconButton(
              icon: Icons.settings_rounded,
              label: 'Receipt camera settings',
              onPressed: onSettings,
            ),
            const SizedBox(width: 8),
            _ReceiptNativeCameraIconButton(
              icon: torchOn
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
              label: torchOn ? 'Turn light off' : 'Turn light on',
              onPressed: torchSupported ? onTorch : null,
              active: torchOn,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptNativeCameraBottomBar extends StatelessWidget {
  const _ReceiptNativeCameraBottomBar({
    required this.capturing,
    required this.settings,
    required this.onCapture,
    this.qualityLabel,
  });

  final bool capturing;
  final ReceiptNativeCameraSettings settings;
  final VoidCallback onCapture;
  final String? qualityLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00050607), Color(0xE6050607)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _ReceiptNativeCameraModePill(
                  icon: settings.assistedReceiptFill
                      ? Icons.receipt_long_rounded
                      : Icons.edit_note_rounded,
                  label: settings.assistedReceiptFill
                      ? 'Assisted receipt'
                      : 'Manual entry',
                  detail: settings.assistedReceiptFill
                      ? 'Review before saving'
                      : 'Photo only if needed',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _ReceiptNativeCameraShutterButton(
                  capturing: capturing,
                  onPressed: capturing ? null : onCapture,
                ),
              ),
              Expanded(
                child: _ReceiptNativeCameraModePill(
                  icon: Icons.storage_rounded,
                  label: qualityLabel ?? 'Save space',
                  detail: _storageDetail(settings.dataSaverLevel),
                  alignRight: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _storageDetail(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => 'Local original',
      ReceiptDataSaverLevel.light => 'Sharper backup',
      ReceiptDataSaverLevel.balanced => 'Balanced backup',
      ReceiptDataSaverLevel.strong => 'Smaller backup',
      ReceiptDataSaverLevel.maximum => 'Smallest backup',
    };
  }
}

class _ReceiptNativeCameraGuidance extends StatelessWidget {
  const _ReceiptNativeCameraGuidance({
    required this.title,
    required this.message,
    this.status,
    this.sectionLabel,
  });

  final String title;
  final String message;
  final String? status;
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD4050607),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x996B7A81)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.subject_rounded,
                  color: Color(0xFFFFD166),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (sectionLabel != null)
                  Text(
                    sectionLabel!,
                    style: const TextStyle(
                      color: Color(0xFFE4EBEE),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD5DEE2),
                fontSize: 13,
                height: 1.18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: 8),
              Text(
                status!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptPreviousSectionGhost extends StatelessWidget {
  const _ReceiptPreviousSectionGhost({required this.preview});

  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        child: FractionallySizedBox(
          heightFactor: .20,
          widthFactor: 1,
          child: Opacity(
            opacity: .28,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFFD166), width: 2),
                ),
              ),
              child: ClipRect(child: preview),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptNativeCameraModePill extends StatelessWidget {
  const _ReceiptNativeCameraModePill({
    required this.icon,
    required this.label,
    required this.detail,
    this.alignRight = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignRight ? Alignment.bottomRight : Alignment.bottomLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 142),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xD911181B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4D5D64)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFFFFD166), size: 17),
                const SizedBox(width: 7),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: alignRight
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD4DEE2),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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

class _ReceiptNativeCameraShutterButton extends StatelessWidget {
  const _ReceiptNativeCameraShutterButton({
    required this.capturing,
    required this.onPressed,
  });

  final bool capturing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take receipt photo',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onPressed == null
                  ? const Color(0xFF80888C)
                  : const Color(0xFFFFFFFF),
              border: Border.all(color: const Color(0xFF050607), width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: capturing
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF101416),
                      ),
                    )
                  : const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF101416),
                      size: 34,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptNativeCameraIconButton extends StatelessWidget {
  const _ReceiptNativeCameraIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: active
            ? const Color(0xFFFFD166)
            : const Color(0xDD11181B),
        foregroundColor: active ? const Color(0xFF101416) : Colors.white,
        disabledBackgroundColor: const Color(0x8811181B),
        disabledForegroundColor: const Color(0xFF8E9AA0),
        minimumSize: const Size(46, 46),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF526168), width: .8),
        ),
      ),
    );
  }
}

class _ReceiptCameraVignette extends StatelessWidget {
  const _ReceiptCameraVignette();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x9A000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0xA6000000),
          ],
          stops: [0, .22, .68, 1],
        ),
      ),
    );
  }
}
