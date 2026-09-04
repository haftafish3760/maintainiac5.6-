import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Initializes Maintainiac's local database in an app-private location.
///
/// Older macOS builds used the Documents directory. A sandbox configuration
/// change could therefore expose Hive files in the user's visible Documents
/// folder. macOS now uses Application Support and copies legacy databases
/// before Hive opens them. Existing destination databases are never replaced.
class MaintainiacHiveBootstrap {
  static const _macOsBundleId = 'com.rbbie.maintaniac';

  static const _knownGlobalDocumentsBoxes = <String>{
    'active_gps_trip_tracking_session',
    'active_workday_sessions',
    'app_signature_store',
    'calendar_preferences.audit_archive',
    'calendar_preferences',
    'calendar_schedule_records.audit_archive',
    'calendar_schedule_records',
    'dashboard_quick_action_layout',
    'employee_work_time_records.audit_archive',
    'employee_work_time_records',
    'expense_export_history',
    'expense_jobs',
    'expense_ledger_receipts',
    'expense_receipt_drafts',
    'expense_reminders_v1',
    'expense_settings',
    'expense_work_profiles_v1',
    'gps_trip_tracking_bluetooth_vehicle_links',
    'gps_trip_tracking_compact_route_points',
    'gps_trip_tracking_settings',
    'invoice_ledger_records',
    'maintainiac_durable_records.audit_archive',
    'maintainiac_durable_records',
    'maintainiac_jobs_v1',
    'maintainiac_maintenance_records',
    'maintainiac_record_drafts',
    'maintainiac_vehicle_profiles',
    'operational_context_v1',
    'receipt_capture_settings',
    'trip_automatic_evidence_candidate_inbox',
    'trip_tracking_trip_log_proposal_inbox',
    'user_profile_settings_v1',
    'vehicle_odometer_snapshots',
  };

  static Future<void> initialize() async {
    if (kIsWeb || !Platform.isMacOS) {
      await Hive.initFlutter();
      return;
    }

    final legacyDocuments = await getApplicationDocumentsDirectory();
    final applicationSupport = await getApplicationSupportDirectory();
    final hiveDirectory = Directory(
      '${applicationSupport.path}${Platform.pathSeparator}hive',
    );
    await hiveDirectory.create(recursive: true);

    await migrateLegacyMacOsBoxes(
      sourceDirectory: legacyDocuments,
      destinationDirectory: hiveDirectory,
      sourceIsPrivateAppContainer: _isPrivateAppContainer(legacyDocuments.path),
    );
    Hive.init(hiveDirectory.path);
  }

  @visibleForTesting
  static Future<List<String>> migrateLegacyMacOsBoxes({
    required Directory sourceDirectory,
    required Directory destinationDirectory,
    required bool sourceIsPrivateAppContainer,
  }) async {
    if (!await sourceDirectory.exists()) return const [];
    await destinationDirectory.create(recursive: true);

    final sourcePath = sourceDirectory.absolute.path;
    final destinationPath = destinationDirectory.absolute.path;
    if (sourcePath == destinationPath) return const [];

    final boxNames =
        sourceIsPrivateAppContainer
              ? await _allHiveBoxNames(sourceDirectory)
              : _knownGlobalDocumentsBoxes.toList(growable: false)
          ..sort();
    final copied = <String>[];

    for (final boxName in boxNames) {
      final source = File('$sourcePath${Platform.pathSeparator}$boxName.hive');
      if (!await source.exists()) continue;

      final destination = File(
        '$destinationPath${Platform.pathSeparator}$boxName.hive',
      );
      if (await destination.exists()) continue;

      final temporary = File('${destination.path}.migrating');
      if (await temporary.exists()) await temporary.delete();
      await source.copy(temporary.path);
      if (await source.length() != await temporary.length()) {
        await temporary.delete();
        throw FileSystemException(
          'Maintainiac could not verify a local database migration.',
          source.path,
        );
      }
      await temporary.rename(destination.path);
      copied.add(boxName);
    }

    return copied;
  }

  static bool _isPrivateAppContainer(String path) {
    final marker =
        '${Platform.pathSeparator}Library${Platform.pathSeparator}Containers'
        '${Platform.pathSeparator}$_macOsBundleId${Platform.pathSeparator}';
    return path.contains(marker);
  }

  static Future<List<String>> _allHiveBoxNames(Directory directory) async {
    final names = <String>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.hive')) continue;
      final fileName = entity.uri.pathSegments.last;
      names.add(fileName.substring(0, fileName.length - '.hive'.length));
    }
    names.sort();
    return names;
  }
}
