import 'cloud_backup_status.dart';

abstract class CloudBackupService {
  Future<CloudBackupStatusSnapshot> currentStatus();
}

class LocalOnlyCloudBackupService implements CloudBackupService {
  const LocalOnlyCloudBackupService();

  @override
  Future<CloudBackupStatusSnapshot> currentStatus() async {
    return const CloudBackupStatusSnapshot.notConnected();
  }
}
