import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/industrial_panel_surface.dart';
import '../../../shared/widgets/receipt_capture/receipt_capture_settings_store.dart';

/// Full-screen first-use setup for the Expense receipt experience.
///
/// It deliberately collects only the choice needed to start using Expenses.
/// Camera controls, storage choices, and account consent remain in their own
/// places so a new customer is not buried in a long setup questionnaire.
class ExpenseReceiptAssistanceSetupScreen extends StatefulWidget {
  const ExpenseReceiptAssistanceSetupScreen({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  State<ExpenseReceiptAssistanceSetupScreen> createState() =>
      _ExpenseReceiptAssistanceSetupScreenState();
}

class _ExpenseReceiptAssistanceSetupScreenState
    extends State<ExpenseReceiptAssistanceSetupScreen> {
  ExpenseReceiptAssistanceChoice? _entryChoice;
  bool? _wantsReceiptHelp;
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ReceiptCaptureSettingsScope.of(context);
    // A new customer must actively choose.  Opening this screen later from
    // Expense settings starts from the preference they already saved.
    if (_entryChoice == null && settings.hasCompletedExpenseReceiptSetup) {
      _entryChoice = settings.expenseReceiptAssistanceChoice;
      _wantsReceiptHelp = _entryChoice != ExpenseReceiptAssistanceChoice.manual;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFF101719),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF101719),
          foregroundColor: const Color(0xFFE8ECEE),
          elevation: 0,
          leading: widget.showBackButton
              ? IconButton(
                  tooltip: 'Back to Expenses',
                  onPressed: _saving ? null : _handleBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
          title: const Text(
            'Receipt Assistance',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                children: [
                  Text(
                    _wantsReceiptHelp == true
                        ? 'Choose receipt help'
                        : 'Would you like help with your receipts?',
                    style: const TextStyle(
                      color: Color(0xFFF0F4F2),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _wantsReceiptHelp == true
                        ? 'Choose how Maintainiac should help. You review and can edit every receipt before saving.'
                        : 'Maintainiac can help fill in a receipt from a photo, PDF, or text. You stay in control and review every receipt before saving.',
                    style: const TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._currentChoices(),
                  const SizedBox(height: 18),
                  _PrivacyReminder(
                    assisted:
                        _entryChoice != null &&
                        _entryChoice != ExpenseReceiptAssistanceChoice.manual,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving || _entryChoice == null
                        ? null
                        : _continue,
                    icon: Icon(
                      _entryChoice == ExpenseReceiptAssistanceChoice.manual
                          ? Icons.check_circle_outline_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(
                      _entryChoice == ExpenseReceiptAssistanceChoice.manual
                          ? 'Save Manual Entry'
                          : 'Save Receipt Assistance',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: const Color(0xFF249D62),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _currentChoices() {
    if (_wantsReceiptHelp == true) return _assistanceChoices();
    return [
      _SetupChoiceCard(
        selected: _wantsReceiptHelp == true,
        icon: Icons.auto_awesome_rounded,
        title: 'Yes, help me',
        detail:
            'Let Maintainiac help fill in receipt details. You can review and correct everything before it is saved.',
        accent: const Color(0xFF8EF6A4),
        onTap: () => setState(() {
          _wantsReceiptHelp = true;
          _entryChoice = null;
        }),
      ),
      const SizedBox(height: 12),
      _SetupChoiceCard(
        selected: _entryChoice == ExpenseReceiptAssistanceChoice.manual,
        icon: Icons.edit_note_rounded,
        title: 'No, I will enter receipts myself',
        detail:
            'Start with a clean receipt form. You can still attach a receipt image whenever you want.',
        accent: const Color(0xFFFFD166),
        onTap: () => setState(() {
          _wantsReceiptHelp = false;
          _entryChoice = ExpenseReceiptAssistanceChoice.manual;
        }),
      ),
    ];
  }

  void _handleBack() {
    if (_wantsReceiptHelp == true && _entryChoice == null) {
      setState(() => _wantsReceiptHelp = null);
      return;
    }
    Navigator.of(context).pop();
  }

  List<Widget> _assistanceChoices() => [
    _SetupChoiceCard(
      selected: _entryChoice == ExpenseReceiptAssistanceChoice.onDevice,
      icon: Icons.auto_awesome_rounded,
      title: 'Local receipt extraction',
      detail:
          'Read receipt photos and PDFs on this device first. You review and edit every detail before saving.',
      accent: const Color(0xFF8EF6A4),
      onTap: () => setState(
        () => _entryChoice = ExpenseReceiptAssistanceChoice.onDevice,
      ),
    ),
    const SizedBox(height: 12),
    _SetupChoiceCard(
      selected: _entryChoice == ExpenseReceiptAssistanceChoice.chatGptAccount,
      icon: Icons.account_circle_outlined,
      title: 'ChatGPT-assisted receipts',
      detail:
          'Use ChatGPT only when you choose it. A separate connection step and your approval are required before your receipt can be shared.',
      accent: const Color(0xFFD6B7FF),
      onTap: () => setState(
        () => _entryChoice = ExpenseReceiptAssistanceChoice.chatGptAccount,
      ),
    ),
  ];

  Future<void> _continue() async {
    final entryChoice = _entryChoice;
    if (entryChoice == null) return;
    setState(() => _saving = true);
    await ReceiptCaptureSettingsScope.of(
      context,
    ).setExpenseReceiptAssistanceChoice(entryChoice);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}

class ExpenseReceiptAssistanceSettingsPanel extends StatelessWidget {
  const ExpenseReceiptAssistanceSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ReceiptCaptureSettingsScope.of(context);
    final choice = settings.expenseReceiptAssistanceChoice;
    return IndustrialPanelSurface(
      dark: true,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Color(0xFF8EF6A4)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Receipt Assistance',
                  style: TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _choiceSummary(choice),
                  style: const TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              appNativeRoute<bool>(
                context,
                const ExpenseReceiptAssistanceSetupScreen(),
              ),
            ),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Choose flow'),
          ),
        ],
      ),
    );
  }

  String _choiceSummary(ExpenseReceiptAssistanceChoice choice) {
    return switch (choice) {
      ExpenseReceiptAssistanceChoice.manual =>
        'Manual entry is your default. Add a receipt image whenever you want.',
      ExpenseReceiptAssistanceChoice.onDevice =>
        'On-device receipt help is your default. You review every result.',
      ExpenseReceiptAssistanceChoice.maintainiacAi =>
        'On-device help first; ask before using Maintainiac AI.',
      ExpenseReceiptAssistanceChoice.chatGptAccount =>
        'Your ChatGPT preference is saved; connection is requested separately.',
    };
  }
}

class _SetupChoiceCard extends StatelessWidget {
  const _SetupChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.detail,
    required this.accent,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String detail;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1C2A2E) : const Color(0xFF141D20),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : const Color(0xFF4B5B62),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 27),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF0F4F2),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? accent : const Color(0xFF8FA0A8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyReminder extends StatelessWidget {
  const _PrivacyReminder({required this.assisted});

  final bool assisted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF42545D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFF8FC9FF)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                assisted
                    ? 'You stay in control. Maintainiac never saves a receipt or changes a line item without your review.'
                    : 'You can attach a receipt image later even when you enter the details yourself.',
                style: const TextStyle(
                  color: Color(0xFFD4DDE0),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
