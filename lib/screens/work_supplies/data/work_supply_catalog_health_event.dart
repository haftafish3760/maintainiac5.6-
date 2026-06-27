import 'work_supply_catalog_hosted_import_validator.dart';

class WorkSupplyCatalogHealthEvent {
  const WorkSupplyCatalogHealthEvent({
    required this.event,
    required this.packId,
    required this.packVersion,
    required this.status,
    required this.isReady,
    required this.chunkCount,
    required this.itemCount,
    required this.issueCount,
    required this.firestoreManifestReadCount,
    required this.firestoreItemDocumentReadCount,
  });

  factory WorkSupplyCatalogHealthEvent.fromValidation(
    WorkSupplyHostedCatalogValidationResult validation,
  ) {
    final manifest = validation.manifest;
    return WorkSupplyCatalogHealthEvent(
      event: validation.isReady ? 'catalogPackReady' : 'catalogPackRejected',
      packId: _safeToken(manifest?.packId ?? 'unknown'),
      packVersion: _safeToken(manifest?.packVersion ?? 'unknown'),
      status: validation.status.name,
      isReady: validation.isReady,
      chunkCount: validation.checkedChunkCount,
      itemCount: validation.checkedItemCount,
      issueCount: validation.issues.length,
      firestoreManifestReadCount: manifest?.firestoreManifestReadCount ?? 0,
      firestoreItemDocumentReadCount:
          manifest?.firestoreItemDocumentReadCount ?? 0,
    );
  }

  final String event;
  final String packId;
  final String packVersion;
  final String status;
  final bool isReady;
  final int chunkCount;
  final int itemCount;
  final int issueCount;
  final int firestoreManifestReadCount;
  final int firestoreItemDocumentReadCount;

  Map<String, Object?> toMap() {
    return {
      'event': event,
      'featureArea': 'inventory_catalog',
      'packId': packId,
      'packVersion': packVersion,
      'status': status,
      'isReady': isReady,
      'chunkCount': chunkCount,
      'itemCount': itemCount,
      'issueCount': issueCount,
      'firestoreManifestReadCount': firestoreManifestReadCount,
      'firestoreItemDocumentReadCount': firestoreItemDocumentReadCount,
    };
  }
}

String _safeToken(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '')
      .toLowerCase();
}
