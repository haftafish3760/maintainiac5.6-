part of 'expense_settings_screen.dart';

class _ExpenseStorageStatusPanel extends StatefulWidget {
  const _ExpenseStorageStatusPanel();

  @override
  State<_ExpenseStorageStatusPanel> createState() =>
      _ExpenseStorageStatusPanelState();
}

class _ExpenseStorageStatusPanelState
    extends State<_ExpenseStorageStatusPanel> {
  AppStorageCheck? _storage;
  var _checking = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (_checking) return;
    setState(() => _checking = true);
    final storage = await AppStorageGuard.check(
      AppStoragePurpose.receiptPhotoCapture,
    );
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = MaintaniacLocalizations.of(context);
    final storage = _storage;
    final available = storage?.availableBytes;
    final state = _ExpenseStorageHealthPresentation.fromBytes(available);
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.deviceStorage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: strings.refreshStorage,
                onPressed: _checking ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          Text(
            available == null
                ? strings.storageUnavailable
                : strings.storageAvailable(
                    AppStorageGuard.formatBytes(available),
                  ),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: state.color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            state.message(strings),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            strings.receiptStorageSafetyNote,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

enum _ExpenseStorageHealth { healthy, warning, critical, unknown }

extension _ExpenseStorageHealthPresentation on _ExpenseStorageHealth {
  static _ExpenseStorageHealth fromBytes(int? bytes) {
    if (bytes == null) return _ExpenseStorageHealth.unknown;
    if (bytes < 500 * 1024 * 1024) return _ExpenseStorageHealth.critical;
    if (bytes < 1024 * 1024 * 1024) return _ExpenseStorageHealth.warning;
    return _ExpenseStorageHealth.healthy;
  }

  Color get color => switch (this) {
    _ExpenseStorageHealth.healthy => const Color(0xFF7AD66D),
    _ExpenseStorageHealth.warning => const Color(0xFFFFD166),
    _ExpenseStorageHealth.critical => const Color(0xFFFF6B6B),
    _ExpenseStorageHealth.unknown => const Color(0xFFC8D0D3),
  };

  String message(MaintaniacLocalizations strings) => switch (this) {
    _ExpenseStorageHealth.healthy => strings.storageHealthyForReceipts,
    _ExpenseStorageHealth.warning => strings.storageLowForReceipts,
    _ExpenseStorageHealth.critical => strings.storageCriticalForReceipts,
    _ExpenseStorageHealth.unknown => strings.storageCheckBeforeImport,
  };
}
