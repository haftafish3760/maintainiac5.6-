enum MaintainiacQaModule {
  inventory,
  receipts,
  ocr,
  expenses,
  camera,
  tripLog,
  odometer,
  recap,
  estimates,
  invoices,
  jobs,
  maintenance,
  calendar,
  sync,
  profiles,
  vehicles,
  fleet,
  employees,
  exports,
  payments,
  security,
  privacy,
  performance,
}

enum MaintainiacNetworkState { offline, wifi, cellular, roaming, blocked }

class MaintainiacQaEnvironment {
  const MaintainiacQaEnvironment({
    required this.clock,
    required this.user,
    required this.account,
    required this.profile,
    required this.vehicle,
    required this.subscriptionTier,
    required this.networkState,
    required this.permissions,
    required this.hive,
    required this.firestoreMirror,
    required this.cloudStorage,
    required this.notifications,
    required this.exports,
    required this.files,
    required this.device,
  });

  final DateTime clock;
  final QaUser user;
  final QaAccount account;
  final QaProfile profile;
  final QaVehicle vehicle;
  final String subscriptionTier;
  final MaintainiacNetworkState networkState;
  final FakePermissionSet permissions;
  final FakeLocalStore hive;
  final FakeMirrorStore firestoreMirror;
  final FakeCloudStorage cloudStorage;
  final FakeNotificationScheduler notifications;
  final FakeExportWriter exports;
  final FakeFileStorage files;
  final FakeDeviceState device;

  static MaintainiacQaEnvironment standard() {
    final user = const QaUser(id: 'user_1', accountId: 'acct_1');
    final account = const QaAccount(id: 'acct_1', ownerUserId: 'user_1');
    return MaintainiacQaEnvironment(
      clock: DateTime.utc(2026, 7, 3, 12),
      user: user,
      account: account,
      profile: const QaProfile(id: 'profile_1', userId: 'user_1'),
      vehicle: const QaVehicle(id: 'vehicle_1', accountId: 'acct_1'),
      subscriptionTier: 'pro',
      networkState: MaintainiacNetworkState.wifi,
      permissions: FakePermissionSet.allowAll(),
      hive: FakeLocalStore(),
      firestoreMirror: FakeMirrorStore(),
      cloudStorage: FakeCloudStorage(),
      notifications: FakeNotificationScheduler(),
      exports: FakeExportWriter(),
      files: FakeFileStorage(),
      device: const FakeDeviceState(
        model: 'Galaxy S24 Ultra',
        appCheckValid: true,
        freeBytes: 1024 * 1024 * 1024,
        batterySaver: false,
      ),
    );
  }
}

class QaUser {
  const QaUser({required this.id, required this.accountId});

  final String id;
  final String accountId;
}

class QaAccount {
  const QaAccount({required this.id, required this.ownerUserId});

  final String id;
  final String ownerUserId;
}

class QaProfile {
  const QaProfile({required this.id, required this.userId});

  final String id;
  final String userId;
}

class QaVehicle {
  const QaVehicle({required this.id, required this.accountId});

  final String id;
  final String accountId;
}

class FakePermissionSet {
  const FakePermissionSet(this.allowed);

  final Set<String> allowed;

  static FakePermissionSet allowAll() {
    return const FakePermissionSet({
      'read',
      'write',
      'sync',
      'export',
      'admin',
      'fleet.manage',
      'employee.manage',
    });
  }

  bool allows(String permission) => allowed.contains(permission);
}

class FakeLocalStore {
  final _boxes = <String, Map<String, Map<String, Object?>>>{};
  final writes = <QaWriteEvent>[];

  void put(String box, String id, Map<String, Object?> payload) {
    _boxes.putIfAbsent(box, () => {})[id] = Map.of(payload);
    writes.add(QaWriteEvent.local(box: box, id: id, payload: payload));
  }

  Map<String, Object?>? get(String box, String id) {
    final payload = _boxes[box]?[id];
    return payload == null ? null : Map.of(payload);
  }
}

class FakeMirrorStore {
  final documents = <String, Map<String, Object?>>{};
  final writes = <QaWriteEvent>[];

  void mirror(String path, Map<String, Object?> payload) {
    documents[path] = Map.of(payload);
    writes.add(QaWriteEvent.mirror(path: path, payload: payload));
  }
}

class FakeCloudStorage {
  final objects = <String, List<int>>{};

  void write(String path, List<int> bytes) {
    objects[path] = List.of(bytes);
  }
}

class FakeNotificationScheduler {
  final scheduled = <Map<String, Object?>>[];

  void schedule(Map<String, Object?> event) {
    scheduled.add(Map.of(event));
  }
}

class FakeExportWriter {
  final exports = <Map<String, Object?>>[];

  void write(Map<String, Object?> export) {
    exports.add(Map.of(export));
  }
}

class FakeFileStorage {
  final files = <String, Object>{};

  void put(String path, Object content) {
    files[path] = content;
  }
}

class FakeDeviceState {
  const FakeDeviceState({
    required this.model,
    required this.appCheckValid,
    required this.freeBytes,
    required this.batterySaver,
  });

  final String model;
  final bool appCheckValid;
  final int freeBytes;
  final bool batterySaver;
}

class QaWriteEvent {
  const QaWriteEvent._({
    required this.kind,
    required this.target,
    required this.payload,
  });

  factory QaWriteEvent.local({
    required String box,
    required String id,
    required Map<String, Object?> payload,
  }) {
    return QaWriteEvent._(
      kind: 'local',
      target: '$box/$id',
      payload: Map.of(payload),
    );
  }

  factory QaWriteEvent.mirror({
    required String path,
    required Map<String, Object?> payload,
  }) {
    return QaWriteEvent._(
      kind: 'firestore_mirror',
      target: path,
      payload: Map.of(payload),
    );
  }

  final String kind;
  final String target;
  final Map<String, Object?> payload;
}
