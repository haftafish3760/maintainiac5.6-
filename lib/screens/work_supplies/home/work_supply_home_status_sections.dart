part of 'work_supply_home_screen.dart';

class _InventoryCommandStatus extends StatelessWidget {
  const _InventoryCommandStatus({
    required this.inventoryCount,
    required this.lowCount,
    required this.draftCount,
    required this.onReviewInventory,
    required this.onResumeDraft,
  });

  final int inventoryCount;
  final int lowCount;
  final int draftCount;
  final VoidCallback onReviewInventory;
  final VoidCallback onResumeDraft;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D5A3E), Color(0xFF102B35)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF58D67D), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inventory Tools',
                    style: TextStyle(
                      color: Color(0xFFBDEFCF),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Find, add, review',
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    draftCount > 0
                        ? '$draftCount draft ${draftCount == 1 ? 'entry' : 'entries'} waiting'
                        : lowCount > 0
                        ? '$lowCount supply ${lowCount == 1 ? 'item needs' : 'items need'} attention'
                        : 'Browse by trade or review what is on hand',
                    style: const TextStyle(
                      color: Color(0xFFD4DDE1),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: draftCount > 0 ? onResumeDraft : onReviewInventory,
              style: FilledButton.styleFrom(
                backgroundColor: draftCount > 0
                    ? const Color(0xFFE0B24D)
                    : const Color(0xFF1976B9),
                foregroundColor: draftCount > 0
                    ? const Color(0xFF101416)
                    : Colors.white,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
              child: Text(draftCount > 0 ? 'Resume' : 'Review'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryDraftPanel extends StatelessWidget {
  const _InventoryDraftPanel({
    required this.draftCount,
    required this.onResumeDraft,
  });

  final int draftCount;
  final VoidCallback onResumeDraft;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onResumeDraft,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFF443416),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0B24D), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_document, color: Color(0xFFFFCF5A)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$draftCount inventory ${draftCount == 1 ? 'draft' : 'drafts'}',
                      style: const TextStyle(
                        color: Color(0xFFFFE2A1),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Resume interrupted receipt or inventory entry work.',
                      style: TextStyle(
                        color: Color(0xFFFFF1C9),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFE2A1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(
        color: Color(0xFFE8ECEE),
        fontWeight: FontWeight.w800,
      ),
      cursorColor: const Color(0xFFE8ECEE),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF172126),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFC7D0D4)),
        hintText: 'Search saved inventory',
        hintStyle: const TextStyle(
          color: Color(0xFF9DA9AE),
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFF53656D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFF53656D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Color(0xFF58A6D6), width: 1.4),
        ),
      ),
    );
  }
}

class _InventoryMessage extends StatelessWidget {
  const _InventoryMessage({required this.lowCount});

  final int lowCount;

  @override
  Widget build(BuildContext context) {
    final text = lowCount == 1
        ? 'You are running low on 1 supply item.'
        : 'You are running low on $lowCount supply items.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF443416),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0B24D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Color(0xFFFFCF5A)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFFFFE2A1),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({
    required this.inventoryCount,
    required this.lowCount,
  });

  final int inventoryCount;
  final int lowCount;

  @override
  Widget build(BuildContext context) {
    final isEmpty = inventoryCount == 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEmpty
                  ? 'Start with the catalog.'
                  : 'Inventory is organized by location.',
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isEmpty
                  ? 'Search or browse by trade first, then add quantity, destination, receipt, and cost details.'
                  : lowCount > 0
                  ? '$lowCount saved ${lowCount == 1 ? 'item is' : 'items are'} at or below the reminder threshold.'
                  : 'Use Review to check company stock, vehicle stock, and custom locations.',
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Browse Plumbing, Electrical, HVAC, Carpentry, Tools, Safety, and more.',
              style: TextStyle(
                color: Color(0xFF8FD3FF),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryRecapStrip extends StatelessWidget {
  const _InventoryRecapStrip({required this.records});

  final List<WorkSupplyInventoryRecord> records;

  @override
  Widget build(BuildContext context) {
    final recaps = buildWorkSupplyInventoryRecaps(
      records: records,
      today: DateTime.now(),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3F7052)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Inventory Recap',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Spending totals use receipt dates, not the day the app was opened.',
              style: TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 9),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth < 390
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final recap in recaps)
                      SizedBox(
                        width: width,
                        child: _InventoryRecapTile(recap: recap),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryRecapTile extends StatelessWidget {
  const _InventoryRecapTile({required this.recap});

  final WorkSupplyInventoryRecap recap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1519),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF4F7F5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recap.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8FE3AA),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _money(recap.totalSpent),
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${recap.itemCount} ${recap.itemCount == 1 ? 'line' : 'lines'} | ${recap.receiptCount} receipt ${recap.receiptCount == 1 ? 'line' : 'lines'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
