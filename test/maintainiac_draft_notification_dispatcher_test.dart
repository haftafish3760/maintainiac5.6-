import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('default policy delivers only one in-app notification', () async {
    final fixture = await _fixture();
    final gateway = _Gateway();
    final dispatcher = MaintainiacDraftNotificationDispatcher(
      reminders: fixture.reminders,
      gateway: gateway,
      permissionProvider: () async =>
          const MaintainiacDraftNotificationPermission(
            pushAuthorized: true,
            audioAuthorized: true,
          ),
    );

    final first = await dispatcher.deliverDue(
      scopeId: 'expenses',
      draftModules: const ['expenseForms'],
      nowUtc: fixture.dueAt,
    );
    final second = await dispatcher.deliverDue(
      scopeId: 'expenses',
      draftModules: const ['expenseForms'],
      nowUtc: fixture.dueAt,
    );

    expect(first.single.inAppDelivered, isTrue);
    expect(first.single.pushDelivered, isFalse);
    expect(first.single.audioDelivered, isFalse);
    expect(second, isEmpty);
    expect(gateway.inAppCalls, 1);
    expect(gateway.pushCalls, 0);
    expect(gateway.audioCalls, 0);
  });

  test('screen opt-in still requires platform permission', () async {
    final fixture = await _fixture(enableExternalChannels: true);
    final gateway = _Gateway();
    final dispatcher = MaintainiacDraftNotificationDispatcher(
      reminders: fixture.reminders,
      gateway: gateway,
      permissionProvider: () async =>
          const MaintainiacDraftNotificationPermission.denied(),
    );

    final delivery = await dispatcher.deliverDue(
      scopeId: 'expenses',
      draftModules: const ['expenseForms'],
      nowUtc: fixture.dueAt,
    );

    expect(delivery.single.inAppDelivered, isTrue);
    expect(delivery.single.pushDelivered, isFalse);
    expect(delivery.single.audioDelivered, isFalse);
    expect(gateway.pushCalls, 0);
    expect(gateway.audioCalls, 0);
  });

  test('opted-in authorized channels record successful delivery', () async {
    final fixture = await _fixture(enableExternalChannels: true);
    final gateway = _Gateway();
    final dispatcher = MaintainiacDraftNotificationDispatcher(
      reminders: fixture.reminders,
      gateway: gateway,
      permissionProvider: () async =>
          const MaintainiacDraftNotificationPermission(
            pushAuthorized: true,
            audioAuthorized: true,
          ),
    );

    final delivery = await dispatcher.deliverDue(
      scopeId: 'expenses',
      draftModules: const ['expenseForms'],
      nowUtc: fixture.dueAt,
    );

    expect(delivery.single.inAppDelivered, isTrue);
    expect(delivery.single.pushDelivered, isTrue);
    expect(delivery.single.audioDelivered, isTrue);
    expect(gateway.pushCalls, 1);
    expect(gateway.audioCalls, 1);
  });

  test('failed external delivery retries without repeating in-app', () async {
    final fixture = await _fixture(enableExternalChannels: true);
    final gateway = _Gateway(pushResult: false, audioResult: false);
    final dispatcher = MaintainiacDraftNotificationDispatcher(
      reminders: fixture.reminders,
      gateway: gateway,
      permissionProvider: () async =>
          const MaintainiacDraftNotificationPermission(
            pushAuthorized: true,
            audioAuthorized: true,
          ),
    );
    await dispatcher.deliverDue(
      scopeId: 'expenses',
      draftModules: const ['expenseForms'],
      nowUtc: fixture.dueAt,
    );

    final retry = await dispatcher.deliverDue(
      scopeId: 'expenses',
      draftModules: const ['expenseForms'],
      nowUtc: fixture.dueAt.add(const Duration(minutes: 1)),
    );

    expect(retry.single.decision.showInApp, isFalse);
    expect(retry.single.decision.sendPush, isTrue);
    expect(retry.single.decision.playAudio, isTrue);
    expect(gateway.inAppCalls, 1);
  });
}

Future<_Fixture> _fixture({bool enableExternalChannels = false}) async {
  final drafts = MaintainiacRecordDraftStore.memory();
  final records = MaintainiacDurableRecordStore.memory();
  final createdAt = DateTime.utc(2026, 1, 1);
  await drafts.save(
    module: 'expenseForms',
    id: 'expense-1',
    payload: const {'amount': 10},
    now: createdAt,
  );
  if (enableExternalChannels) {
    await MaintainiacDraftRetentionPolicyStore(records).save(
      const MaintainiacDraftRetentionPolicy(
        scopeId: 'expenses',
        pushReminderEnabled: true,
        audioReminderEnabled: true,
      ),
      now: createdAt,
    );
  }
  return _Fixture(
    reminders: MaintainiacDraftReminderCoordinator(
      drafts: drafts,
      records: records,
    ),
    dueAt: createdAt.add(const Duration(days: 90)),
  );
}

class _Fixture {
  const _Fixture({required this.reminders, required this.dueAt});

  final MaintainiacDraftReminderCoordinator reminders;
  final DateTime dueAt;
}

class _Gateway implements MaintainiacDraftNotificationGateway {
  _Gateway({this.pushResult = true, this.audioResult = true});

  final bool pushResult;
  final bool audioResult;
  int inAppCalls = 0;
  int pushCalls = 0;
  int audioCalls = 0;

  @override
  Future<bool> showInApp(MaintainiacDraftReminderDecision decision) async {
    inAppCalls += 1;
    return true;
  }

  @override
  Future<bool> sendPush(MaintainiacDraftReminderDecision decision) async {
    pushCalls += 1;
    return pushResult;
  }

  @override
  Future<bool> playAudio(MaintainiacDraftReminderDecision decision) async {
    audioCalls += 1;
    return audioResult;
  }
}
