part of 'expense_receipt_entry_screen.dart';

class _LineUseBanner extends StatelessWidget {
  const _LineUseBanner({required this.use});

  final _ExpenseLineUse use;

  @override
  Widget build(BuildContext context) {
    final isPersonal = use == _ExpenseLineUse.personal;
    final isSplit = use == _ExpenseLineUse.split;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: isSplit
            ? const Color(0xFF3B7C73)
            : isPersonal
            ? const Color(0xFF59636A)
            : const Color(0xFF2E78B7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isSplit
                ? Icons.call_split_rounded
                : isPersonal
                ? Icons.person_rounded
                : Icons.business_center_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${use.label} expense line',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParserReviewNotice extends StatelessWidget {
  const _ParserReviewNotice({required this.line});

  final _ExpenseReceiptLine line;

  @override
  Widget build(BuildContext context) {
    final color = line.parserBadgeColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            line.parserNeedsReview
                ? Icons.rule_rounded
                : Icons.verified_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.parserReviewSummary,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                if ((line.parserReviewReason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line.parserReviewReason!.trim(),
                    style: const TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitAllocationFields extends StatelessWidget {
  const _SplitAllocationFields({
    required this.businessPercentController,
    required this.businessPercent,
  });

  final TextEditingController businessPercentController;
  final double businessPercent;

  @override
  Widget build(BuildContext context) {
    final personalPercent = 1 - businessPercent;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3B7C73)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Shared Item Split',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          RecordTextField(
            label: 'Business Percent',
            controller: businessPercentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            helperText: 'Enter 75 for 75%. The rest is personal.',
          ),
          const SizedBox(height: 8),
          Text(
            'Business ${_percent(businessPercent)} | Personal ${_percent(personalPercent)}',
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelAllocationNotice extends StatelessWidget {
  const _FuelAllocationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E78B7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Fuel will be allocated from mileage once trip records are available.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRuleNotice extends StatelessWidget {
  const _CategoryRuleNotice({required this.rule});

  final ExpenseReceiptCategoryRule rule;

  @override
  Widget build(BuildContext context) {
    final icon = switch (rule.mode) {
      ExpenseReceiptLineInputMode.fuel => Icons.local_gas_station_rounded,
      ExpenseReceiptLineInputMode.amountOnly => Icons.receipt_long_rounded,
      ExpenseReceiptLineInputMode.measuredItem => Icons.inventory_2_rounded,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule.guidance,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelReceiptFields extends StatelessWidget {
  const _FuelReceiptFields({
    required this.odometerController,
    required this.unitPriceController,
    required this.fuelType,
    required this.fillType,
    required this.onFuelTypeChanged,
    required this.onFillTypeChanged,
  });

  final TextEditingController odometerController;
  final TextEditingController unitPriceController;
  final String fuelType;
  final String fillType;
  final ValueChanged<String> onFuelTypeChanged;
  final ValueChanged<String> onFillTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RecordTextField(
          label: 'Odometer Reading',
          helperText: 'Required for MPG and business/personal fuel allocation.',
          controller: odometerController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: RecordDropdownField<String>(
                label: 'Fuel Or Energy Type',
                value: fuelType,
                items: const ['Gasoline', 'Diesel', 'Electric'],
                itemLabel: (value) => value,
                onChanged: onFuelTypeChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RecordDropdownField<String>(
                label: 'Fill Type',
                value: fillType,
                items: const ['Full fill-up', 'Partial fill'],
                itemLabel: (value) => value,
                onChanged: onFillTypeChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RecordTextField(
          label: fuelType == 'Electric' ? 'Price Per kWh' : 'Price Per Gallon',
          helperText: 'Optional if the receipt only shows the line total.',
          controller: unitPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
