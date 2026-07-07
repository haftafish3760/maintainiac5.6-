part of 'receipt_photo_review_screen.dart';

class _ReceiptOrderToolControls extends StatelessWidget {
  const _ReceiptOrderToolControls({
    required this.photoPaths,
    required this.selectedIndex,
    required this.openingCamera,
    required this.onPhotoSelected,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onAddPhoto,
    required this.onRetake,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final bool openingCamera;
  final ValueChanged<int> onPhotoSelected;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;
  final VoidCallback onAddPhoto;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final interactionLocked = openingCamera;
    final canMoveEarlier = selectedIndex > 0;
    final canMoveLater = selectedIndex < photoPaths.length - 1;
    final sectionLabel = _ReceiptPhotoSectionLabels.label(
      index: selectedIndex,
      total: photoPaths.length,
    );
    final sectionHint = _ReceiptPhotoSectionLabels.orderHint(
      index: selectedIndex,
      total: photoPaths.length,
    );
    final countLabel = _ReceiptPhotoSectionLabels.countLabel(
      index: selectedIndex,
      total: photoPaths.length,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF526168)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFFFD166),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$sectionLabel, $countLabel. $sectionHint Receipt details open in this order.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, index) {
                  return _ReceiptOrderThumbnail(
                    path: photoPaths[index],
                    index: index,
                    total: photoPaths.length,
                    selected: index == selectedIndex,
                    onTap: interactionLocked ? null : () => onPhotoSelected(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canMoveEarlier && !interactionLocked
                        ? onMoveEarlier
                        : null,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 17),
                    label: Text(
                      _ReceiptPhotoSectionLabels.moveEarlierLabel(
                        index: selectedIndex,
                      ),
                    ),
                    style: _orderButtonStyle(),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canMoveLater && !interactionLocked
                        ? onMoveLater
                        : null,
                    icon: const Icon(Icons.arrow_downward_rounded, size: 17),
                    label: Text(
                      _ReceiptPhotoSectionLabels.moveLaterLabel(
                        index: selectedIndex,
                        total: photoPaths.length,
                      ),
                    ),
                    style: _orderButtonStyle(),
                  ),
                ),
                const SizedBox(width: 7),
                _MiniReceiptIconButton(
                  icon: Icons.add_a_photo_rounded,
                  label: _ReceiptPhotoSectionLabels.addNextPhotoLabel(
                    index: selectedIndex,
                    total: photoPaths.length,
                  ),
                  onPressed: interactionLocked ? null : onAddPhoto,
                ),
                const SizedBox(width: 5),
                _MiniReceiptIconButton(
                  icon: Icons.camera_alt_rounded,
                  label: _ReceiptPhotoSectionLabels.retakeLabel(
                    index: selectedIndex,
                    total: photoPaths.length,
                  ),
                  semanticLabel: _ReceiptPhotoSectionLabels.retakeSemanticLabel(
                    index: selectedIndex,
                    total: photoPaths.length,
                  ),
                  onPressed: interactionLocked ? null : onRetake,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _orderButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFE8ECEE),
      disabledForegroundColor: const Color(0xFF76848A),
      side: const BorderSide(color: Color(0xFF526168), width: .9),
      minimumSize: const Size(0, 39),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
    );
  }
}
