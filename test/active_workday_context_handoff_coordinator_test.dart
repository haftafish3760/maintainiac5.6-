// Regression coverage for durable active-workday context handoff recovery.
//
// Owns coordinator behavior across workday, odometer, vehicle, and profile
// ports. It does not test UI selection or physical GPS/Bluetooth behavior.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_context_handoff_coordinator.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';

void main() {
  test('completed handoff writes each owner in deterministic order', () async {
    final fixture = await _HandoffFixture.create();
    final result = await fixture.coordinator.apply(fixture.request);

    expect(result.completed, isTrue);
    expect(result.phase, ActiveWorkdayContextHandoffPhase.completed);
    expect(fixture.calls, [
      'workday',
      'odometer:vehicle-2',
      'vehicle:vehicle-2',
      'profile:profile-2',
      'context:vehicle-2',
    ]);
    expect(
      fixture.workday.activeSession?.currentContextSegment.vehicleId,
      'vehicle-2',
    );
    expect(
      fixture.records
          .recordFor(
            ActiveWorkdayContextHandoffCoordinator.recordModule,
            'handoff-1',
          )
          ?.payload['phase'],
      ActiveWorkdayContextHandoffPhase.completed.name,
    );
  });

  test(
    'interrupted handoff resumes without duplicating the workday boundary',
    () async {
      final fixture = await _HandoffFixture.create(
        failFirstOdometerSwitch: true,
      );
      final first = await fixture.coordinator.apply(fixture.request);

      expect(first.completed, isFalse);
      expect(first.phase, ActiveWorkdayContextHandoffPhase.workdayApplied);
      expect(
        fixture.workday.activeSession?.events.where(
          (event) => event.type == ActiveWorkdayEventType.contextChanged,
        ),
        hasLength(1),
      );

      final recovered = await fixture.coordinator.recoverPending();

      expect(recovered, hasLength(1));
      expect(recovered.single.completed, isTrue);
      expect(
        fixture.workday.activeSession?.events.where(
          (event) => event.type == ActiveWorkdayEventType.contextChanged,
        ),
        hasLength(1),
      );
      expect(fixture.calls.where((call) => call == 'workday'), hasLength(1));
      expect(
        fixture.records
            .recordFor(
              ActiveWorkdayContextHandoffCoordinator.recordModule,
              'handoff-1',
            )
            ?.payload['phase'],
        ActiveWorkdayContextHandoffPhase.completed.name,
      );
    },
  );

  test(
    'workday mismatch fails closed without changing another session',
    () async {
      final fixture = await _HandoffFixture.create();
      final invalid = ActiveWorkdayContextHandoffRequest(
        operationId: 'handoff-2',
        workdayId: 'other-workday',
        vehicleId: fixture.request.vehicleId,
        vehicleLabel: fixture.request.vehicleLabel,
        workProfileId: fixture.request.workProfileId,
        endingOdometer: fixture.request.endingOdometer,
        startingOdometer: fixture.request.startingOdometer,
        occurredAt: fixture.request.occurredAt,
      );

      final result = await fixture.coordinator.apply(invalid);

      expect(result.completed, isFalse);
      expect(result.phase, ActiveWorkdayContextHandoffPhase.needsReview);
      expect(fixture.calls, isEmpty);
      expect(
        fixture.workday.activeSession?.currentContextSegment.vehicleId,
        'vehicle-1',
      );
    },
  );

  test('duplicate completed operation does not repeat owner writes', () async {
    final fixture = await _HandoffFixture.create();
    await fixture.coordinator.apply(fixture.request);
    final callsAfterFirst = List<String>.from(fixture.calls);

    final duplicate = await fixture.coordinator.apply(fixture.request);

    expect(duplicate.completed, isTrue);
    expect(fixture.calls, callsAfterFirst);
  });
}

final class _HandoffFixture {
  _HandoffFixture._({
    required this.workday,
    required this.records,
    required this.coordinator,
    required this.request,
    required this.calls,
  });

  final ActiveWorkdayController workday;
  final MaintainiacDurableRecordStore records;
  final ActiveWorkdayContextHandoffCoordinator coordinator;
  final ActiveWorkdayContextHandoffRequest request;
  final List<String> calls;

  static Future<_HandoffFixture> create({
    bool failFirstOdometerSwitch = false,
  }) async {
    final workday = ActiveWorkdayController.memory();
    final occurredAt = DateTime.now().toUtc().subtract(
      const Duration(minutes: 1),
    );
    await workday.startDay(
      vehicleId: 'vehicle-1',
      vehicleLabel: 'Work truck',
      workProfileId: 'profile-1',
      startOdometer: 1000,
      startedAt: occurredAt.subtract(const Duration(hours: 1)),
    );
    final request = ActiveWorkdayContextHandoffRequest(
      operationId: 'handoff-1',
      workdayId: workday.activeSession!.id,
      vehicleId: 'vehicle-2',
      vehicleLabel: 'Delivery van',
      workProfileId: 'profile-2',
      endingOdometer: 1012,
      startingOdometer: 500,
      occurredAt: occurredAt,
    );
    final calls = <String>[];
    final records = MaintainiacDurableRecordStore.memory();
    var shouldFailOdometer = failFirstOdometerSwitch;
    final coordinator = ActiveWorkdayContextHandoffCoordinator(
      records: records,
      ports: ActiveWorkdayContextHandoffPorts(
        activeSession: () => workday.activeSession,
        applyWorkdayBoundary: (handoff) async {
          calls.add('workday');
          return workday.handoffContext(
            vehicleId: handoff.vehicleId,
            vehicleLabel: handoff.vehicleLabel,
            workProfileId: handoff.workProfileId,
            endingOdometer: handoff.endingOdometer,
            startingOdometer: handoff.startingOdometer,
            occurredAt: handoff.occurredAt,
          );
        },
        switchOdometerVehicle: (vehicleId) async {
          calls.add('odometer:$vehicleId');
          if (shouldFailOdometer) {
            shouldFailOdometer = false;
            return false;
          }
          return true;
        },
        selectVehicle: (vehicleId) async => calls.add('vehicle:$vehicleId'),
        selectWorkProfile: (profileId) async => calls.add('profile:$profileId'),
        syncOperationalContext: (handoff) async =>
            calls.add('context:${handoff.vehicleId}'),
      ),
    );
    return _HandoffFixture._(
      workday: workday,
      records: records,
      coordinator: coordinator,
      request: request,
      calls: calls,
    );
  }
}
