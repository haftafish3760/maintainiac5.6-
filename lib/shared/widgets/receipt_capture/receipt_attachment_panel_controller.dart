part of 'receipt_attachment_panel.dart';

enum ReceiptImportEntryIntent { standardReceiptEntry, optionalManualProof }

/// Lets a purpose-built receipt form open the shared capture/import pipeline
/// without inheriting this panel's legacy visual layout.
class ReceiptAttachmentPanelController {
  Future<ReceiptImportActionResult?> Function(ReceiptImportEntryIntent)?
  _openImportOptions;
  Future<void> Function(ReceiptSettingsScreenContext?)? _openSettings;
  final _artifactTracker = ReceiptSessionArtifactTracker();

  bool get isAttached => _openImportOptions != null;

  Future<ReceiptImportActionResult?> openImportOptions({
    ReceiptImportEntryIntent intent =
        ReceiptImportEntryIntent.standardReceiptEntry,
  }) async {
    final open = _openImportOptions;
    if (open == null) return null;
    return open(intent);
  }

  Future<void> openSettings({
    ReceiptSettingsScreenContext? screenContext,
  }) async {
    final open = _openSettings;
    if (open == null) return;
    await open(screenContext);
  }

  /// Finalizes temporary receipt sources only after the owning receipt record
  /// and its permanent saved images have both been written successfully.
  Future<void> finalizeSuccessfulReceiptSave({
    required Iterable<String> keptReceiptPhotoPaths,
  }) async {
    await _artifactTracker.finalizeSuccessfulSave(
      keptReceiptPhotoPaths: keptReceiptPhotoPaths,
    );
  }

  /// Deletes only tracked Maintainiac-owned staging after an explicit discard.
  Future<void> discardReceiptSession() {
    return _artifactTracker.discardSession();
  }

  void _retainAcceptedReceiptSources(ReceiptPhotoReviewResult result) {
    _artifactTracker.retainReviewSources(result);
  }

  void _retainNativeRecoveryManifest(String manifestPath) {
    _artifactTracker.retainRecoveryManifest(manifestPath);
  }

  void _bind({
    required Future<ReceiptImportActionResult?> Function(
      ReceiptImportEntryIntent,
    )
    openImportOptions,
    required Future<void> Function(ReceiptSettingsScreenContext?) openSettings,
  }) {
    _openImportOptions = openImportOptions;
    _openSettings = openSettings;
  }

  void _detach() {
    _openImportOptions = null;
    _openSettings = null;
  }
}

/// Gives one receipt screen a clear settings title and tells the user which
/// controls belong in the form rather than in persistent preferences.
class ReceiptSettingsScreenContext {
  const ReceiptSettingsScreenContext({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.workflowNote,
  });

  final String title;
  final String subtitle;
  final String description;
  final String workflowNote;
}
