import 'receipt_photo_path_identity.dart';

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

  String get guidanceText {
    return switch (guidanceCode) {
      'retake_middle_with_previous_next_context' =>
        'Retake this middle receipt section using the previous and next sections as alignment context.',
      'retake_bottom_with_previous_context' =>
        'Retake the bottom receipt section using the previous section as the top ghost guide.',
      'retake_top_with_next_context' =>
        'Retake the top receipt section and check that it still joins cleanly with the next section.',
      _ =>
        'Retake this receipt section and verify the receipt order before OCR.',
    };
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
    required this.replacementPhotoPaths,
    required this.alignmentContext,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final String replacedPhotoPath;
  final List<String> replacementPhotoPaths;
  final ReceiptPhotoRetakeAlignmentContext alignmentContext;

  int get originalSectionNumber => alignmentContext.targetIndex + 1;

  Map<String, Map<String, Object?>> captureDiagnosticsForReplacementPaths(
    List<String> replacementPhotoPaths,
  ) {
    if (!_orderedPhotoPathsMatch(
      this.replacementPhotoPaths,
      replacementPhotoPaths,
    )) {
      return const {};
    }
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
          if (alignmentContext.hasPreviousContext)
            'receiptRetakePreviousContextSectionNumber':
                alignmentContext.targetIndex,
          if (alignmentContext.hasNextContext)
            'receiptRetakeNextContextSectionNumber':
                alignmentContext.targetIndex + 2,
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
      replacementPhotoPaths: List.unmodifiable(replacementPhotoPaths),
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
    return _newReceiptPhotoPathsAreSafe(
      currentPhotoPaths: currentPhotoPaths,
      newPhotoPaths: replacementPhotoPaths,
    );
  }
}

class ReceiptPhotoInsertAfterOrderPlan {
  const ReceiptPhotoInsertAfterOrderPlan._({
    required this.photoPaths,
    required this.selectedIndex,
    required this.anchorIndex,
    required this.anchorPhotoPath,
    required this.insertedPhotoPaths,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final int anchorIndex;
  final String anchorPhotoPath;
  final List<String> insertedPhotoPaths;

  int get anchorSectionNumber => anchorIndex + 1;

  Map<String, Map<String, Object?>> captureDiagnosticsForInsertedPhotoPaths(
    List<String> insertedPhotoPaths,
  ) {
    if (!_orderedPhotoPathsMatch(this.insertedPhotoPaths, insertedPhotoPaths)) {
      return const {};
    }
    return {
      for (var offset = 0; offset < insertedPhotoPaths.length; offset++)
        insertedPhotoPaths[offset]: {
          'receiptInsertAfterAnchorSectionNumber': anchorSectionNumber,
          'receiptInsertAfterOffset': offset,
          'receiptInsertFinalSectionNumber': anchorSectionNumber + offset + 1,
          'receiptInsertPreservedAnchorSlot': true,
          'receiptInsertOrderPolicy':
              'insert_new_sections_after_selected_anchor',
        },
    };
  }

  static ReceiptPhotoInsertAfterOrderPlan? build({
    required List<String> currentPhotoPaths,
    required int anchorIndex,
    required String anchorPhotoPath,
    required List<String> insertedPhotoPaths,
  }) {
    if (insertedPhotoPaths.isEmpty) return null;
    if (!_receiptPhotoPathsAreUniqueAndNormalized(currentPhotoPaths)) {
      return null;
    }
    if (!_newReceiptPhotoPathsAreSafe(
      currentPhotoPaths: currentPhotoPaths,
      newPhotoPaths: insertedPhotoPaths,
    )) {
      return null;
    }
    if (anchorIndex < 0 || anchorIndex >= currentPhotoPaths.length) {
      return null;
    }
    if (currentPhotoPaths[anchorIndex] != anchorPhotoPath) return null;

    final insertIndex = anchorIndex + 1;
    final updatedPaths = List<String>.of(currentPhotoPaths)
      ..insertAll(insertIndex, insertedPhotoPaths);
    return ReceiptPhotoInsertAfterOrderPlan._(
      photoPaths: List.unmodifiable(updatedPaths),
      selectedIndex: insertIndex,
      anchorIndex: anchorIndex,
      anchorPhotoPath: anchorPhotoPath,
      insertedPhotoPaths: List.unmodifiable(insertedPhotoPaths),
    );
  }
}

class ReceiptPhotoRemovalOrderPlan {
  const ReceiptPhotoRemovalOrderPlan._({
    required this.photoPaths,
    required this.selectedIndex,
    required this.removedPhotoPath,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final String removedPhotoPath;

  static ReceiptPhotoRemovalOrderPlan? build({
    required List<String> currentPhotoPaths,
    required int targetIndex,
    required String targetPhotoPath,
  }) {
    if (currentPhotoPaths.length <= 1) return null;
    if (!_receiptPhotoPathsAreUniqueAndNormalized(currentPhotoPaths)) {
      return null;
    }
    if (targetIndex < 0 || targetIndex >= currentPhotoPaths.length) {
      return null;
    }
    if (currentPhotoPaths[targetIndex] != targetPhotoPath) return null;

    final updatedPaths = List<String>.of(currentPhotoPaths)
      ..removeAt(targetIndex);
    return ReceiptPhotoRemovalOrderPlan._(
      photoPaths: List.unmodifiable(updatedPaths),
      selectedIndex: targetIndex >= updatedPaths.length
          ? updatedPaths.length - 1
          : targetIndex,
      removedPhotoPath: targetPhotoPath,
    );
  }
}

class ReceiptPhotoMoveOrderPlan {
  const ReceiptPhotoMoveOrderPlan._({
    required this.photoPaths,
    required this.selectedIndex,
    required this.movedPhotoPath,
    required this.originalIndex,
    required this.finalIndex,
  });

  final List<String> photoPaths;
  final int selectedIndex;
  final String movedPhotoPath;
  final int originalIndex;
  final int finalIndex;

  int get originalSectionNumber => originalIndex + 1;
  int get finalSectionNumber => finalIndex + 1;
  String get directionCode => finalIndex < originalIndex ? 'earlier' : 'later';

  Map<String, Object?> captureDiagnosticsForMovedPhotoPath(
    String movedPhotoPath,
  ) {
    if (this.movedPhotoPath != movedPhotoPath) return const {};
    return {
      'receiptManualReorderOriginalSectionNumber': originalSectionNumber,
      'receiptManualReorderFinalSectionNumber': finalSectionNumber,
      'receiptManualReorderDirection': directionCode,
      'receiptManualReorderPreservedPhotoPath': true,
      'receiptManualReorderPolicy': 'user_reordered_sections_preserve_paths',
    };
  }

  static ReceiptPhotoMoveOrderPlan? build({
    required List<String> currentPhotoPaths,
    required int selectedIndex,
    required String selectedPhotoPath,
    required int direction,
  }) {
    if (direction != -1 && direction != 1) return null;
    if (!_receiptPhotoPathsAreUniqueAndNormalized(currentPhotoPaths)) {
      return null;
    }
    if (selectedIndex < 0 || selectedIndex >= currentPhotoPaths.length) {
      return null;
    }
    if (currentPhotoPaths[selectedIndex] != selectedPhotoPath) return null;
    final targetIndex = selectedIndex + direction;
    if (targetIndex < 0 || targetIndex >= currentPhotoPaths.length) {
      return null;
    }

    final updatedPaths = List<String>.of(currentPhotoPaths);
    updatedPaths[selectedIndex] = updatedPaths[targetIndex];
    updatedPaths[targetIndex] = selectedPhotoPath;
    return ReceiptPhotoMoveOrderPlan._(
      photoPaths: List.unmodifiable(updatedPaths),
      selectedIndex: targetIndex,
      movedPhotoPath: selectedPhotoPath,
      originalIndex: selectedIndex,
      finalIndex: targetIndex,
    );
  }
}

bool _receiptPhotoPathsAreUniqueAndNormalized(List<String> photoPaths) {
  return receiptPhotoPathsAreUniqueAndNormalized(photoPaths);
}

bool _newReceiptPhotoPathsAreSafe({
  required List<String> currentPhotoPaths,
  required List<String> newPhotoPaths,
}) {
  final seenNewPaths = <String>{};
  final currentPathSet = {
    for (final photoPath in currentPhotoPaths)
      ?normalizedReceiptPhotoPath(photoPath),
  };
  for (final photoPath in newPhotoPaths) {
    final normalized = normalizedReceiptPhotoPath(photoPath);
    if (normalized == null) return false;
    if (!seenNewPaths.add(normalized)) return false;
    if (currentPathSet.contains(normalized)) return false;
  }
  return true;
}

bool _orderedPhotoPathsMatch(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
