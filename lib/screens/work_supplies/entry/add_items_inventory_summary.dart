part of 'work_supply_add_items_screen.dart';

class _PathHint extends StatelessWidget {
  const _PathHint({
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    required this.size,
  });

  final String trade;
  final String category;
  final String system;
  final String itemType;
  final String size;

  @override
  Widget build(BuildContext context) {
    final path = [
      trade,
      category,
      system,
      itemType,
      size,
    ].where((part) => part.trim().isNotEmpty).join(' / ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF102A3A),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF64C98A), width: 1.15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF64C98A),
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemDetailsSummary extends StatelessWidget {
  const _InventoryItemDetailsSummary({
    required this.complete,
    required this.itemName,
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    required this.size,
    required this.onEdit,
  });

  final bool complete;
  final String itemName;
  final String trade;
  final String category;
  final String system;
  final String itemType;
  final String size;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final path = [
      trade,
      category,
      system,
      itemType,
      size,
    ].where((part) => part.trim().isNotEmpty).join(' / ');
    final title = itemName.isEmpty ? 'Inventory item selected' : itemName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _InlineSectionHeader(
          icon: Icons.check_circle_outline_rounded,
          title: 'Item details',
          detail: 'This receipt line is linked to the item below.',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: complete ? const Color(0xFF102A3A) : const Color(0xFF111716),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: complete
                  ? const Color(0xFF64C98A)
                  : const Color(0xFF8FD3FF),
              width: 1.15,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                complete
                    ? Icons.check_circle_rounded
                    : Icons.inventory_2_outlined,
                color: complete
                    ? const Color(0xFF64C98A)
                    : const Color(0xFF8FD3FF),
                size: 23,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF3F0E6),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      path,
                      style: const TextStyle(
                        color: Color(0xFFD8D2C3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        AppButton(
          label: 'Edit Item Details',
          tone: AppButtonTone.general,
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          onPressed: onEdit,
        ),
      ],
    );
  }
}
