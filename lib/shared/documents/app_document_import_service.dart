import '../widgets/receipt_capture/receipt_capture_models.dart';
import '../widgets/receipt_capture/receipt_proof_storage.dart';
import 'app_document_models.dart';
import 'app_document_store.dart';

class AppDocumentImportService {
  const AppDocumentImportService({
    this.store,
    this.proofStorage = ReceiptProofStorage.instance,
  });

  final AppDocumentStore? store;
  final ReceiptProofStorage proofStorage;

  Future<AppDocumentRecord> saveReadOnlyDocument({
    required AppDocumentKind kind,
    required List<ReceiptAttachmentRecord> attachments,
    String title = '',
    String importedText = '',
    String notes = '',
    String sourceLabel = 'Shared import',
    DateTime? now,
  }) async {
    final savedAt = now ?? DateTime.now();
    final id = 'DOC-${savedAt.microsecondsSinceEpoch}';
    final linkedAttachments = attachments
        .map(
          (attachment) => attachment.copyWith(
            linkedModule: kind.storageModule,
            linkedRecordId: id,
          ),
        )
        .toList(growable: false);
    var promoted = const <ReceiptAttachmentRecord>[];
    try {
      promoted = await proofStorage.persistAttachments(linkedAttachments);
      final documentStore = store ?? await AppDocumentStore.create();
      return documentStore.saveRecord(
        AppDocumentRecord(
          id: id,
          kind: kind,
          title: title.trim(),
          importedText: importedText.trim(),
          notes: notes.trim(),
          sourceLabel: sourceLabel.trim(),
          createdAt: savedAt,
          updatedAt: savedAt,
          attachments: List.unmodifiable(promoted),
        ),
      );
    } catch (_) {
      await proofStorage.rollbackPersistedAttachments(
        promoted,
        linkedAttachments,
      );
      rethrow;
    }
  }
}
