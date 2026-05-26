part of 'expense_entry_screen.dart';

class _CategoryDetailsPanel extends StatelessWidget {
  const _CategoryDetailsPanel({
    required this.category,
    required this.amountController,
    required this.quantityController,
    required this.unitPriceController,
    required this.itemController,
    required this.detailController,
    required this.fuelType,
    required this.destination,
    required this.fillType,
    required this.payment,
    required this.onFuelTypeChanged,
    required this.onDestinationChanged,
    required this.onFillTypeChanged,
    required this.onPaymentChanged,
  });

  final String category;
  final TextEditingController amountController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController itemController;
  final TextEditingController detailController;
  final String fuelType;
  final String destination;
  final String fillType;
  final String payment;
  final ValueChanged<String> onFuelTypeChanged;
  final ValueChanged<String> onDestinationChanged;
  final ValueChanged<String> onFillTypeChanged;
  final ValueChanged<String> onPaymentChanged;

  @override
  Widget build(BuildContext context) {
    final fuel = category == 'Fuel';
    return RecordFormPanel(
      children: [
        if (fuel) ..._fuelFields() else ..._receiptLineFields(),
        RecordDropdownField<String>(
          label: 'Payment Method',
          value: payment,
          items: const ['Card', 'Cash', 'Check', 'Other'],
          itemLabel: (value) => value,
          onChanged: onPaymentChanged,
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: fuel ? 'Fuel Total' : 'Amount',
          helperText: 'Required',
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  List<Widget> _fuelFields() {
    final electric = fuelType == 'Electric';
    return [
      RecordDropdownField<String>(
        label: 'Fuel Type',
        value: fuelType,
        items: const ['Gas', 'Diesel', 'Electric'],
        itemLabel: (value) => value,
        onChanged: onFuelTypeChanged,
      ),
      const SizedBox(height: 10),
      RecordDropdownField<String>(
        label: 'Destination',
        value: destination,
        items: const ['Vehicle tank', 'Fuel can', 'Equipment'],
        itemLabel: (value) => value,
        onChanged: onDestinationChanged,
      ),
      const SizedBox(height: 10),
      RecordDropdownField<String>(
        label: 'Fill Type',
        value: fillType,
        items: const ['Full tank', 'Partial fill'],
        itemLabel: (value) => value,
        onChanged: onFillTypeChanged,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: RecordTextField(
              label: electric ? 'Kilowatt Hours' : 'Gallons',
              helperText: 'Required',
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RecordTextField(
              label: electric ? 'Price Per kWh' : 'Price Per Gallon',
              helperText: electric
                  ? 'Required'
                  : 'Required - include 9/10 pricing when shown.',
              controller: unitPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
    ];
  }

  List<Widget> _receiptLineFields() {
    final spec = _ExpenseLineSpec.forCategory(category);
    return [
      RecordTextField(
        label: spec.primaryLabel,
        helperText: spec.primaryHelper,
        controller: itemController,
        textInputAction: TextInputAction.next,
      ),
      if (spec.detailLabel != null) ...[
        const SizedBox(height: 10),
        RecordTextField(
          label: spec.detailLabel!,
          helperText: spec.detailHelper,
          controller: detailController,
          textInputAction: TextInputAction.next,
        ),
      ],
      const SizedBox(height: 10),
    ];
  }
}

class _ExpenseLineSpec {
  const _ExpenseLineSpec({
    required this.primaryLabel,
    required this.primaryHelper,
    this.detailLabel,
    this.detailHelper,
  });

  final String primaryLabel;
  final String primaryHelper;
  final String? detailLabel;
  final String? detailHelper;

  static _ExpenseLineSpec forCategory(String category) {
    return switch (category) {
      'Repair' => const _ExpenseLineSpec(
        primaryLabel: 'Service / Part',
        primaryHelper: 'Required - what was repaired or replaced.',
        detailLabel: 'Repair Notes',
        detailHelper: 'Optional',
      ),
      'Insurance' => const _ExpenseLineSpec(
        primaryLabel: 'Coverage / Policy',
        primaryHelper: 'Required - do not enter sensitive account numbers.',
        detailLabel: 'Coverage Period',
        detailHelper: 'Optional',
      ),
      'Loan/Lease' => const _ExpenseLineSpec(
        primaryLabel: 'Vehicle / Asset',
        primaryHelper: 'Required - do not enter bank account numbers.',
        detailLabel: 'Payment Period',
        detailHelper: 'Optional',
      ),
      'Parking' => const _ExpenseLineSpec(
        primaryLabel: 'Parking Location',
        primaryHelper: 'Required',
        detailLabel: 'Duration',
        detailHelper: 'Optional',
      ),
      'Tolls' => const _ExpenseLineSpec(
        primaryLabel: 'Road / Toll Plaza',
        primaryHelper: 'Required',
        detailLabel: 'Trip Direction',
        detailHelper: 'Optional',
      ),
      'Meals' => const _ExpenseLineSpec(
        primaryLabel: 'Meal / Stop',
        primaryHelper: 'Required',
        detailLabel: 'Business Purpose',
        detailHelper: 'Optional, but useful for audit-ready records.',
      ),
      'Tools' => const _ExpenseLineSpec(
        primaryLabel: 'Tool Name',
        primaryHelper: 'Required',
        detailLabel: 'Serial / Warranty',
        detailHelper: 'Optional',
      ),
      'Supplies' => const _ExpenseLineSpec(
        primaryLabel: 'Supply Item',
        primaryHelper: 'Required',
        detailLabel: 'Job / Use',
        detailHelper: 'Optional',
      ),
      'Tags' => const _ExpenseLineSpec(
        primaryLabel: 'Registration Item',
        primaryHelper: 'Required',
        detailLabel: 'Plate / State',
        detailHelper: 'Optional',
      ),
      'Utilities' => const _ExpenseLineSpec(
        primaryLabel: 'Utility Type',
        primaryHelper: 'Required',
        detailLabel: 'Service Period',
        detailHelper: 'Optional',
      ),
      _ => const _ExpenseLineSpec(
        primaryLabel: 'Item Name',
        primaryHelper: 'Required - what appears on the receipt.',
        detailLabel: 'Expense Detail',
        detailHelper: 'Optional',
      ),
    };
  }
}
