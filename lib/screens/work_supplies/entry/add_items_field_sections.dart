part of 'work_supply_add_items_screen.dart';

class _PurchaseTypePicker extends StatelessWidget {
  const _PurchaseTypePicker({required this.selected, required this.onSelected});

  final _PurchaseType selected;
  final ValueChanged<_PurchaseType> onSelected;

  @override
  Widget build(BuildContext context) {
    return _DropdownField<_PurchaseType>(
      label: 'How was this item packaged or sold?',
      value: selected,
      items: _PurchaseType.values,
      itemLabel: (type) => '${type.label} - ${type.detail}',
      onChanged: onSelected,
    );
  }
}

class _PurchaseMathPreview extends StatelessWidget {
  const _PurchaseMathPreview({
    required this.purchaseType,
    required this.packages,
    required this.unitsPerPackage,
    required this.subtotal,
    required this.taxRate,
  });

  final _PurchaseType purchaseType;
  final TextEditingController packages;
  final TextEditingController unitsPerPackage;
  final TextEditingController subtotal;
  final TextEditingController taxRate;

  @override
  Widget build(BuildContext context) {
    final packageCount = _read(packages.text, 0);
    final perPackage = !purchaseType.asksUnitsPerContainer
        ? 1.0
        : _read(unitsPerPackage.text, 0);
    final beforeTax = _read(subtotal.text, 0);
    final taxPercent = _read(taxRate.text, 0);
    final totalUnits = packageCount * perPackage;
    final totalWithTax = beforeTax * (1 + taxPercent / 100);
    final unitCost = totalUnits <= 0 ? 0.0 : totalWithTax / totalUnits;
    final hasCost = beforeTax > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1519),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3F5058)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calculate_rounded,
            color: Color(0xFF8FD3FF),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasCost
                  ? 'Adds ${_formatNumber(totalUnits)} ${totalUnits == 1 ? 'unit' : 'units'} at \$${unitCost.toStringAsFixed(2)} each with tax.'
                  : 'Adds ${_formatNumber(totalUnits)} ${totalUnits == 1 ? 'unit' : 'units'}. Cost can be left blank when it is unknown.',
              style: const TextStyle(
                color: Color(0xFFDDE6EA),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _read(String value, double fallback) {
    return double.tryParse(value.trim()) ?? fallback;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

class _PackageIdentityPanel extends StatelessWidget {
  const _PackageIdentityPanel({
    required this.barcodeValue,
    required this.packageLabel,
    required this.purchaseType,
    required this.unitsPerPackage,
    required this.onChanged,
  });

  final TextEditingController barcodeValue;
  final TextEditingController packageLabel;
  final _PurchaseType purchaseType;
  final TextEditingController unitsPerPackage;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFFFFC46B),
              size: 19,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Optional. This saves the barcode or QR text only, not a photo of the code. Camera scanning can be added later.',
                style: TextStyle(
                  color: Color(0xFFE8D8BF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Field(
          controller: barcodeValue,
          label: 'Barcode or QR text',
          hint: 'Type the UPC, QR text, or package code',
          keyboardType: TextInputType.text,
          onChanged: onChanged,
        ),
        _Field(
          controller: packageLabel,
          label: 'Package label',
          hint: _defaultPackageLabel,
          keyboardType: TextInputType.text,
          onChanged: onChanged,
        ),
      ],
    );
  }

  String get _defaultPackageLabel {
    if (purchaseType.isEach) return 'Example: Each';
    final count = double.tryParse(unitsPerPackage.text.trim()) ?? 1;
    final countText = count == count.roundToDouble()
        ? count.toInt().toString()
        : count.toStringAsFixed(2);
    return 'Example: ${purchaseType.label} of $countText';
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = items.contains(value) ? value : items.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          DropdownButtonFormField<T>(
            key: ValueKey<String>(
              '$label-$safeValue-${items.map(itemLabel).join('|')}',
            ),
            initialValue: safeValue,
            isExpanded: true,
            dropdownColor: const Color(0xFF172126),
            iconEnabledColor: const Color(0xFFE8ECEE),
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w800,
            ),
            decoration: _inputDecoration(),
            items: [
              for (final item in items)
                DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            onChanged: onChanged,
            cursorColor: const Color(0xFFE8ECEE),
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w800,
            ),
            decoration: _inputDecoration(hint: hint),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE8ECEE),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFF0B1114),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    hintStyle: const TextStyle(color: Color(0xFF8F9A9F)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF6E7B81), width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFF8FD3FF), width: 1.5),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
  );
}
