part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntrySplitPercentActions
    on _ExpenseReceiptEntryScreenState {
  Future<double?> _chooseSplitBusinessPercent(int index) async {
    final line = _lines[index];
    final initial = line.use == _ExpenseLineUse.split
        ? line.effectiveBusinessPercent
        : .5;
    final customController = TextEditingController(
      text: (initial * 100).round().toString(),
    );
    try {
      return await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1F2528),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                10,
                10,
                10,
                MediaQuery.viewInsetsOf(context).bottom + 14,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ReceiptFormPanel(
                    title: 'Split Receipt Line ${index + 1}',
                    subtitle:
                        'Choose the business portion for this line. The rest counts as personal.',
                    icon: Icons.call_split_rounded,
                    accentColor: const Color(0xFF3B7C73),
                    children: [
                      Text(
                        line.displayDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Line amount: ${_money(line.subtotal)}',
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SplitPercentButton(
                            label: '25% Business',
                            percent: .25,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                          _SplitPercentButton(
                            label: '50% Business',
                            percent: .5,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                          _SplitPercentButton(
                            label: '75% Business',
                            percent: .75,
                            onSelected: (value) =>
                                Navigator.of(context).pop(value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RecordTextField(
                        label: 'Custom Business %',
                        helperText:
                            'Enter 0 to 100. Example: 80 means 80% business and 20% personal.',
                        controller: customController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          final entered = _customSplitBusinessPercent(
                            customController.text,
                          );
                          if (entered == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enter a business percentage from 0 to 100.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop(entered);
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Use Custom Split'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      customController.dispose();
    }
  }
}

double? _customSplitBusinessPercent(String value) {
  final normalized = value.replaceAll('%', '').trim();
  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite || parsed < 0 || parsed > 100) {
    return null;
  }
  return parsed / 100;
}
