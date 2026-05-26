import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import 'data/work_supply_catalog.dart';
import 'data/work_supply_models.dart';
import 'work_supply_receipt_screen.dart';

class WorkSupplyScreen extends StatefulWidget {
  const WorkSupplyScreen({super.key});

  @override
  State<WorkSupplyScreen> createState() => _WorkSupplyScreenState();
}

class _WorkSupplyScreenState extends State<WorkSupplyScreen> {
  final _search = TextEditingController();
  WorkSupplyTrade? _selectedTrade;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text;
    final results = searchWorkSupplies(query);
    return AppScreenShell(
      section: AppSection.materials,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        children: [
          const AppScreenHeader(title: 'Work Supplies', centerTitle: true),
          const SizedBox(height: 10),
          const GlobalOdometerHeader(section: AppSection.materials),
          const SizedBox(height: 10),
          _PrimaryActions(onReceipt: _openReceipt, onAdd: _openBlankAdd),
          const SizedBox(height: 12),
          _SearchField(controller: _search, onChanged: () => setState(() {})),
          const SizedBox(height: 10),
          _TradeFilter(
            selected: _selectedTrade,
            onSelected: (trade) => setState(() => _selectedTrade = trade),
          ),
          const SizedBox(height: 12),
          if (query.trim().isNotEmpty)
            _SearchResults(items: results, onSelected: _openReceiptFor)
          else
            _TradeBrowser(
              trade: _selectedTrade ?? workSupplyTrades.first,
              onSelected: _openReceiptFor,
            ),
        ],
      ),
    );
  }

  void _openReceipt() {
    Navigator.of(
      context,
    ).push(appNativeRoute<void>(context, const WorkSupplyReceiptScreen()));
  }

  void _openBlankAdd() {
    Navigator.of(
      context,
    ).push(appNativeRoute<void>(context, const WorkSupplyReceiptScreen()));
  }

  void _openReceiptFor(WorkSupplyItem item) {
    Navigator.of(context).push(
      appNativeRoute<void>(context, WorkSupplyReceiptScreen(seedItem: item)),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.onReceipt, required this.onAdd});

  final VoidCallback onReceipt;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(label: 'Log Receipt', onTap: onReceipt),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(label: 'Add Supply', onTap: onAdd),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: const TextStyle(color: Color(0xFFE8ECEE)),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        labelText: 'Search supplies',
        hintText: 'Try half inch copper 90, Romex, pipe dope',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _TradeFilter extends StatelessWidget {
  const _TradeFilter({required this.selected, required this.onSelected});

  final WorkSupplyTrade? selected;
  final ValueChanged<WorkSupplyTrade> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final trade in workSupplyTrades)
          ChoiceChip(
            label: Text(trade.name),
            selected: selected?.name == trade.name,
            selectedColor: trade.color,
            backgroundColor: const Color(0xFF252D31),
            onSelected: (_) => onSelected(trade),
            labelStyle: TextStyle(
              color: selected?.name == trade.name
                  ? const Color(0xFF07100A)
                  : const Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class _TradeBrowser extends StatelessWidget {
  const _TradeBrowser({required this.trade, required this.onSelected});

  final WorkSupplyTrade trade;
  final ValueChanged<WorkSupplyItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TradeHeader(trade: trade),
        const SizedBox(height: 8),
        for (final group in trade.groups)
          ExpansionTile(
            title: Text(group.name),
            textColor: trade.color,
            collapsedTextColor: const Color(0xFFE8ECEE),
            iconColor: trade.color,
            children: [
              for (final material in group.materials)
                ExpansionTile(
                  title: Text(material.name),
                  children: [
                    for (final item in material.items)
                      _SupplyResultTile(
                        item: item,
                        onTap: () => onSelected(item),
                      ),
                  ],
                ),
              for (final item in group.items)
                _SupplyResultTile(item: item, onTap: () => onSelected(item)),
            ],
          ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.items, required this.onSelected});

  final List<WorkSupplyItem> items;
  final ValueChanged<WorkSupplyItem> onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text(
        'No matching supply found. Add it as a new supply from the receipt.',
        style: TextStyle(color: Color(0xFFD4DDE1), fontWeight: FontWeight.w800),
      );
    }
    return Column(
      children: [
        for (final item in items)
          _SupplyResultTile(item: item, onTap: () => onSelected(item)),
      ],
    );
  }
}

class _SupplyResultTile extends StatelessWidget {
  const _SupplyResultTile({required this.item, required this.onTap});

  final WorkSupplyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: _SupplyThumb(path: item.assetPath),
      title: Text(
        item.name,
        style: const TextStyle(
          color: Color(0xFFE8ECEE),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        '${item.path}  -  ${item.unit}',
        style: const TextStyle(
          color: Color(0xFFD4DDE1),
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.add_circle_rounded, color: Color(0xFF58D67D)),
    );
  }
}

class _TradeHeader extends StatelessWidget {
  const _TradeHeader({required this.trade});

  final WorkSupplyTrade trade;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SupplyThumb(path: trade.assetPath),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            trade.name,
            style: TextStyle(
              color: trade.color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupplyThumb extends StatelessWidget {
  const _SupplyThumb({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final asset = path;
    if (asset == null) {
      return const SizedBox(width: 42, height: 42);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(asset, width: 42, height: 42, fit: BoxFit.contain),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1976B9),
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}
