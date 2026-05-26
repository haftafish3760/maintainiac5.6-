import 'package:flutter/material.dart';
import '../../shared/state/app_state.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../../shared/widgets/record_form_fields.dart';
import '../../shared/widgets/receipt_form_sections.dart';

part 'expense_category_details.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key, required this.category});

  final String category;

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _storeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _storeNotesController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _itemController = TextEditingController();
  final _detailController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  var _hasReceipt = false;
  var _fuelType = 'Gas';
  var _destination = 'Vehicle tank';
  var _fillType = 'Full tank';
  var _payment = 'Card';

  @override
  void dispose() {
    _storeController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _storeNotesController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _itemController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
          children: [
            AppScreenHeader(title: '${widget.category} Expense'),
            const SizedBox(height: 10),
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 10),
            _RequiredContextPanel(category: widget.category),
            const SizedBox(height: 10),
            const _VehicleContextPanel(),
            const SizedBox(height: 10),
            SharedReceiptDateTimePanel(
              selectedDate: _selectedDate,
              selectedTime: _selectedTime,
              onSelectDate: _selectDate,
              onSelectTime: _selectTime,
              onClearTime: () => setState(() => _selectedTime = null),
            ),
            const SizedBox(height: 10),
            SharedReceiptAttachmentPanel(
              hasReceipt: _hasReceipt,
              onChanged: (value) => setState(() => _hasReceipt = value),
            ),
            const SizedBox(height: 10),
            SharedReceiptStorePanel(
              store: _storeController,
              phone: _phoneController,
              street: _streetController,
              city: _cityController,
              state: _stateController,
              zip: _zipController,
              email: _emailController,
              website: _websiteController,
              notes: _storeNotesController,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            _CategoryDetailsPanel(
              category: widget.category,
              amountController: _amountController,
              quantityController: _quantityController,
              unitPriceController: _unitPriceController,
              itemController: _itemController,
              detailController: _detailController,
              fuelType: _fuelType,
              destination: _destination,
              fillType: _fillType,
              payment: _payment,
              onFuelTypeChanged: (value) => setState(() => _fuelType = value),
              onDestinationChanged: (value) =>
                  setState(() => _destination = value),
              onFillTypeChanged: (value) => setState(() => _fillType = value),
              onPaymentChanged: (value) => setState(() => _payment = value),
            ),
            const SizedBox(height: 10),
            RecordFormPanel(
              children: [
                RecordTextField(
                  label: 'Notes Optional',
                  controller: _notesController,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save Expense Draft'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD166),
            surface: Color(0xFF1F2528),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD166),
            surface: Color(0xFF1F2528),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
  }
}

class _RequiredContextPanel extends StatelessWidget {
  const _RequiredContextPanel({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return RecordFormPanel(
      children: [
        Text(
          category,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _VehicleContextPanel extends StatelessWidget {
  const _VehicleContextPanel();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final vehicle = state.activeVehicle;
    return RecordFormPanel(
      children: [
        Text(
          vehicle?.displayName ?? 'No vehicle selected',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
