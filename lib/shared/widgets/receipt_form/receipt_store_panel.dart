import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../record_form_fields.dart';
import 'receipt_form_panel.dart';

part 'receipt_store_panel_sheet.dart';
part 'receipt_store_panel_support.dart';

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
