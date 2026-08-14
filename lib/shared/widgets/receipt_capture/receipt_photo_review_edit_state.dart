class ReceiptPhotoEditTarget {
  const ReceiptPhotoEditTarget._({
    required this.photoPath,
    required this.photoIndex,
  });

  final String photoPath;
  final int photoIndex;

  static ReceiptPhotoEditTarget? capture({
    required List<String> photoPaths,
    required int selectedIndex,
  }) {
    if (selectedIndex < 0 || selectedIndex >= photoPaths.length) return null;
    return ReceiptPhotoEditTarget._(
      photoPath: photoPaths[selectedIndex],
      photoIndex: selectedIndex,
    );
  }

  bool stillOwns({
    required List<String> photoPaths,
    required int selectedIndex,
  }) {
    return selectedIndex == photoIndex &&
        photoIndex >= 0 &&
        photoIndex < photoPaths.length &&
        photoPaths[photoIndex] == photoPath;
  }
}

class ReceiptPhotoPairAdjustmentState {
  final overlapFractions = <double?>[];
  final scaleCorrections = <double>[];
  final rotationCorrectionsDegrees = <double>[];
  final horizontalOffsetFractions = <double>[];
  final zeroOverlapPairs = <bool>[];

  int get pairCount => overlapFractions.length;

  void syncForPhotoCount(int photoCount) {
    final needed = (photoCount - 1).clamp(0, 1000000);
    while (pairCount < needed) {
      overlapFractions.add(null);
      scaleCorrections.add(1);
      rotationCorrectionsDegrees.add(0);
      horizontalOffsetFractions.add(0);
      zeroOverlapPairs.add(false);
    }
    while (pairCount > needed) {
      overlapFractions.removeLast();
      scaleCorrections.removeLast();
      rotationCorrectionsDegrees.removeLast();
      horizontalOffsetFractions.removeLast();
      zeroOverlapPairs.removeLast();
    }
  }

  void resetForPhotoSetChange(int photoCount) {
    overlapFractions.clear();
    scaleCorrections.clear();
    rotationCorrectionsDegrees.clear();
    horizontalOffsetFractions.clear();
    zeroOverlapPairs.clear();
    syncForPhotoCount(photoCount);
  }
}

class ReceiptPhotoReviewDecisionState {
  final promptedPhotoPaths = <String>{};
  final decisionsByPath = <String, Map<String, Object?>>{};

  void evictPhotoPath(String photoPath) {
    promptedPhotoPaths.remove(photoPath);
    decisionsByPath.remove(photoPath);
  }
}
