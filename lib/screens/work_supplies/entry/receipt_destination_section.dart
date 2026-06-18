part of 'work_supply_add_items_screen.dart';

const _chooseInventoryDestinationLabel = 'Choose destination';

class _InventoryDestinationPicker extends StatelessWidget {
  const _InventoryDestinationPicker({
    required this.selected,
    required this.customDestination,
    required this.storageDetail,
    required this.choices,
    required this.onSelected,
    required this.onChanged,
    required this.onStorageDetailChanged,
    required this.onAddVehicle,
  });

  final String selected;
  final TextEditingController customDestination;
  final TextEditingController storageDetail;
  final List<String> choices;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onStorageDetailChanged;
  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (selected == _chooseInventoryDestinationLabel)
        _chooseInventoryDestinationLabel,
      ...choices,
    ];
    final needsSelection = selected == _chooseInventoryDestinationLabel;
    final destinationName = _destinationNameForCopy(selected);
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 3),
      decoration: BoxDecoration(
        color: const Color(0xFF102A3A),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: needsSelection
              ? const Color(0xFFFFC46B)
              : const Color(0xFF63B3E6),
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: needsSelection
                    ? const Color(0xFFFFC46B)
                    : const Color(0xFFA9DFFF),
                size: 23,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose the inventory destination',
                      style: const TextStyle(
                        color: Color(0xFFF2F6EF),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Select where this item belongs before it is added to inventory.',
                      style: const TextStyle(
                        color: Color(0xFFD2E2EA),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DropdownField<String>(
            label: 'Assign this line to',
            value: selected,
            items: items,
            itemLabel: (value) => value,
            onChanged: onSelected,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Vehicle'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA9DFFF),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (selected == workSupplyCustomDestinationLabel) ...[
            const SizedBox(height: 8),
            _Field(
              controller: customDestination,
              label: 'Custom destination',
              hint: 'Shop shelf, trailer, job staging, or vehicle label',
              onChanged: onChanged,
            ),
          ],
          const SizedBox(height: 8),
          _Field(
            controller: storageDetail,
            label: 'Specific place on $destinationName',
            hint: 'Optional: drawer 2, shelf A, left bin, top tray',
            onChanged: onStorageDetailChanged,
          ),
        ],
      ),
    );
  }

  String _destinationNameForCopy(String value) {
    if (value == _chooseInventoryDestinationLabel) return 'this destination';
    if (value == workSupplyCustomDestinationLabel) return 'this location';
    return value
            .replaceAll(RegExp(r'\s+inventory$', caseSensitive: false), '')
            .trim()
            .isEmpty
        ? 'this destination'
        : value
              .replaceAll(RegExp(r'\s+inventory$', caseSensitive: false), '')
              .trim();
  }
}
