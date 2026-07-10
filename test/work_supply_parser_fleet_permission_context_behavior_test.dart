import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_destination.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  group('inventory parser fleet permission context behavior', () {
    test('parser candidate does not grant inventory permission', () {
      const candidate = _ParserCandidate(
        itemId: 'PLUMBING-PEX-90',
        reviewOnly: true,
        suggestedActions: {
          _InventoryAction.addToInventory,
          _InventoryAction.addToJob,
          _InventoryAction.addToEstimate,
          _InventoryAction.addToInvoice,
        },
      );
      const helper = _FleetUserContext(
        role: _FleetRole.helper,
        vehicleId: 'truck-1',
        permissions: {_FleetPermission.viewAssignedJobs},
      );

      final decision = _authorizeCandidateAction(
        user: helper,
        candidate: candidate,
        action: _InventoryAction.addToInventory,
      );

      expect(candidate.reviewOnly, isTrue);
      expect(decision.allowed, isFalse);
      expect(decision.warning, contains('permission denied'));
      expect(decision.warning, contains('review-only'));
    });

    test('owner can see company inventory while employee is vehicle-scoped', () {
      const owner = _FleetUserContext(
        role: _FleetRole.owner,
        vehicleId: 'truck-1',
        permissions: {
          _FleetPermission.manageCompanyInventory,
          _FleetPermission.viewCompanyInventory,
          _FleetPermission.viewVehicleInventory,
        },
      );
      const employee = _FleetUserContext(
        role: _FleetRole.employee,
        vehicleId: 'truck-2',
        permissions: {_FleetPermission.viewVehicleInventory},
      );
      const records = [
        _InventoryRecord(itemId: 'PEX-90', location: 'shop', vehicleId: null),
        _InventoryRecord(itemId: 'PEX-90', location: 'truck', vehicleId: 'truck-1'),
        _InventoryRecord(itemId: 'PEX-90', location: 'truck', vehicleId: 'truck-2'),
      ];

      expect(_visibleInventory(owner, records), hasLength(3));
      expect(_visibleInventory(employee, records), [
        const _InventoryRecord(
          itemId: 'PEX-90',
          location: 'truck',
          vehicleId: 'truck-2',
        ),
      ]);
    });

    test('vehicle inventory context can boost ranking without forcing match', () {
      const candidates = [
        _RankedCandidate(itemId: 'PVC-PLUMBING-90', trade: 'Plumbing', score: 74),
        _RankedCandidate(itemId: 'PVC-CONDUIT-90', trade: 'Electrical', score: 74),
      ];
      const inventory = [
        _InventoryRecord(
          itemId: 'PVC-CONDUIT-90',
          location: 'truck',
          vehicleId: 'truck-electrical',
        ),
      ];

      final ranked = _rankWithVehicleContext(
        candidates: candidates,
        vehicleId: 'truck-electrical',
        inventory: inventory,
      );

      expect(ranked.first.itemId, 'PVC-CONDUIT-90');
      expect(ranked.first.score, 79);
      expect(ranked.first.requiresReview, isTrue);
      expect(ranked.last.requiresReview, isTrue);
    });

    test('same item can exist in multiple vehicle locations', () {
      const records = [
        _InventoryRecord(itemId: 'WIRE-NUT', location: 'truck', vehicleId: 'truck-1'),
        _InventoryRecord(itemId: 'WIRE-NUT', location: 'truck', vehicleId: 'truck-2'),
        _InventoryRecord(itemId: 'WIRE-NUT', location: 'shop', vehicleId: null),
      ];

      final groups = _inventoryLocationsByItem(records);

      expect(groups['WIRE-NUT'], {
        'truck:truck-1',
        'truck:truck-2',
        'shop:company',
      });
    });

    test('inventory destinations expose company vehicle job staging and custom', () {
      final destinations = buildWorkSupplyInventoryDestinations(
        appState: AppStateController(),
        jobNumber: 'JOB-042',
      );

      expect(destinations, contains(workSupplyCompanyInventoryLabel));
      expect(destinations, contains(workSupplyActiveVehicleInventoryLabel));
      expect(destinations, contains('Work Truck 1 inventory'));
      expect(destinations, contains('Job staging - JOB-042'));
      expect(destinations, contains(workSupplyCustomDestinationLabel));
      expect(
        resolveWorkSupplyInventoryDestination(
          selectedDestination: workSupplyCustomDestinationLabel,
          customDestination: 'Trailer shelf 2',
        ),
        'Trailer shelf 2',
      );
    });

    test('admin rollup omits employee private data', () {
      const event = _ParserDiagnosticEvent(
        deviceClass: 'modern flagship',
        deviceModel: 'Galaxy S24',
        employeeId: 'employee-123',
        employeeName: 'Jordan Helper',
        rawReceiptText: 'LOWES CARD 1111 1/2 PEX 90',
        trade: 'Plumbing',
        itemId: 'PEX-90',
        failureCategory: 'ambiguous_match',
      );

      final rollup = _adminRollup(event);

      expect(rollup['deviceClass'], 'modern flagship');
      expect(rollup['deviceModel'], 'Galaxy S24');
      expect(rollup['trade'], 'Plumbing');
      expect(rollup['itemId'], 'PEX-90');
      expect(rollup['failureCategory'], 'ambiguous_match');
      expect(rollup.containsKey('employeeId'), isFalse);
      expect(rollup.containsKey('employeeName'), isFalse);
      expect(rollup.containsKey('rawReceiptText'), isFalse);
    });
  });
}

_AuthorizationDecision _authorizeCandidateAction({
  required _FleetUserContext user,
  required _ParserCandidate candidate,
  required _InventoryAction action,
}) {
  if (!candidate.suggestedActions.contains(action)) {
    return const _AuthorizationDecision(
      allowed: false,
      warning: 'action was not suggested by parser candidate',
    );
  }
  if (candidate.reviewOnly) {
    return const _AuthorizationDecision(
      allowed: false,
      warning: 'permission denied until review-only parser candidate is confirmed',
    );
  }
  final requiredPermission = switch (action) {
    _InventoryAction.addToInventory => _FleetPermission.manageVehicleInventory,
    _InventoryAction.addToJob => _FleetPermission.addJobMaterials,
    _InventoryAction.addToEstimate => _FleetPermission.addEstimateMaterials,
    _InventoryAction.addToInvoice => _FleetPermission.addInvoiceMaterials,
    _InventoryAction.transferVehicle => _FleetPermission.transferVehicleInventory,
    _InventoryAction.markOutOfStock => _FleetPermission.manageVehicleInventory,
  };
  return _AuthorizationDecision(
    allowed: user.permissions.contains(requiredPermission),
    warning: user.permissions.contains(requiredPermission)
        ? ''
        : 'permission denied for ${action.name}',
  );
}

List<_InventoryRecord> _visibleInventory(
  _FleetUserContext user,
  List<_InventoryRecord> records,
) {
  if (user.permissions.contains(_FleetPermission.viewCompanyInventory)) {
    return records;
  }
  if (user.permissions.contains(_FleetPermission.viewVehicleInventory)) {
    return [
      for (final record in records)
        if (record.vehicleId == user.vehicleId) record,
    ];
  }
  return const [];
}

List<_RankedCandidate> _rankWithVehicleContext({
  required List<_RankedCandidate> candidates,
  required String vehicleId,
  required List<_InventoryRecord> inventory,
}) {
  final vehicleItemIds = {
    for (final record in inventory)
      if (record.vehicleId == vehicleId) record.itemId,
  };
  final ranked = [
    for (final candidate in candidates)
      candidate.copyWith(
        score: vehicleItemIds.contains(candidate.itemId)
            ? candidate.score + 5
            : candidate.score,
        requiresReview: true,
      ),
  ]..sort((a, b) => b.score.compareTo(a.score));
  return ranked;
}

Map<String, Set<String>> _inventoryLocationsByItem(
  List<_InventoryRecord> records,
) {
  final grouped = <String, Set<String>>{};
  for (final record in records) {
    grouped
        .putIfAbsent(record.itemId, () => <String>{})
        .add('${record.location}:${record.vehicleId ?? 'company'}');
  }
  return grouped;
}

Map<String, Object?> _adminRollup(_ParserDiagnosticEvent event) {
  return {
    'deviceClass': event.deviceClass,
    'deviceModel': event.deviceModel,
    'trade': event.trade,
    'itemId': event.itemId,
    'failureCategory': event.failureCategory,
  };
}

class _ParserCandidate {
  const _ParserCandidate({
    required this.itemId,
    required this.reviewOnly,
    required this.suggestedActions,
  });

  final String itemId;
  final bool reviewOnly;
  final Set<_InventoryAction> suggestedActions;
}

class _FleetUserContext {
  const _FleetUserContext({
    required this.role,
    required this.vehicleId,
    required this.permissions,
  });

  final _FleetRole role;
  final String vehicleId;
  final Set<_FleetPermission> permissions;
}

class _AuthorizationDecision {
  const _AuthorizationDecision({
    required this.allowed,
    required this.warning,
  });

  final bool allowed;
  final String warning;
}

class _InventoryRecord {
  const _InventoryRecord({
    required this.itemId,
    required this.location,
    required this.vehicleId,
  });

  final String itemId;
  final String location;
  final String? vehicleId;
}

class _RankedCandidate {
  const _RankedCandidate({
    required this.itemId,
    required this.trade,
    required this.score,
    this.requiresReview = true,
  });

  final String itemId;
  final String trade;
  final int score;
  final bool requiresReview;

  _RankedCandidate copyWith({int? score, bool? requiresReview}) {
    return _RankedCandidate(
      itemId: itemId,
      trade: trade,
      score: score ?? this.score,
      requiresReview: requiresReview ?? this.requiresReview,
    );
  }
}

class _ParserDiagnosticEvent {
  const _ParserDiagnosticEvent({
    required this.deviceClass,
    required this.deviceModel,
    required this.employeeId,
    required this.employeeName,
    required this.rawReceiptText,
    required this.trade,
    required this.itemId,
    required this.failureCategory,
  });

  final String deviceClass;
  final String deviceModel;
  final String employeeId;
  final String employeeName;
  final String rawReceiptText;
  final String trade;
  final String itemId;
  final String failureCategory;
}

enum _FleetRole { owner, employee, helper }

enum _FleetPermission {
  viewAssignedJobs,
  viewVehicleInventory,
  viewCompanyInventory,
  manageVehicleInventory,
  manageCompanyInventory,
  addJobMaterials,
  addEstimateMaterials,
  addInvoiceMaterials,
  transferVehicleInventory,
}

enum _InventoryAction {
  addToInventory,
  addToJob,
  addToEstimate,
  addToInvoice,
  transferVehicle,
  markOutOfStock,
}
