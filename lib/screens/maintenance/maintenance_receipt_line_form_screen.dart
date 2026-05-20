import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/industrial_panel.dart';
import '../../shared/widgets/record_text_field.dart';
import 'maintenance_models.dart';

class MaintenanceReceiptLineFormScreen extends StatefulWidget {
  const MaintenanceReceiptLineFormScreen({required this.item, super.key});

  final MaintenanceCatalogItem item;

  @override
  State<MaintenanceReceiptLineFormScreen> createState() =>
      _MaintenanceReceiptLineFormScreenState();
}

class _MaintenanceReceiptLineFormScreenState
    extends State<MaintenanceReceiptLineFormScreen> {
  final _product = TextEditingController();
  final _detailA = TextEditingController();
  final _detailB = TextEditingController();
  final _units = TextEditingController(text: '1');
  final _containers = TextEditingController(text: '1');
  final _cost = TextEditingController();
  String _measurement = 'Quarts';
  String _oilWeight = '5W-30';

  @override
  void dispose() {
    _product.dispose();
    _detailA.dispose();
    _detailB.dispose();
    _units.dispose();
    _containers.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              IndustrialPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt Line: ${widget.item.name}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RecordTextField(
                      label: 'Product name from receipt',
                      controller: _product,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RecordTextField(
                            label: widget.item.detailA,
                            controller: _detailA,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isEngineOil
                              ? DropdownButtonFormField<String>(
                                  initialValue: _oilWeight,
                                  decoration: InputDecoration(
                                    labelText: widget.item.detailB,
                                  ),
                                  dropdownColor: AppColors.field,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  items: engineOilWeights
                                      .map(
                                        (weight) => DropdownMenuItem(
                                          value: weight,
                                          child: Text(weight),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _oilWeight = value ?? _oilWeight,
                                  ),
                                )
                              : RecordTextField(
                                  label: widget.item.detailB,
                                  controller: _detailB,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _measurement,
                            decoration: const InputDecoration(
                              labelText: 'Measurement',
                            ),
                            dropdownColor: AppColors.field,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                            items:
                                const [
                                      'Quarts',
                                      'Gallons',
                                      'Liters',
                                      'Each',
                                      'Set',
                                      'Pack',
                                    ]
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) => setState(
                              () => _measurement = value ?? _measurement,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RecordTextField(
                            label: 'Unit cost',
                            controller: _cost,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RecordTextField(
                            label: 'Units per container',
                            controller: _units,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RecordTextField(
                            label: 'Containers bought',
                            controller: _containers,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Recap(
                      units: double.tryParse(_units.text) ?? 0,
                      containers: double.tryParse(_containers.text) ?? 0,
                      cost: double.tryParse(_cost.text) ?? 0,
                      measurement: _measurement,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        label: 'Save And Continue',
                        tone: AppButtonTone.commit,
                        compact: true,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    Navigator.pop(
      context,
      ReceiptLineEntry(
        itemName: widget.item.name,
        productName: _product.text.trim(),
        detailA: _detailA.text.trim(),
        detailB: _isEngineOil ? _oilWeight : _detailB.text.trim(),
        measurement: _measurement,
        unitsPerContainer: double.tryParse(_units.text) ?? 0,
        containerCount: double.tryParse(_containers.text) ?? 0,
        unitCost: double.tryParse(_cost.text) ?? 0,
      ),
    );
  }

  bool get _isEngineOil => widget.item.name.toLowerCase() == 'engine oil';
}

class _Recap extends StatelessWidget {
  const _Recap({
    required this.units,
    required this.containers,
    required this.cost,
    required this.measurement,
  });

  final double units;
  final double containers;
  final double cost;
  final String measurement;

  @override
  Widget build(BuildContext context) {
    final totalUnits = units * containers;
    final totalCost = cost * containers;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Total: ${totalUnits.toStringAsFixed(2)} $measurement • \$${totalCost.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
