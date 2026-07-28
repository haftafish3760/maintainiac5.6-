part of 'receipt_native_camera_shell.dart';

class _ReceiptPreviousSectionGhost extends StatelessWidget {
  const _ReceiptPreviousSectionGhost({
    required this.preview,
    this.reasonCode,
    this.guidance,
  });

  final Widget preview;
  final String? reasonCode;
  final String? guidance;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      child: Align(
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          child: FractionallySizedBox(
            heightFactor: .14,
            widthFactor: 1,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFFD166), width: 2),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(opacity: .18, child: ClipRect(child: preview)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55050607), Color(0x11050607)],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    right: 12,
                    bottom: 6,
                    child: _ReceiptPreviousSectionGhostRule(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    final message = guidance?.trim();
    return message == null || message.isEmpty
        ? 'Long receipt top ghost-slice guide. Repeat 3-5 readable lines from the prior photo.'
        : 'Long receipt top ghost-slice guide. $message';
  }
}

class _ReceiptPreviousSectionGhostRule extends StatelessWidget {
  const _ReceiptPreviousSectionGhostRule();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD911181B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD166), width: .8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'Repeat 3-5 lines in this guide',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFD166),
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
