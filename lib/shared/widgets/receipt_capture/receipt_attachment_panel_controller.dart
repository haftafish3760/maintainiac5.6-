part of 'receipt_attachment_panel.dart';

/// Lets a purpose-built receipt form open the shared capture/import pipeline
/// without inheriting this panel's legacy visual layout.
class ReceiptAttachmentPanelController {
  Future<void> Function()? _openImportOptions;
  Future<void> Function(ReceiptSettingsScreenContext?)? _openSettings;

  bool get isAttached => _openImportOptions != null;

  Future<void> openImportOptions() async {
    final open = _openImportOptions;
    if (open == null) return;
    await open();
  }

  Future<void> openSettings({ReceiptSettingsScreenContext? screenContext}) async {
    final open = _openSettings;
    if (open == null) return;
    await open(screenContext);
  }

  void _bind({
    required Future<void> Function() openImportOptions,
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
