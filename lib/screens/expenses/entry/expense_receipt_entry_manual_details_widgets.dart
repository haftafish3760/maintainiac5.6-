part of 'expense_receipt_entry_screen.dart';

class _ManualReceiptOdometerAction extends StatelessWidget {
  const _ManualReceiptOdometerAction({
    required this.reading,
    required this.onPressed,
  });

  final int? reading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasReading = reading != null;
    return _ManualReceiptActionTile(
      icon: Icons.speed_rounded,
      label: 'Odometer',
      value: hasReading
          ? 'Current odometer: $reading mi'
          : 'Enter your current odometer to add it to the receipt.',
      actionLabel: hasReading ? 'Edit' : 'Enter',
      onTap: onPressed,
      color: const Color(0xFF8FC9FF),
    );
  }
}

class _ManualReceiptStoreBinding extends StatelessWidget {
  const _ManualReceiptStoreBinding({
    required this.controller,
    required this.store,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.email,
    required this.website,
    required this.notes,
    required this.onChanged,
  });

  final SharedReceiptStorePanelController controller;
  final TextEditingController store;
  final TextEditingController phone;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController zip;
  final TextEditingController email;
  final TextEditingController website;
  final TextEditingController notes;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      child: SharedReceiptStorePanel(
        controller: controller,
        store: store,
        phone: phone,
        street: street,
        city: city,
        state: state,
        zip: zip,
        email: email,
        website: website,
        notes: notes,
        onChanged: onChanged,
      ),
    );
  }
}
