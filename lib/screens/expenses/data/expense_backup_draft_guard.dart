import '../../../shared/firebase/maintainiac_firestore_documents.dart';
import '../../../shared/firebase/maintainiac_firestore_upload_queue.dart';

/// Rejects a cloud backup before it can discard part of a durable record.
///
/// Expense metadata is intentionally one document per receipt. A document that
/// cannot fit the guarded Firestore limit remains local and is never truncated
/// to make a backup appear successful.
class ExpenseBackupDraftGuard {
  const ExpenseBackupDraftGuard._();

  static String? rejectionFor(
    Iterable<MaintainiacFirestoreDocumentDraft> drafts,
  ) {
    try {
      for (final draft in drafts) {
        MaintainiacFirestoreUploadPolicy.validateDraft(draft);
      }
      return null;
    } on ArgumentError catch (error) {
      final detail = error.toString();
      if (detail.contains('document is too large')) {
        return 'This record is too large for the current single-document backup. '
            'It remains safely stored on this device and will need the future '
            'large-record backup path.';
      }
      return 'This record cannot be backed up safely. It remains stored on this device.';
    }
  }
}
