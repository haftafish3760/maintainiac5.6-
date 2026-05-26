import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'record_form_fields.dart';

class SharedReceiptDateTimePanel extends StatelessWidget {
  const SharedReceiptDateTimePanel({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onClearTime,
  });

  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final VoidCallback onClearTime;

  @override
  Widget build(BuildContext context) {
    return RecordFormPanel(
      children: [
        const RecordSectionTitle('Receipt Date And Time'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ReceiptContextButton(
                label: 'Date',
                value: _formatDate(selectedDate),
                requiredText: 'Required',
                icon: Icons.calendar_month_rounded,
                onTap: onSelectDate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptContextButton(
                label: 'Time',
                value: selectedTime == null
                    ? 'No time'
                    : selectedTime!.format(context),
                requiredText: 'Optional',
                icon: Icons.schedule_rounded,
                trailing: selectedTime == null
                    ? null
                    : IconButton(
                        onPressed: onClearTime,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF101416),
                          size: 18,
                        ),
                        tooltip: 'Clear time',
                      ),
                onTap: onSelectTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class SharedReceiptAttachmentPanel extends StatelessWidget {
  const SharedReceiptAttachmentPanel({
    super.key,
    required this.hasReceipt,
    required this.onChanged,
  });

  final bool hasReceipt;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return RecordFormPanel(
      children: [
        const RecordSectionTitle('Receipt'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ReceiptButton(
                icon: Icons.photo_camera_rounded,
                label: 'Camera',
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptButton(
                icon: Icons.image_rounded,
                label: 'Photo',
                onTap: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
        if (hasReceipt) ...[
          const SizedBox(height: 10),
          Container(
            height: 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF151C20), Color(0xFF080B0D)],
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF66737A)),
            ),
            child: const Text(
              'Receipt preview ready - retake or continue',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => onChanged(false),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Retake / Replace'),
          ),
        ],
      ],
    );
  }
}

class _ReceiptContextButton extends StatelessWidget {
  const _ReceiptContextButton({
    required this.label,
    required this.value,
    required this.requiredText,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final String requiredText;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFAAB4B9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF101416), width: .8),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF101416), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: _style(12, FontWeight.w900)),
                    Text(requiredText, style: _style(10, FontWeight.w700)),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style(13, FontWeight.w800),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF101416),
                    size: 19,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _style(double size, FontWeight weight) {
    return TextStyle(
      color: const Color(0xFF101416),
      fontSize: size,
      fontWeight: weight,
    );
  }
}

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

    return RecordFormPanel(
      children: [
        const RecordSectionTitle('Store Information'),
        const SizedBox(height: 10),
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
          await showGeneralDialog<bool>(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Store Information',
            barrierColor: Colors.black.withValues(alpha: .68),
            transitionDuration: const Duration(milliseconds: 260),
            pageBuilder: (context, animation, secondaryAnimation) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 18,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Dialog(
                          insetPadding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFF1F2528),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Color(0xFF66737A)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                const Text(
                                  'Store Information',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFE8ECEE),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                RecordTextField(
                                  label: 'Store Name',
                                  helperText: 'Required',
                                  controller: draftStore,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 10),
                                RecordTextField(
                                  label: 'Street Address',
                                  hintText: '192 Main Street',
                                  controller: draftStreet,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 10),
                                RecordTextField(
                                  label: 'City',
                                  controller: draftCity,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: RecordDropdownField<String>(
                                        label: 'State',
                                        value: draftState.text,
                                        items: _usStates,
                                        itemLabel: _stateLabel,
                                        onChanged: (value) => setDialogState(
                                          () => draftState.text = value,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: RecordTextField(
                                        label: 'ZIP Code',
                                        controller: draftZip,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
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
                                  controller: draftPhone,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _UsPhoneNumberFormatter(),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                RecordTextField(
                                  label: 'Email',
                                  controller: draftEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 10),
                                RecordTextField(
                                  label: 'Website',
                                  controller: draftWebsite,
                                  keyboardType: TextInputType.url,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 10),
                                RecordTextField(
                                  label: 'Store Notes',
                                  controller: draftNotes,
                                  textInputAction: TextInputAction.newline,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFE8ECEE,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF8F9BA1),
                                            width: 1.2,
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            48,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () {
                                          if (draftStore.text.trim().isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Store name is required.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          Navigator.of(context).pop(true);
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF28A745,
                                          ),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size.fromHeight(
                                            48,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
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
                    ),
                  );
                },
              );
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              final curve = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curve,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .96, end: 1).animate(curve),
                  child: child,
                ),
              );
            },
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

class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: FittedBox(child: Text(label)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1976B9),
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
