part of 'expense_receipt_entry_screen.dart';

class _ReceiptLineActionsPanel extends StatelessWidget {
  const _ReceiptLineActionsPanel({
    required this.nextLineNumber,
    required this.materialMode,
    required this.maintenanceRepairMode,
    required this.fuelMode,
    required this.basicMode,
    required this.detailedMode,
    required this.onAddBusiness,
    required this.onAddPersonal,
    required this.onAddShared,
    required this.onAddMaterial,
    required this.onAddMaintenanceRepair,
  });

  final int nextLineNumber;
  final bool materialMode;
  final bool maintenanceRepairMode;
  final bool fuelMode;
  final bool basicMode;
  final bool detailedMode;
  final VoidCallback onAddBusiness;
  final VoidCallback onAddPersonal;
  final VoidCallback onAddShared;
  final VoidCallback onAddMaterial;
  final VoidCallback onAddMaintenanceRepair;

  @override
  Widget build(BuildContext context) {
    if (basicMode) return const SizedBox.shrink();
    final label = nextLineNumber == 1
        ? 'Add Receipt Items'
        : 'Add Another Receipt Item';
    final helper = !detailedMode && !fuelMode && !maintenanceRepairMode
        ? 'Simple review: enter each amount and choose Business, Personal, or Split.'
        : fuelMode
        ? 'Enter the fuel line from this receipt.'
        : maintenanceRepairMode
        ? 'Enter the service or repair line from this receipt.'
        : 'Full detail review: add names, quantities, categories, and amounts.';
    return _ReceiptActionButton(
      label: label,
      helper: helper,
      icon: Icons.playlist_add_rounded,
      color: const Color(0xFF2E78B7),
      onTap: () => _showReceiptItemChoice(context),
    );
  }

  Future<void> _showReceiptItemChoice(BuildContext context) async {
    if (fuelMode) {
      onAddBusiness();
      return;
    }
    if (maintenanceRepairMode) {
      onAddMaintenanceRepair();
      return;
    }
    if (materialMode && detailedMode) {
      onAddMaterial();
      return;
    }
    final action = await showModalBottomSheet<VoidCallback>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'How should this receipt line count?',
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _ReceiptActionButton(
                  label: 'Business Item',
                  helper: 'For a receipt line bought for work.',
                  icon: Icons.business_center_rounded,
                  color: const Color(0xFF2E78B7),
                  onTap: () => Navigator.of(context).pop(onAddBusiness),
                ),
                const SizedBox(height: 8),
                _ReceiptActionButton(
                  label: 'Personal Item',
                  helper: 'For a personal receipt line.',
                  icon: Icons.person_rounded,
                  color: const Color(0xFF59636A),
                  onTap: () => Navigator.of(context).pop(onAddPersonal),
                ),
                const SizedBox(height: 8),
                _ReceiptActionButton(
                  label: 'Shared Item',
                  helper: 'For one line split between business and personal.',
                  icon: Icons.call_split_rounded,
                  color: const Color(0xFF3B7C73),
                  onTap: () => Navigator.of(context).pop(onAddShared),
                ),
              ],
            ),
          ),
        );
      },
    );
    action?.call();
  }
}

class _ReceiptActionButton extends StatelessWidget {
  const _ReceiptActionButton({
    required this.label,
    required this.helper,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String helper;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      helper,
                      style: const TextStyle(
                        color: Color(0xFFEAF0EE),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
