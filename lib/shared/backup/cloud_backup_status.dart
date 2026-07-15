import 'cloud_backup_quota.dart';
import 'cloud_backup_manifest.dart';

enum CloudBackupConnectionState {
  notConnected,
  connected,
  paused,
  unavailable;

  String get label {
    return switch (this) {
      CloudBackupConnectionState.notConnected => 'Not connected',
      CloudBackupConnectionState.connected => 'Connected',
      CloudBackupConnectionState.paused => 'Paused',
      CloudBackupConnectionState.unavailable => 'Unavailable',
    };
  }
}

class CloudBackupStatusSnapshot {
  const CloudBackupStatusSnapshot({
    required this.connectionState,
    required this.entitlement,
    required this.usedBytes,
    this.message,
  });

  const CloudBackupStatusSnapshot.notConnected()
    : connectionState = CloudBackupConnectionState.notConnected,
      entitlement = const CloudBackupEntitlement.localOnly(),
      usedBytes = 0,
      message = 'Backup is not turned on yet.';

  const CloudBackupStatusSnapshot.unavailable({
    this.entitlement = const CloudBackupEntitlement.localOnly(),
    this.usedBytes = 0,
    this.message = 'Backup is unavailable. Local receipt saving still works.',
  }) : connectionState = CloudBackupConnectionState.unavailable;

  final CloudBackupConnectionState connectionState;
  final CloudBackupEntitlement entitlement;
  final int usedBytes;
  final String? message;

  bool get isEnabled => connectionState == CloudBackupConnectionState.connected;

  CloudBackupQuotaCheck checkPendingBytes(int pendingBytes) {
    return CloudBackupQuotaPolicy.check(
      entitlement: entitlement,
      usedBytes: usedBytes,
      pendingBytes: pendingBytes,
      backupEnabled: isEnabled,
    );
  }

  CloudBackupQuotaCheck checkManifest(CloudBackupManifest manifest) {
    return checkPendingBytes(manifest.pendingBytes);
  }
}
