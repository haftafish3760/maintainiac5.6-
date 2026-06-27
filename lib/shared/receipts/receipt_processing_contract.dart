enum ReceiptProcessingSource { none, photo, pdf, importedText, mixed }

enum ReceiptProcessingStage {
  noSource,
  textExtracted,
  parsed,
  stagedForReview,
  reviewed,
  saveReady,
}

enum ReceiptSaveDestination {
  undecided,
  expenseOnly,
  inventoryReview,
  inventoryConfirmed,
  maintenanceReview,
}

enum ReceiptReviewLane {
  unmatched,
  inventory,
  businessExpense,
  personal,
  split,
}

class ReceiptProcessingSnapshot {
  const ReceiptProcessingSnapshot({
    required this.source,
    required this.stage,
    required this.destination,
    this.lineCount = 0,
    this.needsReview = true,
    this.warningCount = 0,
  });

  const ReceiptProcessingSnapshot.noSource()
    : this(
        source: ReceiptProcessingSource.none,
        stage: ReceiptProcessingStage.noSource,
        destination: ReceiptSaveDestination.undecided,
      );

  final ReceiptProcessingSource source;
  final ReceiptProcessingStage stage;
  final ReceiptSaveDestination destination;
  final int lineCount;
  final bool needsReview;
  final int warningCount;

  bool get hasSource => source != ReceiptProcessingSource.none;
  bool get hasLines => lineCount > 0;
  bool get hasExtractedText =>
      stage.index >= ReceiptProcessingStage.textExtracted.index;
  bool get hasParsedData => stage.index >= ReceiptProcessingStage.parsed.index;
  bool get isStagedForReview =>
      stage.index >= ReceiptProcessingStage.stagedForReview.index;
  bool get canCommitInventory =>
      destination == ReceiptSaveDestination.inventoryConfirmed &&
      stage == ReceiptProcessingStage.saveReady &&
      !needsReview;

  ReceiptProcessingSnapshot copyWith({
    ReceiptProcessingSource? source,
    ReceiptProcessingStage? stage,
    ReceiptSaveDestination? destination,
    int? lineCount,
    bool? needsReview,
    int? warningCount,
  }) {
    return ReceiptProcessingSnapshot(
      source: source ?? this.source,
      stage: stage ?? this.stage,
      destination: destination ?? this.destination,
      lineCount: lineCount ?? this.lineCount,
      needsReview: needsReview ?? this.needsReview,
      warningCount: warningCount ?? this.warningCount,
    );
  }
}
