part of 'work_supply_add_items_screen.dart';

class _CatalogWizardPathBar extends StatelessWidget {
  const _CatalogWizardPathBar({
    required this.trade,
    required this.category,
    required this.itemType,
    required this.system,
    required this.size,
    required this.onTrade,
    required this.onCategory,
    required this.onItemType,
    required this.onSystem,
    required this.onSize,
  });

  final String trade;
  final String category;
  final String itemType;
  final String system;
  final String size;
  final VoidCallback? onTrade;
  final VoidCallback? onCategory;
  final VoidCallback? onItemType;
  final VoidCallback? onSystem;
  final VoidCallback? onSize;

  @override
  Widget build(BuildContext context) {
    final tokens = <_PathTokenSpec>[
      if (trade.trim().isNotEmpty)
        _PathTokenSpec('Trade', trade, onTrade, _receiptTradeColor(trade)),
      if (category.trim().isNotEmpty)
        _PathTokenSpec(
          'Category',
          category,
          onCategory,
          const Color(0xFF8FD3FF),
        ),
      if (itemType.trim().isNotEmpty)
        _PathTokenSpec('Item', itemType, onItemType, const Color(0xFFFFC46B)),
      if (system.trim().isNotEmpty)
        _PathTokenSpec('Material', system, onSystem, const Color(0xFF64C98A)),
      if (size.trim().isNotEmpty)
        _PathTokenSpec('Size', size, onSize, const Color(0xFFD8A4FF)),
    ];
    if (tokens.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF10191E),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF63B3E6), width: 1.15),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final token in tokens)
            InkWell(
              onTap: token.onTap,
              borderRadius: BorderRadius.circular(6),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: token.color.withValues(alpha: .24),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: token.color, width: 1.1),
                ),
                child: Text(
                  '${token.label}: ${token.value}',
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PathTokenSpec {
  const _PathTokenSpec(this.label, this.value, this.onTap, this.color);

  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color color;
}

class _CatalogWizardChoice {
  const _CatalogWizardChoice({
    required this.label,
    required this.detail,
    required this.color,
    required this.onTap,
    this.imageAsset,
  });

  final String label;
  final String detail;
  final Color color;
  final VoidCallback onTap;
  final String? imageAsset;
}
