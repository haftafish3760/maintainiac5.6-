part of 'expense_receipt_entry_screen.dart';

class _ReceiptEntryStartGuide extends StatelessWidget {
  const _ReceiptEntryStartGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF4B6873)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let’s get this receipt ready',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'You stay in control. Check every detail before you save.',
            style: TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          _ReceiptEntryStartGuideStep(
            number: '1',
            title: 'Set the vehicle and date',
          ),
          SizedBox(height: 5),
          _ReceiptEntryStartGuideStep(
            number: '2',
            title: 'Add a receipt photo or enter it by hand',
          ),
          SizedBox(height: 5),
          _ReceiptEntryStartGuideStep(
            number: '3',
            title:
                'Check the filled details, choose Business, Personal, or Mixed, then save',
          ),
        ],
      ),
    );
  }
}

class _ReceiptEntryStartGuideStep extends StatelessWidget {
  const _ReceiptEntryStartGuideStep({
    required this.number,
    required this.title,
  });

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFFFD166),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF1F2528),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
