import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../record_form_fields.dart';
import 'receipt_form_panel.dart';

class SharedReceiptStorePanel extends StatelessWidget {
  const SharedReceiptStorePanel({
    super.key,
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
    final hasStore = store.text.trim().isNotEmpty;
    final cityLine = [
      city.text.trim(),
      state.text.trim(),
      zip.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final location = [
      street.text.trim(),
      cityLine,
    ].where((part) => part.isNotEmpty).join(', ');

    return ReceiptFormPanel(
      title: 'Store Information',
      subtitle:
          'Store name is required. Contact and address details can be added when available.',
      icon: Icons.storefront_rounded,
      accentColor: const Color(0xFF79C8FF),
      children: [
        InkWell(
          onTap: () => _openStoreForm(context),
          borderRadius: BorderRadius.circular(5),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1976B9), Color(0xFF0F4068)],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF79C8FF), width: 1.1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, color: Color(0xFFFFD166)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasStore ? store.text.trim() : 'Store Info',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasStore
                            ? (location.isEmpty
                                  ? 'Address not entered'
                                  : location)
                            : 'Name, street, city, state, ZIP, phone, web',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD4DDE1),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openStoreForm(BuildContext context) async {
    final draftStore = TextEditingController(text: store.text);
    final draftPhone = TextEditingController(text: phone.text);
    final draftStreet = TextEditingController(text: street.text);
    final draftCity = TextEditingController(text: city.text);
    final draftState = TextEditingController(text: _stateValue(state.text));
    final draftZip = TextEditingController(text: zip.text);
    final draftEmail = TextEditingController(text: email.text);
    final draftWebsite = TextEditingController(text: website.text);
    final draftNotes = TextEditingController(text: notes.text);
    var saved = false;

    try {
      saved =
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _StoreInformationSheet(
              store: draftStore,
              phone: draftPhone,
              street: draftStreet,
              city: draftCity,
              state: draftState,
              zip: draftZip,
              email: draftEmail,
              website: draftWebsite,
              notes: draftNotes,
            ),
          ) ??
          false;

      if (!saved) return;
      store.text = draftStore.text.trim();
      phone.text = draftPhone.text.trim();
      street.text = draftStreet.text.trim();
      city.text = draftCity.text.trim();
      state.text = draftState.text.trim();
      zip.text = draftZip.text.trim();
      email.text = draftEmail.text.trim();
      website.text = draftWebsite.text.trim();
      notes.text = draftNotes.text.trim();
      onChanged();
    } finally {
      draftStore.dispose();
      draftPhone.dispose();
      draftStreet.dispose();
      draftCity.dispose();
      draftState.dispose();
      draftZip.dispose();
      draftEmail.dispose();
      draftWebsite.dispose();
      draftNotes.dispose();
    }
  }

  String _stateValue(String value) {
    final trimmed = value.trim().toUpperCase();
    return _usStates.contains(trimmed) ? trimmed : '';
  }
}

class _StoreInformationSheet extends StatefulWidget {
  const _StoreInformationSheet({
    required this.store,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.email,
    required this.website,
    required this.notes,
  });

  final TextEditingController store;
  final TextEditingController phone;
  final TextEditingController street;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController zip;
  final TextEditingController email;
  final TextEditingController website;
  final TextEditingController notes;

  @override
  State<_StoreInformationSheet> createState() => _StoreInformationSheetState();
}

class _StoreInformationSheetState extends State<_StoreInformationSheet> {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF1F2528),
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          border: Border(top: BorderSide(color: Color(0xFF66737A))),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F9BA1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Store Information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Store name is required. Everything else is optional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFD4DDE1),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    RecordTextField(
                      label: 'Store Name',
                      helperText: 'Required',
                      controller: widget.store,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Street Address',
                      hintText: '192 Main Street',
                      controller: widget.street,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'City',
                      controller: widget.city,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: RecordDropdownField<String>(
                            label: 'State',
                            value: widget.state.text,
                            items: _usStates,
                            itemLabel: _stateLabel,
                            onChanged: (value) =>
                                setState(() => widget.state.text = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: RecordTextField(
                            label: 'ZIP Code',
                            controller: widget.zip,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Phone',
                      hintText: '(555) 123-4567',
                      controller: widget.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _UsPhoneNumberFormatter(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Email',
                      controller: widget.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Website',
                      controller: widget.website,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Store Notes',
                      controller: widget.notes,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE8ECEE),
                        side: const BorderSide(
                          color: Color(0xFF8F9BA1),
                          width: 1.2,
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text('Save And Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (widget.store.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Store name is required.')));
      return;
    }
    Navigator.of(context).pop(true);
  }

  String _stateLabel(String value) {
    if (value.isEmpty) return 'Select state';
    return value;
  }
}

const _usStates = <String>[
  '',
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'DC',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY',
];

class _UsPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 10 ? digits.substring(0, 10) : digits;
    final formatted = _format(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length <= 3) return '(${digits.padRight(0)}';
    if (digits.length <= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    }
    return '(${digits.substring(0, 3)}) '
        '${digits.substring(3, 6)}-${digits.substring(6)}';
  }
}
