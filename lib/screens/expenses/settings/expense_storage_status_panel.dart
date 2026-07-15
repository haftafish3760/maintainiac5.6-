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
              const Expanded(
                child: Text(
                  'Device Storage',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Refresh storage',
                onPressed: _checking ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          Text(
            available == null
                ? 'Available storage could not be verified right now.'
                : '${AppStorageGuard.formatBytes(available)} available',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: state.color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            state.message,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          const Text(
            'Receipt processing needs temporary device space. Maintainiac saves your records locally first and never deletes your photos or files to make room.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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

  String get message => switch (this) {
    _ExpenseStorageHealth.healthy =>
      'Storage is healthy for receipt capture and local proof saving.',
    _ExpenseStorageHealth.warning =>
      'Storage is getting low. Consider freeing space before importing more receipts.',
    _ExpenseStorageHealth.critical =>
      'Storage is critically low. Free space before capturing or importing another receipt.',
    _ExpenseStorageHealth.unknown =>
      'Refresh to try again before importing a large receipt or PDF.',
  };
}
