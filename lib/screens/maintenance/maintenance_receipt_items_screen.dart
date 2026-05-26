import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/industrial_panel.dart';
import '../../shared/widgets/record_text_field.dart';
import 'maintenance_item_setup_screen.dart';
import 'maintenance_models.dart';
import 'maintenance_receipt_line_form_screen.dart';

class MaintenanceReceiptItemsScreen extends StatefulWidget {
  const MaintenanceReceiptItemsScreen({
    required this.items,
    required this.workSource,
    super.key,
  });

  final List<MaintenanceCatalogItem> items;
  final WorkSource workSource;

  @override
  State<MaintenanceReceiptItemsScreen> createState() =>
      _MaintenanceReceiptItemsScreenState();
}

class _MaintenanceReceiptItemsScreenState
    extends State<MaintenanceReceiptItemsScreen> {
  final Map<String, List<ReceiptLineEntry>> _entries = {};
  final _subtotal = TextEditingController();
  final _tax = TextEditingController();
  final _total = TextEditingController();

  @override
  void dispose() {
    _subtotal.dispose();
    _tax.dispose();
    _total.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = _entries.values.expand((entry) => entry).toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              const AppScreenHeader(title: 'Receipt Items'),
              const SizedBox(height: 10),
              IndustrialPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fill Out Receipt Lines',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap an item to enter what was purchased. Add as many lines as the receipt needs.',
                    ),
                    const SizedBox(height: 10),
                    ActionChip(
                      label: const Text('Add Non-Maintenance Item'),
                      avatar: const Text('➕'),
                      onPressed: () {},
                    ),
                    const SizedBox(height: 8),
                    for (final item in widget.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ReceiptItemRow(
                          item: item,
                          entries: _entries[item.name] ?? const [],
                          onTap: () => _openLineForm(item),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              IndustrialPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Receipt Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAAB4B9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'MAINTENANCE RECEIPT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Divider(color: AppColors.ink),
                          if (allEntries.isEmpty)
                            const Text(
                              'No receipt lines entered yet.',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            for (final entry in allEntries)
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.productName.isEmpty
                                          ? entry.itemName
                                          : entry.productName,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${entry.totalCost.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MoneyField(
                            label: 'Subtotal',
                            controller: _subtotal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MoneyField(label: 'Tax', controller: _tax),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MoneyField(
                            label: 'Total',
                            controller: _total,
                            action: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        label: 'Save And Continue',
                        tone: AppButtonTone.commit,
                        compact: true,
                        onPressed: () => Navigator.of(context).push(
                          appNativeRoute(
                            context,
                            MaintenanceItemSetupScreen(
                              items: widget.items,
                              entries: allEntries,
                            ),
                          ),
                        ),
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

  Future<void> _openLineForm(MaintenanceCatalogItem item) async {
    final entry = await Navigator.of(context).push<ReceiptLineEntry>(
      appNativeRoute(context, MaintenanceReceiptLineFormScreen(item: item)),
    );
    if (entry == null) return;
    setState(() => _entries.putIfAbsent(item.name, () => []).add(entry));
  }
}

class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({
    required this.item,
    required this.entries,
    required this.onTap,
  });

  final MaintenanceCatalogItem item;
  final List<ReceiptLineEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Ink(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.fieldAlt,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              entries.isEmpty ? 'Add' : '${entries.length}',
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required this.controller,
    this.action = TextInputAction.next,
  });

  final String label;
  final TextEditingController controller;
  final TextInputAction action;

  @override
  Widget build(BuildContext context) {
    return RecordTextField(
      label: label,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: action,
    );
  }
}
