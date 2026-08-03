part of 'receipt_photo_review_screen.dart';

class _ReceiptReviewThumbnailStrip extends StatelessWidget {
  const _ReceiptReviewThumbnailStrip({
    required this.photoPaths,
    required this.selectedIndex,
    required this.onPhotoSelected,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final ValueChanged<int> onPhotoSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ColoredBox(
        color: const Color(0xF20D1316),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: photoPaths.length,
          separatorBuilder: (_, _) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final selected = index == selectedIndex;
            return Semantics(
              button: true,
              selected: selected,
              label: 'Receipt photo ${index + 1} of ${photoPaths.length}',
              child: InkWell(
                onTap: () => onPhotoSelected(index),
                borderRadius: BorderRadius.circular(5),
                child: Ink(
                  width: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFFD166)
                          : const Color(0xFF526168),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ColoredBox(
                          color: const Color(0xFF050607),
                          child: Image.file(
                            File(photoPaths[index]),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Color(0xFF172126),
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 3,
                        left: 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFFD166)
                                : const Color(0xE6000000),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF171005)
                                      : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
