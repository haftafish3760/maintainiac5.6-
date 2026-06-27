import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../record_form_fields.dart';
import 'receipt_form_panel.dart';

class SharedReceiptStorePanel extends StatefulWidget {
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
  State<SharedReceiptStorePanel> createState() =>
      _SharedReceiptStorePanelState();
}

class _SharedReceiptStorePanelState extends State<SharedReceiptStorePanel> {
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final hasStore = widget.store.text.trim().isNotEmpty;
    final cityLine = [
      widget.city.text.trim(),
      widget.state.text.trim(),
      widget.zip.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final location = [
      widget.street.text.trim(),
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
          onTap: _sheetOpen ? null : () => _openStoreForm(context),
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
                        hasStore ? widget.store.text.trim() : 'Store Info',
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
    if (_sheetOpen) return;
    setState(() => _sheetOpen = true);

    try {
      final draft = await showModalBottomSheet<_StoreInformationDraft>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _StoreInformationSheet(
          initial: _StoreInformationDraft(
            store: widget.store.text,
            phone: widget.phone.text,
            street: widget.street.text,
            city: widget.city.text,
            state: _stateValue(widget.state.text),
            zip: widget.zip.text,
            email: widget.email.text,
            website: widget.website.text,
            notes: widget.notes.text,
          ),
        ),
      );

      if (draft == null || !context.mounted) return;
      widget.store.text = draft.store;
      widget.phone.text = draft.phone;
      widget.street.text = draft.street;
      widget.city.text = draft.city;
      widget.state.text = draft.state;
      widget.zip.text = draft.zip;
      widget.email.text = draft.email;
      widget.website.text = draft.website;
      widget.notes.text = draft.notes;
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
  }

  String _stateValue(String value) {
    final trimmed = value.trim().toUpperCase();
    return _usStates.contains(trimmed) ? trimmed : '';
  }
}

class _StoreInformationSheet extends StatefulWidget {
  const _StoreInformationSheet({required this.initial});

  final _StoreInformationDraft initial;

  @override
  State<_StoreInformationSheet> createState() => _StoreInformationSheetState();
}

class _StoreInformationSheetState extends State<_StoreInformationSheet> {
  late final TextEditingController _store;
  late final TextEditingController _phone;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _store = TextEditingController(text: widget.initial.store);
    _phone = TextEditingController(text: widget.initial.phone);
    _street = TextEditingController(text: widget.initial.street);
    _city = TextEditingController(text: widget.initial.city);
    _state = TextEditingController(text: widget.initial.state);
    _zip = TextEditingController(text: widget.initial.zip);
    _email = TextEditingController(text: widget.initial.email);
    _website = TextEditingController(text: widget.initial.website);
    _notes = TextEditingController(text: widget.initial.notes);
  }

  @override
  void dispose() {
    _store.dispose();
    _phone.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _email.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final heightFactor = bottomInset > 0 ? 0.74 : 0.92;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF1F2528),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(top: BorderSide(color: Color(0xFF66737A))),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                        controller: _store,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      RecordTextField(
                        label: 'Street Address',
                        hintText: '192 Main Street',
                        controller: _street,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      RecordTextField(
                        label: 'City',
                        controller: _city,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: RecordDropdownField<String>(
                              label: 'State',
                              value: _state.text,
                              items: _usStates,
                              itemLabel: _stateLabel,
                              onChanged: (value) =>
                                  setState(() => _state.text = value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: RecordTextField(
                              label: 'ZIP Code',
                              controller: _zip,
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
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _UsPhoneNumberFormatter(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      RecordTextField(
                        label: 'Email',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      RecordTextField(
                        label: 'Website',
                        controller: _website,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      RecordTextField(
                        label: 'Store Notes',
                        controller: _notes,
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
                        onPressed: () => Navigator.of(context).pop(),
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
      ),
    );
  }

  void _save() {
    if (_store.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Store name is required.')));
      return;
    }
    Navigator.of(context).pop(
      _StoreInformationDraft(
        store: _store.text.trim(),
        phone: _phone.text.trim(),
        street: _street.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        zip: _zip.text.trim(),
        email: _email.text.trim(),
        website: _website.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
  }

  String _stateLabel(String value) {
    if (value.isEmpty) return 'Select state';
    return value;
  }
}

class _StoreInformationDraft {
  const _StoreInformationDraft({
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

  final String store;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String email;
  final String website;
  final String notes;
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
