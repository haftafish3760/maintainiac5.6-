class ReceiptPhotoRetakeAlignmentContext {
  const ReceiptPhotoRetakeAlignmentContext._({
    required this.targetIndex,
    required this.targetPhotoPath,
    this.previousPhotoPath,
    this.nextPhotoPath,
  });

  final int targetIndex;
  final String targetPhotoPath;
  final String? previousPhotoPath;
  final String? nextPhotoPath;

  bool get hasPreviousContext => previousPhotoPath != null;
  bool get hasNextContext => nextPhotoPath != null;
  bool get hasTwoSidedContext => hasPreviousContext && hasNextContext;

  String? get preferredGuidePhotoPath => previousPhotoPath ?? nextPhotoPath;

  String get guidanceCode {
    if (hasTwoSidedContext) return 'retake_middle_with_previous_next_context';
    if (hasPreviousContext) return 'retake_bottom_with_previous_context';
    if (hasNextContext) return 'retake_top_with_next_context';
    return 'retake_single_section_no_context';
  }

  static ReceiptPhotoRetakeAlignmentContext? build({
    required List<String> currentPhotoPaths,
    required String targetPhotoPath,
  }) {
    if (!_receiptPhotoPathsAreUniqueAndNormalized(currentPhotoPaths)) {
      return null;
    }
    final targetIndex = currentPhotoPaths.indexOf(targetPhotoPath);
    if (targetIndex < 0) return null;
    return ReceiptPhotoRetakeAlignmentContext._(
      targetIndex: targetIndex,
      targetPhotoPath: targetPhotoPath,
      previousPhotoPath: targetIndex > 0
          ? currentPhotoPaths[targetIndex - 1]
          : null,
      nextPhotoPath: targetIndex < currentPhotoPaths.length - 1
          ? currentPhotoPaths[targetIndex + 1]
          : null,
    );
  }
}

class ReceiptPhotoRetakeOrderPlan {
  const ReceiptPhotoRetakeOrderPlan._({
    required this.photoPaths,
    required this.selectedIndex,
    required this.replacedPhotoPath,
    required this.alignmentContext,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final String replacedPhotoPath;
  final ReceiptPhotoRetakeAlignmentContext alignmentContext;

  int get originalSectionNumber => alignmentContext.targetIndex + 1;

  Map<String, Map<String, Object?>> captureDiagnosticsForReplacementPaths(
    List<String> replacementPhotoPaths,
  ) {
    return {
      for (var offset = 0; offset < replacementPhotoPaths.length; offset++)
        replacementPhotoPaths[offset]: {
          'receiptRetakePreservedOriginalSlot': offset == 0,
          'receiptRetakeOriginalSectionNumber': originalSectionNumber,
          'receiptRetakeReplacementOffset': offset,
          'receiptRetakeFinalSectionNumber': originalSectionNumber + offset,
          'receiptRetakeInsertedExtraSection': offset > 0,
          'receiptRetakeGuidanceCode': alignmentContext.guidanceCode,
          'receiptRetakeHasPreviousAlignmentContext':
              alignmentContext.hasPreviousContext,
          'receiptRetakeHasNextAlignmentContext':
              alignmentContext.hasNextContext,
          'receiptRetakeHasTwoSidedAlignmentContext':
              alignmentContext.hasTwoSidedContext,
          'receiptRetakeOrderPolicy':
              'preserve_original_slot_insert_extra_sections_after_target',
        },
    };
  }

  static ReceiptPhotoRetakeOrderPlan? build({
    required List<String> currentPhotoPaths,
    required String targetPhotoPath,
    required List<String> replacementPhotoPaths,
  }) {
    if (currentPhotoPaths.isEmpty || replacementPhotoPaths.isEmpty) {
      return null;
    }
    if (!_replacementPathsAreSafe(
      currentPhotoPaths: currentPhotoPaths,
      replacementPhotoPaths: replacementPhotoPaths,
    )) {
      return null;
    }
    final alignmentContext = ReceiptPhotoRetakeAlignmentContext.build(
      currentPhotoPaths: currentPhotoPaths,
      targetPhotoPath: targetPhotoPath,
    );
    if (alignmentContext == null) return null;
    final targetIndex = alignmentContext.targetIndex;
    final updatedPaths = List<String>.of(currentPhotoPaths);
    updatedPaths[targetIndex] = replacementPhotoPaths.first;
    if (replacementPhotoPaths.length > 1) {
      updatedPaths.insertAll(targetIndex + 1, replacementPhotoPaths.skip(1));
    }
    return ReceiptPhotoRetakeOrderPlan._(
      photoPaths: List.unmodifiable(updatedPaths),
      selectedIndex: targetIndex,
      replacedPhotoPath: targetPhotoPath,
      alignmentContext: alignmentContext,
    );
  }

  static bool _replacementPathsAreSafe({
    required List<String> currentPhotoPaths,
    required List<String> replacementPhotoPaths,
  }) {
    if (!_receiptPhotoPathsAreUniqueAndNormalized(currentPhotoPaths)) {
      return false;
    }
    final seenReplacementPaths = <String>{};
    final currentPathSet = currentPhotoPaths.toSet();
    for (final path in replacementPhotoPaths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty || trimmed != path) return false;
      if (!seenReplacementPaths.add(path)) return false;
      if (currentPathSet.contains(path)) return false;
    }
    return true;
  }
}

bool _receiptPhotoPathsAreUniqueAndNormalized(List<String> photoPaths) {
  final seenPhotoPaths = <String>{};
  for (final path in photoPaths) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed != path) return false;
    if (!seenPhotoPaths.add(path)) return false;
  }
  return true;
}
