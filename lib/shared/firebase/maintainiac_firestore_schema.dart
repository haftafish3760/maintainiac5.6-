class MaintainiacFirestoreSchema {
  const MaintainiacFirestoreSchema._();

  static const orgs = 'orgs';
  static const catalogPacks = 'catalogPacks';
  static const vendorRegistry = 'vendorRegistry';
  static const parserHealth = 'parserHealth';
  static const catalogHealth = 'catalogHealth';
  static const sharedCorrectionCandidates = 'sharedCorrectionCandidates';
  static const aiAbuseSecurityEvents = 'aiAbuseSecurityEvents';
  static const aiEnforcementActions = 'aiEnforcementActions';

  static const orgMembers = 'members';
  static const orgInvites = 'invites';
  static const orgVehicles = 'vehicles';
  static const orgExpenses = 'expenses';
  static const orgMileageRecords = 'mileageRecords';
  static const orgDashboardSummaries = 'dashboardSummaries';
  static const orgReceiptProofs = 'proofs';
  static const orgSettings = 'settings';
  static const orgInventoryItems = 'inventoryItems';
  static const orgInventoryReceipts = 'inventoryReceipts';
  static const orgInventoryTransactions = 'inventoryTransactions';
  static const orgReceiptDiagnostics = 'receiptDiagnostics';
  static const orgExpenseTelemetrySummaries = 'expenseTelemetrySummaries';
  static const orgAuditEvents = 'auditEvents';
  static const orgSyncManifests = 'syncManifests';

  static const catalogPackManifests = 'manifests';
  static const vendorProfiles = 'profiles';
  static const vendorAliases = 'aliases';

  static String catalogPackDocumentPath(String packId) {
    return '$catalogPacks/$packId';
  }

  static String catalogPackManifestDocumentPath(String packId, String version) {
    return '$catalogPacks/$packId/$catalogPackManifests/$version';
  }

  static String orgCollectionPath(String orgId, String collectionId) {
    return '$orgs/$orgId/$collectionId';
  }

  static String userCollectionPath(String uid, String collectionId) {
    return 'users/$uid/$collectionId';
  }
}

class MaintainiacStorageSchema {
  const MaintainiacStorageSchema._();

  static const catalogPacksPrefix = 'catalog-packs';
  static const receiptProofsPrefix = 'receipt-proofs';
  static const exportBundlesPrefix = 'export-bundles';

  static String workSupplyCatalogPrefix(String version) {
    return '$catalogPacksPrefix/work-supplies/$version';
  }
}
