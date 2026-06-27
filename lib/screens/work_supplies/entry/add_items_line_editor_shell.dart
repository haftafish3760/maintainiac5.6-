part of 'work_supply_add_items_screen.dart';

class _ReceiptLineEditorScreen extends StatelessWidget {
  const _ReceiptLineEditorScreen({
    required this.mode,
    required this.lineNumber,
    required this.showDestinationPicker,
    required this.scrollController,
    required this.child,
    required this.canSave,
    required this.onSave,
    required this.canStepBack,
    required this.onStepBack,
  });

  final _ItemEntryMode mode;
  final int lineNumber;
  final bool showDestinationPicker;
  final ScrollController scrollController;
  final Widget child;
  final bool canSave;
  final Future<void> Function() onSave;
  final bool canStepBack;
  final VoidCallback onStepBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !canStepBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && canStepBack) onStepBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundBottom,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundTop,
          foregroundColor: const Color(0xFFE8ECEE),
          title: Text(_title),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
              children: [
                _LineEditorIntro(
                  mode: mode,
                  lineNumber: lineNumber,
                  showDestinationPicker: showDestinationPicker,
                ),
                const SizedBox(height: 14),
                child,
                const SizedBox(height: 12),
                AppButton(
                  label: 'Save Line And Continue',
                  tone: AppButtonTone.commit,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                  ),
                  onPressed: canSave ? () => onSave() : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    return switch (mode) {
      _ItemEntryMode.newInventory => 'Add Inventory Item',
      _ItemEntryMode.catalogInventory => 'Inventory Item',
      _ItemEntryMode.nonInventory => 'Additional Receipt Item',
    };
  }
}

class _LineEditorIntro extends StatelessWidget {
  const _LineEditorIntro({
    required this.mode,
    required this.lineNumber,
    required this.showDestinationPicker,
  });

  final _ItemEntryMode mode;
  final int lineNumber;
  final bool showDestinationPicker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Line $lineNumber',
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _detail,
                  style: const TextStyle(
                    color: Color(0xFFD3DBDE),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    return switch (mode) {
      _ItemEntryMode.newInventory => const Color(0xFF8FD3FF),
      _ItemEntryMode.catalogInventory => const Color(0xFFA9DFFF),
      _ItemEntryMode.nonInventory => const Color(0xFFFFC46B),
    };
  }

  IconData get _icon {
    return switch (mode) {
      _ItemEntryMode.newInventory => Icons.add_box_outlined,
      _ItemEntryMode.catalogInventory => Icons.search_rounded,
      _ItemEntryMode.nonInventory => Icons.receipt_long_outlined,
    };
  }

  String get _detail {
    return switch (mode) {
      _ItemEntryMode.newInventory =>
        'Add one inventory item from this receipt.',
      _ItemEntryMode.catalogInventory =>
        'Choose the item from the catalog, or create it if it is not listed.',
      _ItemEntryMode.nonInventory =>
        'Label a receipt line as business, personal, or mixed without adding it to inventory.',
    };
  }
}
