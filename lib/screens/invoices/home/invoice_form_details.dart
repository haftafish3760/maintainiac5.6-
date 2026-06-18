import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/calendar/app_date_picker.dart';
import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/signatures/app_signature_capture.dart';
import '../../../shared/signatures/app_signature_models.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/industrial_panel_surface.dart';
import '../../../shared/widgets/record_form_fields.dart';
import '../data/invoice_ledger_models.dart';
import '../data/invoice_record.dart';

part 'invoice_form_sheets.dart';

class InvoiceInformationScreen extends StatefulWidget {
  const InvoiceInformationScreen({required this.record, super.key});

  final InvoiceRecord record;

  @override
  State<InvoiceInformationScreen> createState() =>
      _InvoiceInformationScreenState();
}

class _InvoiceInformationScreenState extends State<InvoiceInformationScreen> {
  final _title = TextEditingController();
  late final TextEditingController _number;
  final _poNumber = TextEditingController();
  late DateTime _invoiceDate;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _title.text = widget.record.title;
    _number = TextEditingController(text: widget.record.invoiceNumber);
    _poNumber.text = widget.record.poNumber;
    _invoiceDate = widget.record.issueDate;
    _dueDate = widget.record.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _number.dispose();
    _poNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InvoiceDetailScaffold(
      title: 'Invoice Information',
      children: [
        RecordTextField(label: 'Invoice Title', controller: _title),
        const SizedBox(height: 10),
        RecordTextField(label: 'Invoice Number', controller: _number),
        const SizedBox(height: 10),
        RecordTextField(label: 'PO Number', controller: _poNumber),
        const SizedBox(height: 10),
        _InvoiceDateSelector(
          label: 'Invoice Date',
          value: appShortDateLabel(_invoiceDate),
          requiredText: 'Required',
          onTap: () => _selectInvoiceDate(),
        ),
        const SizedBox(height: 10),
        _InvoiceDateSelector(
          label: 'Due Date',
          value: _dueDate == null
              ? 'No due date'
              : appShortDateLabel(_dueDate!),
          requiredText: 'Optional',
          onTap: () => _selectDueDate(),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _dueDate = null),
          child: const Text('Clear Due Date'),
        ),
        const SizedBox(height: 12),
        _CancelSaveRow(onSave: _save),
      ],
    );
  }

  Future<void> _selectInvoiceDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _invoiceDate,
    );
    if (picked == null) return;
    setState(() => _invoiceDate = picked);
  }

  Future<void> _selectDueDate() async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _dueDate ?? _invoiceDate,
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  void _save() {
    final number = _number.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document number is required.')),
      );
      return;
    }
    Navigator.of(context).pop(
      widget.record.copyWith(
        title: _title.text.trim(),
        invoiceNumber: number,
        poNumber: _poNumber.text.trim(),
        issueDate: _invoiceDate,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
      ),
    );
  }
}

class InvoiceItemsScreen extends StatefulWidget {
  const InvoiceItemsScreen({required this.record, super.key});

  final InvoiceRecord record;

  @override
  State<InvoiceItemsScreen> createState() => _InvoiceItemsScreenState();
}

class _InvoiceItemsScreenState extends State<InvoiceItemsScreen> {
  late InvoiceRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  @override
  Widget build(BuildContext context) {
    return _InvoiceDetailScaffold(
      title: 'Items & Materials',
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Materials import will connect here.'),
                  ),
                ),
                icon: const Icon(Icons.inventory_rounded),
                label: const Text('Add From Materials'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _addNewItem(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_record.lines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No line items have been added yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          )
        else
          for (final line in _record.lines)
            _InvoiceLinePreview(
              line: line,
              onDelete: () => _removeLine(line.id),
            ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_record),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _addNewItem(BuildContext context) async {
    final line = await Navigator.of(context).push<InvoiceLineItemRecord>(
      appNativeRoute<InvoiceLineItemRecord>(
        context,
        const InvoiceItemEditorScreen(),
      ),
    );
    if (line == null || !context.mounted) return;
    setState(() {
      _record = _record.copyWith(lines: [..._record.lines, line]);
    });
  }

  void _removeLine(String id) {
    setState(() {
      _record = _record.copyWith(
        lines: _record.lines.where((line) => line.id != id).toList(),
      );
    });
  }
}

class InvoiceItemEditorScreen extends StatefulWidget {
  const InvoiceItemEditorScreen({super.key});

  @override
  State<InvoiceItemEditorScreen> createState() =>
      _InvoiceItemEditorScreenState();
}

class _InvoiceItemEditorScreenState extends State<InvoiceItemEditorScreen> {
  final _name = TextEditingController();
  final _details = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _taxRate = TextEditingController();
  var _unit = 'Optional';

  @override
  void dispose() {
    _name.dispose();
    _details.dispose();
    _quantity.dispose();
    _price.dispose();
    _taxRate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InvoiceDetailScaffold(
      title: 'Create Item',
      children: [
        const RecordSectionTitle('Item Info'),
        const SizedBox(height: 12),
        RecordTextField(label: 'Item Name', controller: _name),
        const SizedBox(height: 10),
        RecordTextField(label: 'Details', controller: _details),
        const SizedBox(height: 10),
        RecordTextField(
          label: 'Quantity',
          controller: _quantity,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        const SizedBox(height: 10),
        RecordDropdownField<String>(
          label: 'Unit Of Measure',
          value: _unit,
          items: _invoiceUnits,
          itemLabel: (value) => value,
          onChanged: (value) => setState(() => _unit = value),
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: 'Price',
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: 'Tax Rate',
          controller: _taxRate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 14),
        _TotalPanel(label: 'Total', value: _totalLabel),
        const SizedBox(height: 12),
        _CancelSaveRow(onSave: _save),
      ],
    );
  }

  String get _totalLabel {
    final quantity = _numberValue(_quantity.text, fallback: 1);
    final price = _numberValue(_price.text);
    final taxRate = _numberValue(_taxRate.text);
    final subtotal = quantity * price;
    final total = subtotal + subtotal * taxRate / 100;
    return '\$${total.toStringAsFixed(2)}';
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item name is required.')));
      return;
    }
    Navigator.of(context).pop(
      InvoiceLineItemRecord(
        id: 'line_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        details: _details.text.trim(),
        quantity: _numberValue(_quantity.text, fallback: 1),
        unit: _unit == 'Optional' ? 'item' : _unit,
        unitPrice: _numberValue(_price.text),
        taxRate: _numberValue(_taxRate.text),
      ),
    );
  }
}

class _InvoiceLinePreview extends StatelessWidget {
  const _InvoiceLinePreview({required this.line, required this.onDelete});

  final InvoiceLineItemRecord line;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF141A1D),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF667178)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (line.details.trim().isNotEmpty)
                  Text(
                    line.details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_quantityLabel(line.quantity)} ${line.unit}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${line.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF6BE58D),
              fontWeight: FontWeight.w900,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Line item actions',
            onSelected: (value) {
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailScaffold extends StatelessWidget {
  const _InvoiceDetailScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.invoices,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        children: [
          const AppBackButton(),
          const SizedBox(height: 8),
          AppScreenHeader(title: title),
          const SizedBox(height: 10),
          RecordFormPanel(children: children),
        ],
      ),
    );
  }
}

class _InvoiceDateSelector extends StatelessWidget {
  const _InvoiceDateSelector({
    required this.label,
    required this.value,
    required this.requiredText,
    required this.onTap,
  });

  final String label;
  final String value;
  final String requiredText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFAAB4B9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF101416), width: .8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFF101416),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: _dateStyle(12, FontWeight.w900)),
                    Text(requiredText, style: _dateStyle(10, FontWeight.w700)),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _dateStyle(13, FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF101416),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _dateStyle(double size, FontWeight weight) {
    return TextStyle(
      color: const Color(0xFF101416),
      fontSize: size,
      fontWeight: weight,
    );
  }
}

class _CancelSaveRow extends StatelessWidget {
  const _CancelSaveRow({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(onPressed: onSave, child: const Text('Save')),
        ),
      ],
    );
  }
}

class _TotalPanel extends StatelessWidget {
  const _TotalPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: _TotalLine(label: label, value: value, emphasized: true),
    );
  }
}

const _invoiceUnits = [
  'Optional',
  'Item',
  'Pieces',
  'Labor',
  'Hours',
  'Feet',
  'Yards',
  'Gallons',
  'Boxes',
  'Bags',
  'Packages',
];

double _numberValue(String value, {double fallback = 0}) {
  return double.tryParse(value.trim()) ?? fallback;
}

String _quantityLabel(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
