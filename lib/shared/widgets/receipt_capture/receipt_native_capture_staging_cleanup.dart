part of 'receipt_native_capture_staging.dart';

bool? _boolValue(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == 'yes' || text == '1') return true;
  if (text == 'false' || text == 'no' || text == '0') return false;
  return null;
}

double? _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

const Set<String> _missingBottomEdgeStatuses = {
  'missing',
  'not_found',
  'cut_off',
  'possibly_cut_off',
  'outside_frame',
  'needs_next_section',
  'continues',
};

const Set<String> _presentBottomEdgeStatuses = {
  'found',
  'present',
  'visible',
  'complete',
  'framed',
  'bottom_visible',
};

const List<String> _coveredInterruptionCases = [
  'app_backgrounded_after_capture',
  'phone_call_after_capture',
  'camera_closed_before_review',
  'review_closed_before_attach',
];

Future<Directory> _recoveryManifestRoot() async {
  final directory = await getApplicationDocumentsDirectory();
  return Directory(path.join(directory.path, 'native_capture_recovery'));
}

Future<void> _deleteRecoveryManifest(String manifestPath) async {
  if (manifestPath.trim().isEmpty) return;
  try {
    final file = File(manifestPath);
    if (await file.exists()) await file.delete();
  } catch (_) {}
  await _deleteRecoveryIndex(manifestPath);
}

Future<void> _deleteRecoveryIndex(String manifestPath) async {
  try {
    final store = await ReceiptNativeCaptureRecoveryStore.create();
    await store.deleteByManifestPath(manifestPath);
  } catch (_) {}
}

Future<void> _cleanRecoveryIndex({
  required Iterable<String> retainedPaths,
  required Duration olderThan,
  DateTime? now,
}) async {
  try {
    final store = await ReceiptNativeCaptureRecoveryStore.create();
    await store.deleteUnrecoverableEntries(retainedPaths: retainedPaths);
    await store.deleteOldEntries(
      retainedPaths: retainedPaths,
      olderThan: olderThan,
      now: now,
    );
  } catch (_) {}
}

Future<void> _cleanOldRecoveryManifests({
  required Iterable<String> retainedPaths,
  Duration olderThan = const Duration(days: 7),
  DateTime? now,
}) async {
  final retained = retainedPaths
      .map((item) => path.normalize(item.trim()))
      .where((item) => item.isNotEmpty)
      .toSet();
  final root = await _recoveryManifestRoot();
  if (!await root.exists()) return;
  final cutoff = (now ?? DateTime.now()).subtract(olderThan);
  await for (final entity in root.list()) {
    if (entity is! File || path.extension(entity.path) != '.json') continue;
    try {
      final stat = await entity.stat();
      if (stat.modified.isAfter(cutoff)) continue;
      final content = jsonDecode(await entity.readAsString());
      if (_manifestReferencesRetainedPath(content, retained)) continue;
      await _deleteRecoveryManifest(entity.path);
    } catch (_) {
      continue;
    }
  }
}

bool _manifestReferencesRetainedPath(Object? content, Set<String> retained) {
  if (retained.isEmpty || content is! Map) return false;
  final stagedPhotoPaths = content['stagedPhotoPaths'];
  if (stagedPhotoPaths is! Iterable) return false;
  for (final item in stagedPhotoPaths) {
    if (retained.contains(path.normalize(item.toString().trim()))) {
      return true;
    }
  }
  return false;
}
