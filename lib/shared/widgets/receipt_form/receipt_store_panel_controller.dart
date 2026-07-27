part of 'receipt_store_panel.dart';

/// Opens the shared store editor from a purpose-built receipt layout without
/// duplicating field rules or the editor's draft behavior.
class SharedReceiptStorePanelController {
  Future<void> Function()? _openEditor;

  bool get isAvailable => _openEditor != null;

  Future<void> openEditor() async {
    final open = _openEditor;
    if (open == null) return;
    await open();
  }

  void _bind(Future<void> Function() openEditor) {
    _openEditor = openEditor;
  }

  void _detach() {
    _openEditor = null;
  }
}
