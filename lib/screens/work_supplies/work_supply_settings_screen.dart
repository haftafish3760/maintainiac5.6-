import 'package:flutter/material.dart';

import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'data/work_supply_catalog.dart';
import 'data/work_supply_catalog_audit.dart';
import 'data/work_supply_inventory_settings_store.dart';
import 'data/work_supply_models.dart';

part 'work_supply_settings_controls.dart';
part 'work_supply_settings_panels.dart';

class WorkSupplySettingsScreen extends StatefulWidget {
  const WorkSupplySettingsScreen({super.key});

  @override
  State<WorkSupplySettingsScreen> createState() =>
      _WorkSupplySettingsScreenState();
}

class _WorkSupplySettingsScreenState extends State<WorkSupplySettingsScreen> {
  late final Future<WorkSupplyInventorySettingsController> _settingsFuture;
  final _itemSearch = TextEditingController();
  String? _selectedTrade;

  @override
  void initState() {
    super.initState();
    _settingsFuture = WorkSupplyInventorySettingsController.create();
  }

  @override
  void dispose() {
    _itemSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.materials,
      body: Column(
        children: [
          const GlobalOdometerHeader(section: AppSection.materials),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<WorkSupplyInventorySettingsController>(
              future: _settingsFuture,
              builder: (context, snapshot) {
                final settings = snapshot.data;
                if (settings == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF58D67D)),
                  );
                }
                return AnimatedBuilder(
                  animation: settings,
                  builder: (context, _) => ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    children: [
                      _SettingsIntro(audit: auditWorkSupplyCatalog()),
                      const SizedBox(height: 10),
                      _ReceiptAssistPanel(settings: settings),
                      const SizedBox(height: 10),
                      _CatalogVisibilityPanel(settings: settings),
                      const SizedBox(height: 10),
                      _TradeSettingsPanel(
                        settings: settings,
                        selectedTrade: _selectedTrade,
                        onSelectTrade: (trade) =>
                            setState(() => _selectedTrade = trade),
                      ),
                      if (_selectedTrade != null) ...[
                        const SizedBox(height: 10),
                        _CategorySettingsPanel(
                          settings: settings,
                          trade: _selectedTrade!,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _ItemSettingsPanel(
                        settings: settings,
                        controller: _itemSearch,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
