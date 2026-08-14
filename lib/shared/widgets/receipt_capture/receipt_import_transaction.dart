import 'receipt_capture_models.dart';

/// A source the user can choose from the preserved Add Receipt screen.
enum ReceiptImportSourceAction {
  camera,
  image,
  pdf,
  savedText,
  pasteText,
  settings,
  shareHelp,
}

enum ReceiptImportActionDisposition { stayOnChooser, completed }

/// The explicit result of one source-chooser transaction.
///
/// This replaces the previous boolean where `true` could mean anything from
/// "the picker opened" to "receipt review finished". A review result remains
/// attached so later route owners can distinguish Continue, Save draft, and
/// Discard without guessing from navigator state.
class ReceiptImportActionResult {
  const ReceiptImportActionResult.stayOnChooser()
    : disposition = ReceiptImportActionDisposition.stayOnChooser,
      reviewResult = null;

  const ReceiptImportActionResult.completed()
    : disposition = ReceiptImportActionDisposition.completed,
      reviewResult = null;

  const ReceiptImportActionResult.reviewCompleted(this.reviewResult)
    : disposition = ReceiptImportActionDisposition.completed;

  final ReceiptImportActionDisposition disposition;
  final ReceiptPhotoReviewResult? reviewResult;

  bool get closesChooser =>
      disposition == ReceiptImportActionDisposition.completed;

  bool get exitsReceiptFlow => reviewResult?.exitsReceiptFlow ?? false;
}

/// Side-effect policy for a completed photo-review decision.
///
/// Keeping this policy independent from Navigator and platform pickers makes
/// the safety rule executable in tests: Continue is the only decision that
/// may start receipt reading, Save draft retains proof without reading it, and
/// Discard may only remove app-owned staged copies.
class ReceiptReviewHandoffPlan {
  const ReceiptReviewHandoffPlan._({
    required this.installReviewedPhotos,
    required this.retainReviewedSources,
    required this.notifyReceiptDetails,
    required this.startReceiptRead,
    required this.discardStagedPhotos,
    required this.exitsReceiptFlow,
  });

  factory ReceiptReviewHandoffPlan.forOutcome(
    ReceiptPhotoReviewOutcome outcome, {
    bool assistedReceiptFill = true,
  }) {
    return switch (outcome) {
      ReceiptPhotoReviewOutcome.acceptedForReceiptDetails =>
        ReceiptReviewHandoffPlan._(
          installReviewedPhotos: true,
          retainReviewedSources: true,
          notifyReceiptDetails: true,
          startReceiptRead: assistedReceiptFill,
          discardStagedPhotos: false,
          exitsReceiptFlow: false,
        ),
      ReceiptPhotoReviewOutcome.saveDraftAndExit =>
        const ReceiptReviewHandoffPlan._(
          installReviewedPhotos: true,
          retainReviewedSources: true,
          notifyReceiptDetails: false,
          startReceiptRead: false,
          discardStagedPhotos: false,
          exitsReceiptFlow: true,
        ),
      ReceiptPhotoReviewOutcome.discardAndExit =>
        const ReceiptReviewHandoffPlan._(
          installReviewedPhotos: false,
          retainReviewedSources: false,
          notifyReceiptDetails: false,
          startReceiptRead: false,
          discardStagedPhotos: true,
          exitsReceiptFlow: true,
        ),
    };
  }

  final bool installReviewedPhotos;
  final bool retainReviewedSources;
  final bool notifyReceiptDetails;
  final bool startReceiptRead;
  final bool discardStagedPhotos;
  final bool exitsReceiptFlow;
}
