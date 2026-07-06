/// Engine-owned source module labels for generated documents and export
/// packages. Feature screens should use these constants instead of local magic
/// strings so document ownership stays deterministic across app modules.
abstract final class MaintainiacDocumentSourceModule {
  static const String documentEngine = 'document_engine';
  static const String expenses = 'expenses';
  static const String invoices = 'invoices';
  static const String receipts = 'receipts';
  static const String estimates = 'estimates';
  static const String reports = 'reports';
}
