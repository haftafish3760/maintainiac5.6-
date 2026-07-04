import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inventory parser barcode identity behavior', () {
    test(
      'unknown barcode creates review candidate but not inventory truth',
      () {
        const resolver = _BarcodeIdentityResolver();

        final result = resolver.resolve(
          barcode: '000111222333',
          receiptCandidateId: '',
          knownMappings: const {},
        );

        expect(result.reviewRequired, isTrue);
        expect(result.suggestedItemId, 'unknown_barcode');
        expect(result.localInventoryWriteAllowed, isFalse);
        expect(result.officialPackMutationAllowed, isFalse);
        expect(result.evidence, contains('unknown_barcode_stays_review_only'));
        expect(
          result.evidence,
          contains('barcode_scan_can_create_review_candidate'),
        );
      },
    );

    test('barcode receipt disagreement keeps ranked alternatives', () {
      const resolver = _BarcodeIdentityResolver();

      final result = resolver.resolve(
        barcode: '999888777666',
        receiptCandidateId: 'plumbing.pvc.schedule_40_coupling',
        knownMappings: const {
          '999888777666': 'electrical.pvc.conduit_coupling',
        },
      );

      expect(result.reviewRequired, isTrue);
      expect(result.suggestedItemId, 'electrical.pvc.conduit_coupling');
      expect(
        result.alternatives,
        contains('plumbing.pvc.schedule_40_coupling'),
      );
      expect(
        result.evidence,
        contains('barcode_receipt_disagreement_requires_review'),
      );
      expect(
        result.evidence,
        contains('barcode_evidence_never_bypasses_conflict_rules'),
      );
      expect(result.localInventoryWriteAllowed, isFalse);
    });

    test('user confirmation stores private memory before pack promotion', () {
      const resolver = _BarcodeIdentityResolver();

      final result = resolver.confirmLocalMapping(
        barcode: '123456789012',
        confirmedItemId: 'hvac.condensate.pvc_elbow',
      );

      expect(result.reviewRequired, isFalse);
      expect(result.localInventoryWriteAllowed, isTrue);
      expect(result.officialPackMutationAllowed, isFalse);
      expect(
        result.evidence,
        contains('user_scanned_barcode_maps_to_private_inventory_memory_first'),
      );
      expect(
        result.evidence,
        contains('barcode_mapping_requires_user_confirmation'),
      );
      expect(
        result.evidence,
        contains('retailer_database_scraping_is_forbidden'),
      );
    });

    test('same catalog barcode can exist on multiple vehicles separately', () {
      const resolver = _BarcodeIdentityResolver();

      final truckOne = resolver.placeOnVehicle(
        barcode: '456789012345',
        catalogItemId: 'plumbing.pvc.schedule_40_coupling',
        vehicleId: 'truck_1',
        bin: 'left_bin_a',
      );
      final truckTwo = resolver.placeOnVehicle(
        barcode: '456789012345',
        catalogItemId: 'plumbing.pvc.schedule_40_coupling',
        vehicleId: 'truck_2',
        bin: 'right_drawer_3',
      );

      expect(truckOne.suggestedItemId, truckTwo.suggestedItemId);
      expect(truckOne.vehicleId, isNot(truckTwo.vehicleId));
      expect(truckOne.bin, isNot(truckTwo.bin));
      expect(truckOne.localInventoryWriteAllowed, isTrue);
      expect(truckTwo.localInventoryWriteAllowed, isTrue);
      expect(truckOne.officialPackMutationAllowed, isFalse);
      expect(truckTwo.officialPackMutationAllowed, isFalse);
      expect(
        truckOne.evidence,
        contains('same_catalog_item_can_exist_on_multiple_vehicles'),
      );
      expect(
        truckTwo.evidence,
        contains('fleet_vehicle_inventory_is_separate_from_catalog'),
      );
    });
  });
}

class _BarcodeIdentityResolver {
  const _BarcodeIdentityResolver();

  _BarcodeIdentityResult resolve({
    required String barcode,
    required String receiptCandidateId,
    required Map<String, String> knownMappings,
  }) {
    final mappedItemId = knownMappings[barcode];
    if (mappedItemId == null) {
      return const _BarcodeIdentityResult(
        suggestedItemId: 'unknown_barcode',
        alternatives: [],
        reviewRequired: true,
        localInventoryWriteAllowed: false,
        officialPackMutationAllowed: false,
        evidence: [
          'unknown_barcode_stays_review_only',
          'barcode_scan_can_create_review_candidate',
          'barcode_missing_does_not_block_receipt_parser',
        ],
      );
    }
    final disagreement =
        receiptCandidateId.isNotEmpty && receiptCandidateId != mappedItemId;
    return _BarcodeIdentityResult(
      suggestedItemId: mappedItemId,
      alternatives: disagreement
          ? [receiptCandidateId, mappedItemId]
          : [mappedItemId],
      reviewRequired: disagreement,
      localInventoryWriteAllowed: false,
      officialPackMutationAllowed: false,
      evidence: [
        'barcode_can_link_to_canonical_item',
        'barcode_can_boost_confidence_only_with_corroborating_evidence',
        if (disagreement) 'barcode_receipt_disagreement_requires_review',
        if (disagreement) 'barcode_evidence_never_bypasses_conflict_rules',
      ],
    );
  }

  _BarcodeIdentityResult confirmLocalMapping({
    required String barcode,
    required String confirmedItemId,
  }) {
    return _BarcodeIdentityResult(
      suggestedItemId: confirmedItemId,
      alternatives: [confirmedItemId],
      reviewRequired: false,
      localInventoryWriteAllowed: true,
      officialPackMutationAllowed: false,
      evidence: const [
        'user_scanned_barcode_maps_to_private_inventory_memory_first',
        'barcode_mapping_requires_user_confirmation',
        'retailer_database_scraping_is_forbidden',
      ],
    );
  }

  _VehicleBarcodePlacement placeOnVehicle({
    required String barcode,
    required String catalogItemId,
    required String vehicleId,
    required String bin,
  }) {
    return _VehicleBarcodePlacement(
      barcode: barcode,
      suggestedItemId: catalogItemId,
      vehicleId: vehicleId,
      bin: bin,
      localInventoryWriteAllowed: true,
      officialPackMutationAllowed: false,
      evidence: const [
        'same_catalog_item_can_exist_on_multiple_vehicles',
        'fleet_vehicle_inventory_is_separate_from_catalog',
        'bin_drawer_location_is_not_parser_identity',
        'vehicle_location_is_user_inventory_metadata',
      ],
    );
  }
}

class _BarcodeIdentityResult {
  const _BarcodeIdentityResult({
    required this.suggestedItemId,
    required this.alternatives,
    required this.reviewRequired,
    required this.localInventoryWriteAllowed,
    required this.officialPackMutationAllowed,
    required this.evidence,
  });

  final String suggestedItemId;
  final List<String> alternatives;
  final bool reviewRequired;
  final bool localInventoryWriteAllowed;
  final bool officialPackMutationAllowed;
  final List<String> evidence;
}

class _VehicleBarcodePlacement {
  const _VehicleBarcodePlacement({
    required this.barcode,
    required this.suggestedItemId,
    required this.vehicleId,
    required this.bin,
    required this.localInventoryWriteAllowed,
    required this.officialPackMutationAllowed,
    required this.evidence,
  });

  final String barcode;
  final String suggestedItemId;
  final String vehicleId;
  final String bin;
  final bool localInventoryWriteAllowed;
  final bool officialPackMutationAllowed;
  final List<String> evidence;
}
