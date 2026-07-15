import '../storage/app_storage_guard.dart';

typedef ExpenseSettingsStorageCheck = Future<AppStorageCheck> Function();

/// Serializes small Expense preference writes and reserves enough device space
/// to report a failed save before the UI claims the preference was stored.
class ExpenseSettingsWriteQueue {
  ExpenseSettingsWriteQueue(ExpenseSettingsStorageCheck? storageCheck)
    : _storageCheck = storageCheck ?? _defaultStorageCheck;

  final ExpenseSettingsStorageCheck? _storageCheck;
  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(Future<T> Function() operation) {
    final next = _tail.then((_) async {
      final check = _storageCheck;
      if (check != null) {
        final storage = await check();
        if (!storage.hasEnoughSpace) {
          throw StateError(storage.blockingMessage());
        }
      }
      return operation();
    });
    _tail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}
