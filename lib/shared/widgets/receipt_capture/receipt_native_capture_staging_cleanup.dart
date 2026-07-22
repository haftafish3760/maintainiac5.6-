part of 'receipt_native_capture_staging.dart';

bool? _boolValue(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == 'yes' || text == '1') return true;
  if (text == 'false' || text == 'no' || text == '0') return false;
  return null;
}

double? _doubleValue(Object? value) {
  final parsed = switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null || !parsed.isFinite) return null;
  return parsed;
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
  } catch (_) {}
}
