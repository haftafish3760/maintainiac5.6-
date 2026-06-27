part of 'work_supply_add_items_screen.dart';

class _AddHeader extends StatelessWidget {
  const _AddHeader({required this.receiptInfoComplete});

  final bool receiptInfoComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          receiptInfoComplete ? 'Add Receipt Items' : 'Receipt Information',
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          receiptInfoComplete
              ? 'Add each receipt line as inventory or as an additional business, personal, or mixed-use item.'
              : 'Start with the receipt date, proof, and store. Then continue to review or add the receipt items.',
          style: const TextStyle(
            color: Color(0xFFC7D0D4),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  const _ReceiptSection({
    required this.selectedDate,
    required this.selectedTime,
    required this.hasReceipt,
    required this.showCamera,
    required this.store,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.email,
    required this.website,
    required this.storeNotes,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onClearTime,
    required this.onReceiptChanged,
    required this.onImportedText,
    required this.onStoreChanged,
  });

  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final bool hasReceipt;
  final bool showCamera;
  final TextEditingController store;
  final TextEditingController phone;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController zip;
  final TextEditingController email;
  final TextEditingController website;
  final TextEditingController storeNotes;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final VoidCallback onClearTime;
  final ValueChanged<bool> onReceiptChanged;
  final ValueChanged<String> onImportedText;
  final VoidCallback onStoreChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharedReceiptDateTimePanel(
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          onSelectDate: onSelectDate,
          onSelectTime: onSelectTime,
          onClearTime: onClearTime,
        ),
        const SizedBox(height: 12),
        SharedReceiptAttachmentPanel(
          hasReceipt: hasReceipt,
          showCamera: showCamera,
          area: ReceiptCaptureArea.materialsInventory,
          onChanged: onReceiptChanged,
          onImportedText: onImportedText,
        ),
        const SizedBox(height: 12),
        SharedReceiptStorePanel(
          store: store,
          phone: phone,
          street: street,
          city: city,
          state: state,
          zip: zip,
          email: email,
          website: website,
          notes: storeNotes,
          onChanged: onStoreChanged,
        ),
      ],
    );
  }
}

class _BorderPanel extends StatelessWidget {
  const _BorderPanel({
    required this.label,
    required this.child,
    this.surfaceColor = const Color(0xFF162229),
    this.borderColor = const Color(0xFF67747A),
    this.labelColor = const Color(0xFFD3DBDE),
  });

  final String label;
  final Widget child;
  final Color surfaceColor;
  final Color borderColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderColor, width: 1.25),
          ),
          child: child,
        ),
        Positioned(
          left: 12,
          top: -8,
          child: StructuralBorderLabel(
            label: label,
            alignment: Alignment.centerLeft,
            maxWidthFactor: 0.72,
            backgroundColor: labelColor,
            textColor: const Color(0xFF101416),
          ),
        ),
      ],
    );
  }
}
