enum TripSourceInventoryStatus {
  clean,
  duplicateFilenames,
  duplicatePrimaryTypes,
  unsafePath,
}

class TripSourceInventoryDecision {
  const TripSourceInventoryDecision({
    required this.status,
    required this.reasonCode,
    required this.sourceFileCount,
    required this.testFileCount,
    required this.duplicateFilenames,
    required this.duplicatePrimaryTypes,
  });

  final TripSourceInventoryStatus status;
  final String reasonCode;
  final int sourceFileCount;
  final int testFileCount;
  final List<String> duplicateFilenames;
  final List<String> duplicatePrimaryTypes;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'sourceFileCount': _safeCount(sourceFileCount),
    'testFileCount': _safeCount(testFileCount),
    'duplicateFilenames': duplicateFilenames.take(20).toList(growable: false),
    'duplicatePrimaryTypes': duplicatePrimaryTypes
        .take(20)
        .toList(growable: false),
    'tripInventoryOnly': true,
    'inventoryCanModifyFiles': false,
    'inventoryCanDeleteFiles': false,
    'inventoryCanSilenceFailures': false,
    'moduleBoundaryProtected': true,
    'receiptInventoryFuelExpenseModulesExcluded': true,
    'odometerTruthBoundaryTracked': true,
    'odometerIsGlobalTruth': true,
    'calibrationProofBoundaryTracked': true,
    'inventoryCanApplyCalibration': false,
    'inventoryCanCreateOfficialMileage': false,
    'inventoryCanSetGlobalTruth': false,
    'inventoryCanChangeOfficialMileage': false,
    'rawSourceIncluded': false,
    'tokensIncluded': false,
  };
}

class TripSourceInventoryPolicy {
  const TripSourceInventoryPolicy._();

  static TripSourceInventoryDecision evaluate({
    required Iterable<String> sourcePaths,
    required Iterable<String> testPaths,
    required Map<String, String> primaryTypesByPath,
  }) {
    final source = sourcePaths
        .where(_isTripDartPath)
        .map(_normalizedPath)
        .toList(growable: false);
    final tests = testPaths
        .where(_isTripDartPath)
        .map(_normalizedPath)
        .toList(growable: false);
    if (source.any(_unsafePath) || tests.any(_unsafePath)) {
      return _decision(
        status: TripSourceInventoryStatus.unsafePath,
        reasonCode: 'trip_inventory_unsafe_path',
        sourceFileCount: source.length,
        testFileCount: tests.length,
        duplicateFilenames: const [],
        duplicatePrimaryTypes: const [],
      );
    }

    final duplicateFilenames = _duplicates([
      ...source.map(_basename),
      ...tests.map(_basename),
    ]);
    final duplicatePrimaryTypes = _duplicates(
      primaryTypesByPath.entries
          .where((entry) => _isTripDartPath(entry.key))
          .map((entry) => entry.value.trim())
          .where((value) => value.isNotEmpty && _safeTypeName(value)),
    );

    if (duplicateFilenames.isNotEmpty) {
      return _decision(
        status: TripSourceInventoryStatus.duplicateFilenames,
        reasonCode: 'trip_inventory_duplicate_filenames',
        sourceFileCount: source.length,
        testFileCount: tests.length,
        duplicateFilenames: duplicateFilenames,
        duplicatePrimaryTypes: duplicatePrimaryTypes,
      );
    }
    if (duplicatePrimaryTypes.isNotEmpty) {
      return _decision(
        status: TripSourceInventoryStatus.duplicatePrimaryTypes,
        reasonCode: 'trip_inventory_duplicate_primary_types',
        sourceFileCount: source.length,
        testFileCount: tests.length,
        duplicateFilenames: duplicateFilenames,
        duplicatePrimaryTypes: duplicatePrimaryTypes,
      );
    }
    return _decision(
      status: TripSourceInventoryStatus.clean,
      reasonCode: 'trip_inventory_clean',
      sourceFileCount: source.length,
      testFileCount: tests.length,
      duplicateFilenames: const [],
      duplicatePrimaryTypes: const [],
    );
  }
}

TripSourceInventoryDecision _decision({
  required TripSourceInventoryStatus status,
  required String reasonCode,
  required int sourceFileCount,
  required int testFileCount,
  required List<String> duplicateFilenames,
  required List<String> duplicatePrimaryTypes,
}) {
  return TripSourceInventoryDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    sourceFileCount: _safeCount(sourceFileCount),
    testFileCount: _safeCount(testFileCount),
    duplicateFilenames: List.unmodifiable(
      duplicateFilenames.where(_safeFilename).toList()..sort(),
    ),
    duplicatePrimaryTypes: List.unmodifiable(
      duplicatePrimaryTypes.where(_safeTypeName).toList()..sort(),
    ),
  );
}

bool _isTripDartPath(String value) {
  final path = _normalizedPath(value);
  final base = _basename(path);
  return path.endsWith('.dart') &&
      (path.contains('/trip_tracking/') ||
          base.startsWith('trip_') ||
          base.startsWith('dashboard_trip_tracking') ||
          base.startsWith('mapbox_trip_assist'));
}

bool _unsafePath(String value) {
  final normalized = _normalizedPath(value);
  return normalized.contains('..') ||
      normalized.contains('\u0000') ||
      normalized.trim() != normalized ||
      normalized.length > 300;
}

String _normalizedPath(String value) => value.replaceAll('\\', '/').trim();

String _basename(String value) {
  final normalized = _normalizedPath(value);
  final slash = normalized.lastIndexOf('/');
  return slash < 0 ? normalized : normalized.substring(slash + 1);
}

List<String> _duplicates(Iterable<String> values) {
  final seen = <String>{};
  final duplicates = <String>{};
  for (final value in values) {
    final clean = value.trim();
    if (clean.isEmpty) continue;
    if (!seen.add(clean)) duplicates.add(clean);
  }
  return duplicates.toList(growable: false)..sort();
}

bool _safeFilename(String value) {
  return RegExp(r'^[A-Za-z0-9_.-]+\.dart$').hasMatch(value);
}

bool _safeTypeName(String value) {
  return RegExp(r'^[A-Za-z][A-Za-z0-9_]{1,120}$').hasMatch(value);
}

int _safeCount(int value) {
  if (value <= 0) return 0;
  return value > 100000 ? 100000 : value;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'trip_inventory_clean' => 'trip_inventory_clean',
    'trip_inventory_duplicate_filenames' =>
      'trip_inventory_duplicate_filenames',
    'trip_inventory_duplicate_primary_types' =>
      'trip_inventory_duplicate_primary_types',
    'trip_inventory_unsafe_path' => 'trip_inventory_unsafe_path',
    _ => 'trip_inventory_unsafe_path',
  };
}
