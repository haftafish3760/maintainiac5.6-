part of 'work_supply_add_items_screen.dart';

class _TypedCatalogSuggestionList extends StatelessWidget {
  const _TypedCatalogSuggestionList({
    required this.suggestions,
    required this.typedSuggestion,
    required this.onApplyTypedSuggestion,
    required this.onApply,
  });

  final List<WorkSupplyItem> suggestions;
  final WorkSupplyItem? typedSuggestion;
  final VoidCallback onApplyTypedSuggestion;
  final ValueChanged<WorkSupplyItem> onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF10252F),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF63B3E6), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.psychology_alt_outlined,
                color: Color(0xFF8FD3FF),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Closest catalog matches',
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (final item in suggestions.take(6)) ...[
            _SuggestionResultRow(
              item: item,
              preferred: typedSuggestion?.id == item.id,
              onTap: () {
                if (typedSuggestion?.id == item.id) {
                  onApplyTypedSuggestion();
                } else {
                  onApply(item);
                }
              },
            ),
            if (item != suggestions.take(6).last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _SuggestionResultRow extends StatelessWidget {
  const _SuggestionResultRow({
    required this.item,
    required this.preferred,
    required this.onTap,
  });

  final WorkSupplyItem item;
  final bool preferred;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Ink(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        decoration: BoxDecoration(
          color: preferred ? const Color(0xFF17324A) : const Color(0xFF111716),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: preferred
                ? const Color(0xFF8FD3FF)
                : const Color(0xFF41535D),
            width: 1.05,
          ),
        ),
        child: Row(
          children: [
            Icon(
              preferred
                  ? Icons.auto_awesome_rounded
                  : Icons.inventory_2_outlined,
              color: preferred
                  ? const Color(0xFF8FD3FF)
                  : const Color(0xFFC7D0D4),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.trade} / ${item.category} / ${item.system} / ${item.itemType}'
                    '${item.variant.isEmpty ? '' : ' / ${item.variant}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFE8ECEE),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
