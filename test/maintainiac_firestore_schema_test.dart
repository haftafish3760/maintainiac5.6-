import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_audit.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';

void main() {
  test('Firestore schema exposes hosted catalog collection paths', () {
    expect(MaintainiacFirestoreSchema.catalogPacks, 'catalogPacks');
    expect(MaintainiacFirestoreSchema.catalogPackManifests, 'manifests');
    expect(
      MaintainiacFirestoreSchema.catalogPackDocumentPath(
        workSupplyCatalogPackId,
      ),
      'catalogPacks/$workSupplyCatalogPackId',
    );
    expect(
      MaintainiacFirestoreSchema.catalogPackManifestDocumentPath(
        workSupplyCatalogPackId,
        workSupplyCatalogPackVersion,
      ),
      workSupplyCatalogManifestDocumentPath,
    );
  });

  test('Firestore schema exposes privacy-safe command center collections', () {
    expect(MaintainiacFirestoreSchema.parserHealth, 'parserHealth');
    expect(
      MaintainiacFirestoreSchema.orgExpenseTelemetrySummaries,
      'expenseTelemetrySummaries',
    );
    expect(MaintainiacFirestoreSchema.orgSettings, 'settings');
    expect(MaintainiacFirestoreSchema.catalogHealth, 'catalogHealth');
    expect(
      MaintainiacFirestoreSchema.sharedCorrectionCandidates,
      'sharedCorrectionCandidates',
    );
    expect(
      MaintainiacFirestoreSchema.aiAbuseSecurityEvents,
      'aiAbuseSecurityEvents',
    );
    expect(
      MaintainiacFirestoreSchema.aiEnforcementActions,
      'aiEnforcementActions',
    );
    expect(
      MaintainiacFirestoreSchema.orgCollectionPath(
        'ORG-1',
        MaintainiacFirestoreSchema.orgReceiptDiagnostics,
      ),
      'orgs/ORG-1/receiptDiagnostics',
    );
  });

  test('Storage schema matches work supply catalog chunk prefix', () {
    expect(
      MaintainiacStorageSchema.workSupplyCatalogPrefix(
        workSupplyCatalogPackVersion,
      ),
      workSupplyCatalogStoragePrefix,
    );
  });

  test(
    'Firestore docs describe manifest plus Storage chunks, not item docs',
    () {
      final spec = File('docs/firebase_sync_schema_spec.md').readAsStringSync();

      expect(spec, contains('catalogPacks/{packId}'));
      expect(spec, contains('catalogPacks/{packId}/manifests/{versionId}'));
      expect(spec, contains('catalog-packs/work-supplies/{version}'));
      expect(
        spec,
        contains('must not read one Firestore document per catalog item'),
      );
    },
  );
}
