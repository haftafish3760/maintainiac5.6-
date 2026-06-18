import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/industrial_panel.dart';
import '../../shared/widgets/record_text_field.dart';
import '../../shared/widgets/receipt_capture/receipt_capture.dart';
import 'maintenance_models.dart';
import 'maintenance_receipt_items_screen.dart';
import 'maintenance_item_setup_screen.dart';
import 'maintenance_svg_icon.dart';

class MaintenanceSetupScreen extends StatefulWidget {
  const MaintenanceSetupScreen({
    required this.workSource,
    this.initialItems = const [],
    super.key,
  });

  final WorkSource workSource;
  final List<MaintenanceCatalogItem> initialItems;

  @override
  State<MaintenanceSetupScreen> createState() => _MaintenanceSetupScreenState();
}

class _MaintenanceSetupScreenState extends State<MaintenanceSetupScreen> {
  final Set<MaintenanceCatalogItem> _selected = {};
  bool _hasReceipt = false;
  String _storeName = '';

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.initialItems);
  }

  @override
  Widget build(BuildContext context) {
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
              const AppScreenHeader(title: 'Manual Maintenance Setup'),
              const SizedBox(height: 10),
              IndustrialPanel(
                child: Row(
                  children: [
                    Expanded(
                      child: _SmallField(
                        label: 'Receipt Date',
                        value: 'Select date',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SmallField(
                        label: 'Receipt Time',
                        value: 'Optional',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SharedReceiptAttachmentPanel(
                hasReceipt: _hasReceipt,
                area: ReceiptCaptureArea.maintenanceRepair,
                onChanged: (value) => setState(() => _hasReceipt = value),
              ),
              const SizedBox(height: 10),
              IndustrialPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Purchase Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_storeName.isNotEmpty)
                      Text(
                        _storeName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: _storeName.isEmpty
                          ? 'Fill Out Store Information'
                          : 'Edit Store',
                      compact: true,
                      onPressed: _editStore,
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
                      'Items On This Setup',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select maintenance items you want to log or set up.',
                    ),
                    const SizedBox(height: 10),
                    for (final item in maintenanceCatalog)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _MaintenanceChoice(
                          item: item,
                          selected: _selected.contains(item),
                          onTap: () => setState(
                            () => _selected.contains(item)
                                ? _selected.remove(item)
                                : _selected.add(item),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        label: 'Next',
                        tone: AppButtonTone.commit,
                        compact: true,
                        onPressed: _selected.isEmpty ? null : _next,
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

  void _next() {
    final items = _selected.toList();
    if (_hasReceipt || _storeName.trim().isNotEmpty) {
      Navigator.of(context).push(
        appNativeRoute(
          context,
          MaintenanceReceiptItemsScreen(
            items: items,
            workSource: widget.workSource,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        appNativeRoute(
          context,
          MaintenanceItemSetupScreen(items: items, entries: const []),
        ),
      );
    }
  }

  Future<void> _editStore() async {
    final controller = TextEditingController(text: _storeName);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            RecordTextField(
              label: 'Store name',
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) =>
                  Navigator.pop(context, controller.text.trim()),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'Save And Continue',
                tone: AppButtonTone.commit,
                compact: true,
                onPressed: () => Navigator.pop(context, controller.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _storeName = result);
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return BorderLabel(
      label: label,
      padding: const EdgeInsets.all(8),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _MaintenanceChoice extends StatelessWidget {
  const _MaintenanceChoice({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MaintenanceCatalogItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(5),
      onTap: onTap,
      child: Ink(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.fieldAlt,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            MaintenanceSvgIcon(itemName: item.name, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
