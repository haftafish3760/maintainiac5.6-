part of 'work_supply_add_items_screen.dart';

class _ExactItemChoices extends StatelessWidget {
  const _ExactItemChoices({required this.items, required this.onItemSelected});

  final List<WorkSupplyItem> items;
  final ValueChanged<WorkSupplyItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 680 ? 4 : (width >= 390 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 1.52,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ExactItemTile(
              item: item,
              onTap: () => onItemSelected(item),
            );
          },
        );
      },
    );
  }
}

class _ExactItemTile extends StatelessWidget {
  const _ExactItemTile({required this.item, required this.onTap});

  final WorkSupplyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF0E1519),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4D626B), width: 1.15),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.variant,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC7D0D4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFF64C98A),
                      size: 17,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onItemSelected});

  final List<WorkSupplyItem> results;
  final ValueChanged<WorkSupplyItem> onItemSelected;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'No matching catalog items.',
          style: TextStyle(
            color: Color(0xFFC7D0D4),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final item in results)
          _ItemChoiceRow(item: item, onTap: () => onItemSelected(item)),
      ],
    );
  }
}

class _ItemChoiceRow extends StatelessWidget {
  const _ItemChoiceRow({required this.item, required this.onTap});

  final WorkSupplyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1519),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3F5058)),
      ),
      child: ListTile(
        dense: true,
        title: Text(
          item.name,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        trailing: const Icon(
          Icons.add_circle_outline_rounded,
          color: Color(0xFF64C98A),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _Choice {
  const _Choice({
    required this.label,
    required this.detail,
    required this.onTap,
    this.color,
  });

  final String label;
  final String detail;
  final VoidCallback onTap;
  final Color? color;
}
