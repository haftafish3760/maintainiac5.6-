part of 'invoice_form_details.dart';

Future<void> showInvoiceTotalsSheet(BuildContext context) {
  return _showInvoiceSheet(
    context,
    title: 'Invoice Totals',
    children: const [
      _TotalLine(label: 'Subtotal', value: r'$0.00'),
      _TotalLine(label: 'Discount', value: r'$0.00'),
      _TotalLine(label: 'Tax', value: r'$0.00'),
      Divider(color: Color(0xFF6F7A80)),
      _TotalLine(label: 'Grand Total', value: r'$0.00', emphasized: true),
    ],
  );
}

Future<void> showInvoiceDiscountSheet(BuildContext context) {
  return _showInvoiceSheet(
    context,
    title: 'Discount',
    children: const [
      RecordTextField(label: 'Discount Amount'),
      SizedBox(height: 10),
      RecordTextField(label: 'Discount Percent'),
      SizedBox(height: 12),
      _TotalLine(label: 'Invoice Discount', value: r'$0.00'),
    ],
  );
}

Future<void> showInvoiceTaxSheet(BuildContext context) {
  return _showInvoiceSheet(
    context,
    title: 'Tax',
    children: const [
      RecordTextField(label: 'Tax Rate'),
      SizedBox(height: 10),
      _TotalLine(label: 'Taxable Subtotal', value: r'$0.00'),
      _TotalLine(label: 'Estimated Tax', value: r'$0.00'),
    ],
  );
}

Future<String?> showInvoicePaymentMethodSheet(
  BuildContext context,
  String current,
) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: const Color(0xFF20292D),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetTitle('Payment Method'),
          for (final method in _paymentMethods)
            ListTile(
              title: Text(method),
              trailing: method == current
                  ? const Icon(Icons.check_rounded, color: Color(0xFF6BE58D))
                  : null,
              onTap: () => Navigator.of(context).pop(method),
            ),
        ],
      ),
    ),
  );
}

Future<AppSignatureResult?> showInvoiceSignatureSheet(
  BuildContext context, {
  AppSignatureResult? savedOwnerSignature,
}) async {
  final action = await showModalBottomSheet<_SignatureSheetAction>(
    context: context,
    showDragHandle: true,
    backgroundColor: const Color(0xFF20292D),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: RecordFormPanel(
            children: [
              const _SheetTitle('Signature'),
              const SizedBox(height: 10),
              const Text(
                'Your signature can be saved locally. Customer signatures are only saved to this document and must be collected again if totals or line items change.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (savedOwnerSignature?.hasInk == true) ...[
                _SignatureActionTile(
                  title: 'Use Saved My Signature',
                  detail: 'Apply your saved local signature to this document.',
                  icon: Icons.verified_rounded,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_SignatureSheetAction.useSavedOwner),
                ),
                const SizedBox(height: 10),
              ],
              _SignatureActionTile(
                title: savedOwnerSignature?.hasInk == true
                    ? 'Update My Saved Signature'
                    : 'Add My Signature',
                detail: 'Use your finger or stylus. This saves locally only.',
                icon: Icons.edit_rounded,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_SignatureSheetAction.captureOwner),
              ),
              const SizedBox(height: 10),
              _SignatureActionTile(
                title: 'Add Customer Signature',
                detail:
                    'Fresh signature for this document only. Never reusable.',
                icon: Icons.assignment_turned_in_rounded,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_SignatureSheetAction.captureCustomer),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) return null;
  if (action == _SignatureSheetAction.useSavedOwner) {
    return savedOwnerSignature;
  }
  final role = action == _SignatureSheetAction.captureOwner
      ? AppSignatureRole.owner
      : AppSignatureRole.customer;
  final title = role == AppSignatureRole.owner
      ? 'Add My Signature'
      : 'Add Customer Signature';
  return showModalBottomSheet<AppSignatureResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF20292D),
    builder: (context) => AppSignatureCaptureSheet(role: role, title: title),
  );
}

enum _SignatureSheetAction { useSavedOwner, captureOwner, captureCustomer }

Future<void> showInvoiceTermsSheet(BuildContext context) {
  return _showInvoiceSheet(
    context,
    title: 'Terms And Conditions',
    children: const [
      RecordTextField(
        label: 'Terms',
        hintText: 'Payment due at time of service, 7 days, 30 days...',
      ),
    ],
  );
}

Future<String?> showInvoiceStatusSheet(BuildContext context, String current) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    backgroundColor: const Color(0xFF20292D),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetTitle('Mark Invoice As'),
          for (final status in const ['Unpaid', 'Partly Paid', 'Paid'])
            ListTile(
              title: Text(status),
              trailing: status == current
                  ? const Icon(Icons.check_rounded, color: Color(0xFF6BE58D))
                  : null,
              onTap: () => Navigator.of(context).pop(status),
            ),
        ],
      ),
    ),
  );
}

Future<void> _showInvoiceSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF20292D),
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: RecordFormPanel(
          children: [
            _SheetTitle(title),
            const SizedBox(height: 12),
            ...children,
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasized ? 16 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasized ? const Color(0xFF6BE58D) : null,
              fontSize: emphasized ? 18 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );
  }
}

class _SignatureActionTile extends StatelessWidget {
  const _SignatureActionTile({
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFAAB4B9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF101416), width: .8),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF101416), size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF101416),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF101416),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF101416)),
            ],
          ),
        ),
      ),
    );
  }
}

const _paymentMethods = [
  'Cash',
  'Card',
  'Credit',
  'Debit',
  'Check',
  'Transfer',
];
