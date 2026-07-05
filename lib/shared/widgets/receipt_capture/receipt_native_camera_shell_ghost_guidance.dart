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
    return Align(
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        child: FractionallySizedBox(
          heightFactor: .20,
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
                Opacity(opacity: .30, child: ClipRect(child: preview)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xCC050607),
                        Color(0x33050607),
                        Color(0x66050607),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: MediaQuery.viewPaddingOf(context).top + 8,
                  child: _ReceiptPreviousSectionGhostLabel(
                    reasonCode: reasonCode,
                    guidance: guidance,
                  ),
                ),
                const Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: _ReceiptPreviousSectionGhostRule(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPreviousSectionGhostLabel extends StatelessWidget {
  const _ReceiptPreviousSectionGhostLabel({this.reasonCode, this.guidance});

  final String? reasonCode;
  final String? guidance;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xD911181B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFD166), width: .8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            children: [
              const Icon(
                Icons.layers_rounded,
                color: Color(0xFFFFD166),
                size: 15,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE4EBEE),
                        fontSize: 10.5,
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
    );
  }

  bool get _missingBottomAndTotals =>
      reasonCode?.trim() == 'missing_bottom_edge_and_totals';
  bool get _usesNextContext =>
      reasonCode?.trim() == 'retake_top_with_next_context';

  String get _title {
    if (_usesNextContext) return 'Match the next section';
    return _missingBottomAndTotals
        ? 'Match the bottom section'
        : 'Match sections';
  }

  String get _message {
    final custom = guidance?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    if (_usesNextContext) {
      return 'Use the next section as context, then confirm the join in review.';
    }
    if (_missingBottomAndTotals) {
      return 'Repeat 3-5 readable lines here so subtotal, total, and final lines can be matched.';
    }
    return 'Repeat 3-5 readable lines from the prior photo.';
  }

  String get _semanticLabel =>
      'Long receipt top ghost-slice guide. $_title. $_message';
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
          'Line up 3-5 repeated receipt lines here',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
