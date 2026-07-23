import 'dart:async';

import 'maintainiac_draft_reminder_coordinator.dart';

class MaintainiacDraftNotificationPermission {
  const MaintainiacDraftNotificationPermission({
    required this.pushAuthorized,
    required this.audioAuthorized,
  });

  const MaintainiacDraftNotificationPermission.denied()
    : pushAuthorized = false,
      audioAuthorized = false;

  final bool pushAuthorized;
  final bool audioAuthorized;
}

abstract interface class MaintainiacDraftNotificationGateway {
  Future<bool> showInApp(MaintainiacDraftReminderDecision decision);

  Future<bool> sendPush(MaintainiacDraftReminderDecision decision);

  Future<bool> playAudio(MaintainiacDraftReminderDecision decision);
}

class MaintainiacDraftNotificationDelivery {
  const MaintainiacDraftNotificationDelivery({
    required this.decision,
    required this.inAppDelivered,
    required this.pushDelivered,
    required this.audioDelivered,
  });

  final MaintainiacDraftReminderDecision decision;
  final bool inAppDelivered;
  final bool pushDelivered;
  final bool audioDelivered;
}

class MaintainiacDraftNotificationDispatcher {
  MaintainiacDraftNotificationDispatcher({
    required MaintainiacDraftReminderCoordinator reminders,
    required MaintainiacDraftNotificationGateway gateway,
    required Future<MaintainiacDraftNotificationPermission> Function()
    permissionProvider,
  }) : _reminders = reminders,
       _gateway = gateway,
       _permissionProvider = permissionProvider;

  final MaintainiacDraftReminderCoordinator _reminders;
  final MaintainiacDraftNotificationGateway _gateway;
  final Future<MaintainiacDraftNotificationPermission> Function()
  _permissionProvider;
  static Future<void> _deliveryTail = Future<void>.value();

  Future<List<MaintainiacDraftNotificationDelivery>> deliverDue({
    required String scopeId,
    required Iterable<String> draftModules,
    DateTime? nowUtc,
  }) {
    return _serializeDelivery(
      () => _deliverDue(
        scopeId: scopeId,
        draftModules: draftModules,
        nowUtc: nowUtc,
      ),
    );
  }

  Future<List<MaintainiacDraftNotificationDelivery>> _deliverDue({
    required String scopeId,
    required Iterable<String> draftModules,
    DateTime? nowUtc,
  }) async {
    final permissions = await _safePermissions();
    final due = _reminders.dueForScope(
      scopeId: scopeId,
      draftModules: draftModules,
      nowUtc: nowUtc,
    );
    final deliveries = <MaintainiacDraftNotificationDelivery>[];
    for (final decision in due) {
      final inApp = decision.showInApp
          ? await _safely(() => _gateway.showInApp(decision))
          : false;
      final push = decision.sendPush && permissions.pushAuthorized
          ? await _safely(() => _gateway.sendPush(decision))
          : false;
      final audio = decision.playAudio && permissions.audioAuthorized
          ? await _safely(() => _gateway.playAudio(decision))
          : false;
      if (inApp || push || audio) {
        await _reminders.recordDelivery(
          decision,
          inAppDelivered: inApp,
          pushDelivered: push,
          audioDelivered: audio,
          nowUtc: nowUtc,
        );
      }
      deliveries.add(
        MaintainiacDraftNotificationDelivery(
          decision: decision,
          inAppDelivered: inApp,
          pushDelivered: push,
          audioDelivered: audio,
        ),
      );
    }
    return List.unmodifiable(deliveries);
  }

  static Future<T> _serializeDelivery<T>(Future<T> Function() delivery) async {
    final previous = _deliveryTail;
    final release = Completer<void>();
    _deliveryTail = release.future;
    await previous;
    try {
      return await delivery();
    } finally {
      release.complete();
    }
  }

  Future<MaintainiacDraftNotificationPermission> _safePermissions() async {
    try {
      return await _permissionProvider();
    } catch (_) {
      return const MaintainiacDraftNotificationPermission.denied();
    }
  }

  Future<bool> _safely(Future<bool> Function() deliver) async {
    try {
      return await deliver();
    } catch (_) {
      return false;
    }
  }
}
