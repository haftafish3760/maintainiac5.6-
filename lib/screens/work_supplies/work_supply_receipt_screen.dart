import 'package:flutter/material.dart';

import '../../shared/widgets/app_back_button.dart';
import 'data/work_supply_catalog.dart';
import 'data/work_supply_models.dart';

class WorkSupplyReceiptScreen extends StatefulWidget {
  const WorkSupplyReceiptScreen({super.key, this.seedItem});

  final WorkSupplyItem? seedItem;

  @override
  State<WorkSupplyReceiptScreen> createState() =>
      _WorkSupplyReceiptScreenState();
}

class _WorkSupplyReceiptScreenState extends State<WorkSupplyReceiptScreen> {
  final _store = TextEditingController();
  final _search = TextEditingController();
  final _lines = <WorkSupplyItem>[];
  var _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final item = widget.seedItem;
    if (item != null) _lines.add(item);
  }

  @override
  void dispose() {
    _store.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = searchWorkSupplies(_search.text);
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const AppScreenHeader(title: 'Work Supplies Receipt'),
            const SizedBox(height: 12),
            _ReceiptBasics(store: _store, date: _date, onDate: _pickDate),
            const SizedBox(height: 12),
            _SearchField(controller: _search, onChanged: () => setState(() {})),
            const SizedBox(height: 10),
            for (final item in results.take(8))
              _SupplyResultTile(item: item, onTap: () => _addLine(item)),
            const SizedBox(height: 12),
            _ReceiptLines(lines: _lines),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _lines.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Review Receipt'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  void _addLine(WorkSupplyItem item) {
    setState(() => _lines.add(item));
  }
}

class _ReceiptBasics extends StatelessWidget {
  const _ReceiptBasics({
    required this.store,
    required this.date,
    required this.onDate,
  });

  final TextEditingController store;
  final DateTime date;
  final VoidCallback onDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: store,
          style: const TextStyle(color: Color(0xFFE8ECEE)),
          decoration: const InputDecoration(
            labelText: 'Store Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onDate,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text('${date.month}/${date.day}/${date.year}'),
          ),
        ),
      ],
    );
  }
}

class _ReceiptLines extends StatelessWidget {
  const _ReceiptLines({required this.lines});

  final List<WorkSupplyItem> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Text(
        'No receipt items added yet.',
        style: TextStyle(color: Color(0xFFD4DDE1), fontWeight: FontWeight.w800),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Receipt Items',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        for (final item in lines)
          Text(
            '${item.name}  -  ${item.unit}',
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w800,
            ),
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
        labelText: 'Find receipt item',
        hintText: 'Search by name, nickname, size, or trade',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
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
      leading: item.assetPath == null
          ? const SizedBox(width: 42, height: 42)
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                item.assetPath!,
                width: 42,
                height: 42,
                fit: BoxFit.contain,
              ),
            ),
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
