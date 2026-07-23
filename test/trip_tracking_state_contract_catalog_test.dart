import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_contract_catalog.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_state_machine.dart';

void main() {
  test('every canonical state has one complete behavior contract', () {
    final contracts = TripTrackingStateContractCatalog.all;
    expect(
      contracts.map((contract) => contract.state).toSet(),
      TripTrackingSessionLifecycleContractState.values.toSet(),
    );
    expect(
      contracts.map((contract) => contract.diagnosticEvent).toSet().length,
      contracts.length,
    );

    for (final contract in contracts) {
      expect(
        contract.definition.trim(),
        isNotEmpty,
        reason: contract.state.name,
      );
      expect(
        contract.persistenceRequirement.trim(),
        isNotEmpty,
        reason: contract.state.name,
      );
      expect(
        contract.recoveryBehavior.trim(),
        isNotEmpty,
        reason: contract.state.name,
      );
      expect(
        contract.userVisibleBehavior.trim(),
        isNotEmpty,
        reason: contract.state.name,
      );
      expect(contract.diagnosticEvent, startsWith('trip_state_'));
    }
  });

  test('entry, exit, and forbidden sets mirror the sole state machine', () {
    for (final state in TripTrackingSessionLifecycleContractState.values) {
      final contract = TripTrackingStateContractCatalog.forState(state);
      final expectedEntries = TripTrackingSessionLifecycleContractState.values
          .where(
            (candidate) =>
                TripTrackingSessionContractStateMachine.canTransition(
                  candidate,
                  state,
                ),
          )
          .toSet();
      expect(contract.legalEntryStates, expectedEntries, reason: state.name);
      expect(
        contract.legalExitStates,
        TripTrackingSessionContractStateMachine.allowedNextStates(state),
        reason: state.name,
      );
      expect(
        contract.legalExitStates.intersection(contract.forbiddenExitStates),
        isEmpty,
        reason: state.name,
      );
      expect(
        contract.legalExitStates.union(contract.forbiddenExitStates),
        TripTrackingSessionLifecycleContractState.values.toSet(),
        reason: state.name,
      );
    }
  });

  test(
    'review and terminal contracts preserve user and odometer authority',
    () {
      final pending = TripTrackingStateContractCatalog.forState(
        TripTrackingSessionLifecycleContractState.COMPLETION_PENDING,
      );
      final failed = TripTrackingStateContractCatalog.forState(
        TripTrackingSessionLifecycleContractState.FAILED_UNRECOVERABLE,
      );
      final cancelled = TripTrackingStateContractCatalog.forState(
        TripTrackingSessionLifecycleContractState.CANCELLED,
      );

      expect(pending.userVisibleBehavior, contains('user-confirmed'));
      expect(failed.userVisibleBehavior, contains('odometer'));
      expect(cancelled.persistenceRequirement, contains('Retain'));
      expect(TripTrackingStateContractCatalog.odometerIsGlobalTruth, isTrue);
    },
  );
}
