part of 'receipt_store_panel.dart';

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
