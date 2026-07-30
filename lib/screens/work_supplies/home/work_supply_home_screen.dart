import 'package:flutter/material.dart';

import '../../../shared/calendar/calendar_flow_models.dart';
import '../../../shared/calendar/calendar_inventory_projection_adapter.dart';
import '../calendar/work_supply_calendar_panel.dart';
import '../data/work_supply_models.dart';
import '../data/work_supply_inventory_recap.dart';

part 'work_supply_home_calendar_sections.dart';
part 'work_supply_home_status_sections.dart';

class WorkSupplyHomeScreen extends StatelessWidget {
  const WorkSupplyHomeScreen({
    super.key,
    required this.query,
    required this.inventoryRecords,
    required this.inventoryTransactions,
    required this.draftCount,
    required this.selectedCalendarDay,
    required this.inventoryCount,
    required this.lowCount,
    required this.hasMessages,
    required this.showIntro,
    required this.onQueryChanged,
    required this.onAddItems,
    required this.onDismissIntro,
    required this.onResumeDraft,
    required this.onReviewInventory,
    required this.onCalendarDaySelected,
    required this.onOpenJobs,
  });

  final String query;
  final List<WorkSupplyInventoryRecord> inventoryRecords;
  final List<WorkSupplyInventoryTransaction> inventoryTransactions;
  final int draftCount;
  final DateTime selectedCalendarDay;
  final int inventoryCount;
  final int lowCount;
  final bool hasMessages;
  final bool showIntro;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onAddItems;
  final VoidCallback onDismissIntro;
  final VoidCallback onResumeDraft;
  final VoidCallback onReviewInventory;
  final ValueChanged<DateTime> onCalendarDaySelected;
  final VoidCallback onOpenJobs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasMessages) ...[
            _InventoryMessage(lowCount: lowCount),
            const SizedBox(height: 10),
          ],
          const _ScreenTitle(),
          const SizedBox(height: 10),
          if (showIntro) ...[
            _WorkSupplyIntroPanel(onDismiss: onDismissIntro),
            const SizedBox(height: 10),
          ],
          _WorkSupplyPrimaryActions(onAddSupplies: onAddItems),
          const SizedBox(height: 12),
          _InventoryCommandStatus(
            inventoryCount: inventoryCount,
            lowCount: lowCount,
            draftCount: draftCount,
            onReviewInventory: onReviewInventory,
            onResumeDraft: onResumeDraft,
          ),
          const SizedBox(height: 10),
          if (draftCount > 0) ...[
            _InventoryDraftPanel(
              draftCount: draftCount,
              onResumeDraft: onResumeDraft,
            ),
            const SizedBox(height: 10),
          ],
          _SearchField(value: query, onChanged: onQueryChanged),
          const SizedBox(height: 12),
          _InventorySummary(inventoryCount: inventoryCount, lowCount: lowCount),
          const SizedBox(height: 12),
          _InventoryRecapStrip(records: inventoryRecords),
          const SizedBox(height: 12),
          _InventoryCalendarHomePanel(
            records: inventoryRecords,
            transactions: inventoryTransactions,
            selectedDay: selectedCalendarDay,
            onDaySelected: onCalendarDaySelected,
          ),
        ],
      ),
    );
  }
}

class _WorkSupplyIntroPanel extends StatelessWidget {
  const _WorkSupplyIntroPanel({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF132126),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF58A6D6), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.inventory_2_rounded,
              color: Color(0xFF8FD3FF),
              size: 22,
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set up only the supplies you track',
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Inventory shows saved stock. Trade packs help search, receipt review, and add-item suggestions when you choose to use them.',
                    style: TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, color: Color(0xFFC7D0D4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Track what is on hand, what it cost, and where the receipt lives.',
          style: TextStyle(
            color: Color(0xFFC7D0D4),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _WorkSupplyPrimaryActions extends StatelessWidget {
  const _WorkSupplyPrimaryActions({required this.onAddSupplies});

  final VoidCallback onAddSupplies;

  @override
  Widget build(BuildContext context) {
    return _PrimaryActionButton(
      label: 'Add Inventory / Receipt',
      icon: Icons.add_box_outlined,
      color: const Color(0xFF2F7D4B),
      onTap: onAddSupplies,
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}
