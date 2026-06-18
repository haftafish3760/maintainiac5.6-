part of 'receipt_photo_review_screen.dart';

class _ReceiptPhotoStrip extends StatelessWidget {
  const _ReceiptPhotoStrip({
    required this.photoPaths,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final sectionLabel = _ReceiptPhotoSectionLabels.label(
            index: index,
            total: photoPaths.length,
          );
          return Semantics(
            button: true,
            selected: selected,
            label:
                '$sectionLabel receipt section, ${_ReceiptPhotoSectionLabels.countLabel(index: index, total: photoPaths.length)}',
            child: InkWell(
              onTap: () => onSelected(index),
              child: Container(
                width: 82,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF58D67D)
                        : const Color(0xFF53656D),
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(photoPaths[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0xCC000000),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sectionLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE8ECEE),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _ReceiptPhotoSectionLabels.countLabel(
                                  index: index,
                                  total: photoPaths.length,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFC8D0D3),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: photoPaths.length,
      ),
    );
  }
}
