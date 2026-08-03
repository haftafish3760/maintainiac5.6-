part of 'receipt_photo_review_screen.dart';

class _ReceiptStitchedReceiptSurface extends StatelessWidget {
  const _ReceiptStitchedReceiptSurface({
    required this.path,
    required this.onTap,
  });

  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _StitchPreviewPhoto(
      path: path,
      label: 'Combined receipt',
      alignment: Alignment.topCenter,
      selected: true,
      showHeader: false,
      showSelectionBorder: false,
      onSelected: onTap,
    );
  }
}

class _StitchPreviewPhoto extends StatefulWidget {
  const _StitchPreviewPhoto({
    required this.path,
    required this.label,
    required this.alignment,
    required this.selected,
    required this.onSelected,
    this.showHeader = true,
    this.showSelectionBorder = true,
  });

  final String path;
  final String label;
  final Alignment alignment;
  final bool selected;
  final VoidCallback onSelected;
  final bool showHeader;
  final bool showSelectionBorder;

  @override
  State<_StitchPreviewPhoto> createState() => _StitchPreviewPhotoState();
}

class _StitchPreviewPhotoState extends State<_StitchPreviewPhoto> {
  final _transformController = TransformationController();
  TapDownDetails? _lastDoubleTap;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_handleTransformChanged);
  }

  @override
  void didUpdateWidget(covariant _StitchPreviewPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _transformController.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_handleTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final physicalWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(900, 1500);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Keep the selected-photo identity and gesture help outside the
        // receipt pixels. A label laid over a receipt can hide exactly the
        // line someone is trying to match.
        if (widget.showHeader)
          _StitchPhotoHeader(label: widget.label, selected: widget.selected),
        if (widget.showHeader) const SizedBox(height: 4),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Semantics(
                button: true,
                label: widget.selected
                    ? '${widget.label} selected'
                    : widget.label,
                hint: widget.selected
                    ? 'Pinch or double tap to zoom the receipt image'
                    : 'Tap to select. Pinch or double tap to zoom the receipt image',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onSelected,
                  onDoubleTapDown: (details) => _lastDoubleTap = details,
                  onDoubleTap: _toggleZoom,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 1,
                    maxScale: 6,
                    boundaryMargin: const EdgeInsets.all(48),
                    // At normal size the receipt should stay centered and
                    // stable. Panning only becomes useful after zooming.
                    panEnabled: _isZoomed,
                    scaleEnabled: true,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox.expand(
                      child: Image.file(
                        File(widget.path),
                        fit: BoxFit.contain,
                        alignment: widget.alignment,
                        // Supplying both cacheWidth and cacheHeight can decode
                        // a very tall stitched receipt into the viewport's
                        // shape. Width-only decoding preserves the receipt's
                        // true aspect ratio while still bounding memory use.
                        cacheWidth: physicalWidth,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.selected && widget.showSelectionBorder)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.fromBorderSide(
                          BorderSide(color: Color(0xFF28A745), width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isZoomed)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Semantics(
                    button: true,
                    label: 'Reset receipt zoom',
                    child: IconButton.filledTonal(
                      tooltip: 'Reset zoom',
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.zoom_out_map_rounded),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleTransformChanged() {
    final zoomed = _transformController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _isZoomed || !mounted) return;
    setState(() => _isZoomed = zoomed);
  }

  void _toggleZoom() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if (scale > 1.05) {
      _resetZoom();
      return;
    }
    final position = _lastDoubleTap?.localPosition ?? Offset.zero;
    const targetScale = 2.25;
    final zoom = Matrix4.identity()
      ..storage[0] = targetScale
      ..storage[5] = targetScale
      ..storage[12] = -position.dx * (targetScale - 1)
      ..storage[13] = -position.dy * (targetScale - 1);
    _transformController.value = zoom;
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }
}

class _StitchPhotoHeader extends StatelessWidget {
  const _StitchPhotoHeader({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        border: Border.all(
          color: selected ? const Color(0xFF28A745) : const Color(0xFF526168),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.touch_app_rounded,
              color: selected
                  ? const Color(0xFF5CE17A)
                  : const Color(0xFFC8D0D3),
              size: 15,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                selected ? '$label selected' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const Tooltip(
              message: 'Pinch or double tap to zoom',
              child: Icon(
                Icons.zoom_in_rounded,
                color: Color(0xFFFFD166),
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
