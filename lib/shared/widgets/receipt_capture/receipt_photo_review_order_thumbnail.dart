part of 'receipt_photo_review_screen.dart';

class _ReceiptOrderThumbnail extends StatelessWidget {
  const _ReceiptOrderThumbnail({
    required this.path,
    required this.index,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final String path;
  final int index;
  final int total;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF172126),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? const Color(0xFFFFD166) : const Color(0xFF344047),
            width: selected ? 2 : 1,
          ),
        ),
        child: SizedBox(
          width: 66,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: 180,
                  cacheHeight: 240,
                  filterQuality: FilterQuality.low,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFF050607),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF76848A),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: _ReceiptOrderThumbnailLabel(
                  alignment: _ReceiptOrderThumbnailLabelAlignment.topLeft,
                  text: _ReceiptPhotoSectionLabels.label(
                    index: index,
                    total: total,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: _ReceiptOrderThumbnailLabel(
                  alignment: _ReceiptOrderThumbnailLabelAlignment.bottomRight,
                  text: _ReceiptPhotoSectionLabels.sectionNumberLabel(
                    index: index,
                    total: total,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ReceiptOrderThumbnailLabelAlignment { topLeft, bottomRight }

class _ReceiptOrderThumbnailLabel extends StatelessWidget {
  const _ReceiptOrderThumbnailLabel({
    required this.alignment,
    required this.text,
  });

  final _ReceiptOrderThumbnailLabelAlignment alignment;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isTopLeft = alignment == _ReceiptOrderThumbnailLabelAlignment.topLeft;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD050607),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTopLeft ? 5 : 6),
          bottomRight: Radius.circular(isTopLeft ? 6 : 5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isTopLeft
                ? const Color(0xFFE8ECEE)
                : const Color(0xFFFFD166),
            fontSize: isTopLeft ? 9.5 : 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
