part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewPhotoPager on _ReceiptPhotoReviewScreenState {
  Widget _buildPhotoReviewPager() {
    return PageView.builder(
      controller: _photoReviewPageController,
      itemCount: _photoPaths.length,
      physics: _photoPreviewZoomed
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      onPageChanged: (index) {
        if (!_reviewWorkActive || index == _selectedIndex) return;
        _resetPhotoPreviewZoom();
        _updateReviewState(() => _selectedIndex = index);
      },
      itemBuilder: (context, index) {
        return _ReceiptSwipePhotoPage(
          key: ValueKey(_photoPaths[index]),
          path: _photoPaths[index],
          cacheWidth: _reviewPreviewCacheWidth(context),
          cacheHeight: _reviewPreviewCacheHeight(context),
          selected: index == _selectedIndex,
          onZoomChanged: (zoomed) {
            if (index != _selectedIndex) return;
            _setPhotoPreviewZoomed(zoomed);
          },
        );
      },
    );
  }
}

class _ReceiptSwipePhotoPage extends StatefulWidget {
  const _ReceiptSwipePhotoPage({
    super.key,
    required this.path,
    required this.cacheWidth,
    required this.cacheHeight,
    required this.selected,
    required this.onZoomChanged,
  });

  final String path;
  final int cacheWidth;
  final int cacheHeight;
  final bool selected;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ReceiptSwipePhotoPage> createState() => _ReceiptSwipePhotoPageState();
}

class _ReceiptSwipePhotoPageState extends State<_ReceiptSwipePhotoPage> {
  final _controller = TransformationController();
  TapDownDetails? _lastDoubleTap;
  var _zoomed = false;

  @override
  void didUpdateWidget(covariant _ReceiptSwipePhotoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected && !widget.selected) _resetZoom();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) => _lastDoubleTap = details,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 6,
        boundaryMargin: const EdgeInsets.all(48),
        panEnabled: _zoomed,
        onInteractionUpdate: (_) => _syncZoomState(),
        onInteractionEnd: (_) => _syncZoomState(),
        child: SizedBox.expand(
          child: Image.file(
            File(widget.path),
            fit: BoxFit.contain,
            cacheWidth: widget.cacheWidth,
            cacheHeight: widget.cacheHeight,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Receipt image could not be previewed.',
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _toggleZoom() {
    if (_zoomed) {
      _resetZoom();
      return;
    }
    final tap = _lastDoubleTap?.localPosition ?? Offset.zero;
    const scale = 2.25;
    final matrix = Matrix4.identity()
      ..storage[0] = scale
      ..storage[5] = scale
      ..storage[12] = -tap.dx * (scale - 1)
      ..storage[13] = -tap.dy * (scale - 1);
    _controller.value = matrix;
    _setZoomed(true);
  }

  void _syncZoomState() {
    _setZoomed(_controller.value.getMaxScaleOnAxis() > 1.05);
  }

  void _resetZoom() {
    _lastDoubleTap = null;
    _controller.value = Matrix4.identity();
    _setZoomed(false);
  }

  void _setZoomed(bool value) {
    if (_zoomed == value || !mounted) return;
    setState(() => _zoomed = value);
    widget.onZoomChanged(value);
  }
}
