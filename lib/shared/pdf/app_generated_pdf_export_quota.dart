class AppGeneratedPdfExportQuotaStatus {
  const AppGeneratedPdfExportQuotaStatus({
    required this.monthKey,
    required this.usedExports,
    required this.freeExportsPerMonth,
    required this.rewardedUnlockAvailable,
  });

  final String monthKey;
  final int usedExports;
  final int freeExportsPerMonth;
  final bool rewardedUnlockAvailable;

  int get freeExportsRemaining {
    final remaining = freeExportsPerMonth - usedExports;
    return remaining < 0 ? 0 : remaining;
  }

  bool get canExport => freeExportsRemaining > 0 || rewardedUnlockAvailable;

  bool get requiresUnlock => !canExport;
}

typedef AppGeneratedPdfExportCountReader =
    Future<int> Function(String monthKey);
typedef AppGeneratedPdfExportCountWriter =
    Future<void> Function(String monthKey, int usedExports);

class AppGeneratedPdfExportQuotaService {
  AppGeneratedPdfExportQuotaService({
    required this.readUsedExports,
    required this.writeUsedExports,
    this.freeExportsPerMonth = 1,
  }) : assert(freeExportsPerMonth >= 0);

  final AppGeneratedPdfExportCountReader readUsedExports;
  final AppGeneratedPdfExportCountWriter writeUsedExports;
  final int freeExportsPerMonth;
  final Set<String> _rewardedUnlocks = <String>{};

  Future<AppGeneratedPdfExportQuotaStatus> status(DateTime now) async {
    final monthKey = _monthKey(now);
    final usedExports = await _readNonNegative(monthKey);
    return AppGeneratedPdfExportQuotaStatus(
      monthKey: monthKey,
      usedExports: usedExports,
      freeExportsPerMonth: freeExportsPerMonth,
      rewardedUnlockAvailable: _rewardedUnlocks.contains(monthKey),
    );
  }

  Future<bool> canExport(DateTime now) async {
    return (await status(now)).canExport;
  }

  Future<void> consumeExport(DateTime now) async {
    final current = await status(now);
    if (current.freeExportsRemaining > 0) {
      await writeUsedExports(current.monthKey, current.usedExports + 1);
      return;
    }
    if (current.rewardedUnlockAvailable) {
      _rewardedUnlocks.remove(current.monthKey);
      return;
    }
    throw const AppGeneratedPdfExportQuotaException(
      'monthly_export_limit_reached',
    );
  }

  Future<bool> unlockExportWithRewardedAdPlaceholder(DateTime now) async {
    final monthKey = _monthKey(now);
    _rewardedUnlocks.add(monthKey);
    return true;
  }

  Future<int> _readNonNegative(String monthKey) async {
    final value = await readUsedExports(monthKey);
    return value < 0 ? 0 : value;
  }

  static String _monthKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    return '${value.year}-$month';
  }
}

class AppGeneratedPdfExportQuotaException implements Exception {
  const AppGeneratedPdfExportQuotaException(this.reasonCode);

  final String reasonCode;

  @override
  String toString() => 'PDF export quota blocked: $reasonCode';
}
