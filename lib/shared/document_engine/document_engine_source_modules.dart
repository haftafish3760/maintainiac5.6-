/// Engine-owned source labels for generated documents and export packages.
/// Feature screens should use these constants instead of local magic strings.
abstract final class MaintainiacDocumentSourceModule {
  static const String documentEngine = 'document_engine';
  static const String expenses = 'expenses';
  static const String invoices = 'invoices';
  static const String receipts = 'receipts';
  static const String estimates = 'estimates';
  static const String jobs = 'jobs';
  static const String customers = 'customers';
  static const String maintenance = 'maintenance';
  static const String reports = 'reports';
  static const String exports = 'exports';
}
