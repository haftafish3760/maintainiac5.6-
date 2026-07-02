part of 'receipt_edge_cropper.dart';

class _CropHandle extends StatelessWidget {
  const _CropHandle({
    required this.imageRect,
    required this.cropRect,
    required this.handle,
    required this.onDrag,
  });

  final Rect imageRect;
  final Rect cropRect;
  final _ReceiptCropHandle handle;
  final void Function(
    _ReceiptCropHandle handle,
    DragUpdateDetails details,
    Rect imageRect,
    Rect cropRect,
  )
  onDrag;

  static const _hitSize = 56.0;
  static const _edgeVisibleSize = 8.0;
  static const _edgeVisibleLength = 112.0;
  static const _cornerVisibleSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final rect = switch (handle) {
      _ReceiptCropHandle.left => Rect.fromLTWH(
        cropRect.left - _hitSize / 2,
        cropRect.top,
        _hitSize,
        cropRect.height,
      ),
      _ReceiptCropHandle.right => Rect.fromLTWH(
        cropRect.right - _hitSize / 2,
        cropRect.top,
        _hitSize,
        cropRect.height,
      ),
      _ReceiptCropHandle.top => Rect.fromLTWH(
        cropRect.left,
        cropRect.top - _hitSize / 2,
        cropRect.width,
        _hitSize,
      ),
      _ReceiptCropHandle.bottom => Rect.fromLTWH(
        cropRect.left,
        cropRect.bottom - _hitSize / 2,
        cropRect.width,
        _hitSize,
      ),
      _ReceiptCropHandle.topLeft => Rect.fromLTWH(
        cropRect.left - _hitSize / 2,
        cropRect.top - _hitSize / 2,
        _hitSize,
        _hitSize,
      ),
      _ReceiptCropHandle.topRight => Rect.fromLTWH(
        cropRect.right - _hitSize / 2,
        cropRect.top - _hitSize / 2,
        _hitSize,
        _hitSize,
      ),
      _ReceiptCropHandle.bottomLeft => Rect.fromLTWH(
        cropRect.left - _hitSize / 2,
        cropRect.bottom - _hitSize / 2,
        _hitSize,
        _hitSize,
      ),
      _ReceiptCropHandle.bottomRight => Rect.fromLTWH(
        cropRect.right - _hitSize / 2,
        cropRect.bottom - _hitSize / 2,
        _hitSize,
        _hitSize,
      ),
    };
    final vertical =
        handle == _ReceiptCropHandle.left || handle == _ReceiptCropHandle.right;
    final horizontal =
        handle == _ReceiptCropHandle.top || handle == _ReceiptCropHandle.bottom;
    final corner = !vertical && !horizontal;
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) => onDrag(handle, details, imageRect, cropRect),
        child: Center(
          child: Semantics(
            button: true,
            label: _semanticLabel,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: corner
                    ? const Color(0xFFFFF2BD)
                    : const Color(0xFFFFD166),
                borderRadius: BorderRadius.circular(corner ? 7 : 4),
                border: Border.all(
                  color: const Color(0xFF050607),
                  width: corner ? 2 : 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xDD000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                width: vertical
                    ? _edgeVisibleSize
                    : horizontal
                    ? _edgeVisibleLength
                    : _cornerVisibleSize,
                height: vertical
                    ? _edgeVisibleLength
                    : horizontal
                    ? _edgeVisibleSize
                    : _cornerVisibleSize,
                child: corner
                    ? const Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xFF050607),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 6, height: 6),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    return switch (handle) {
      _ReceiptCropHandle.left => 'Move left receipt crop edge',
      _ReceiptCropHandle.right => 'Move right receipt crop edge',
      _ReceiptCropHandle.top => 'Move top receipt crop edge',
      _ReceiptCropHandle.bottom => 'Move bottom receipt crop edge',
      _ReceiptCropHandle.topLeft => 'Move top left receipt crop corner',
      _ReceiptCropHandle.topRight => 'Move top right receipt crop corner',
      _ReceiptCropHandle.bottomLeft => 'Move bottom left receipt crop corner',
      _ReceiptCropHandle.bottomRight => 'Move bottom right receipt crop corner',
    };
  }
}
