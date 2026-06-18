part of 'work_supply_add_items_screen.dart';

class _ManualInventoryRequiredPanel extends StatelessWidget {
  const _ManualInventoryRequiredPanel({
    required this.name,
    required this.description,
    required this.generatedName,
    required this.typedSuggestion,
    required this.suggestions,
    required this.onChanged,
    required this.onApplyTypedSuggestion,
    required this.onApplyCatalogSuggestion,
  });

  final TextEditingController name;
  final TextEditingController description;
  final String generatedName;
  final WorkSupplyItem? typedSuggestion;
  final List<WorkSupplyItem> suggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback onApplyTypedSuggestion;
  final ValueChanged<WorkSupplyItem> onApplyCatalogSuggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
      decoration: BoxDecoration(
        color: const Color(0xFF102A3A),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF63B3E6), width: 1.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFFA9DFFF), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Required item details',
                  style: TextStyle(
                    color: Color(0xFFF0F7FA),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _Field(
            controller: name,
            label: 'Search or item name',
            hint: generatedName.isEmpty
                ? 'Example: 1/2 in copper 90, zip ties, PVC cement'
                : generatedName,
            onChanged: onChanged,
          ),
          if (suggestions.isNotEmpty) ...[
            _TypedCatalogSuggestionList(
              suggestions: suggestions,
              typedSuggestion: typedSuggestion,
              onApplyTypedSuggestion: onApplyTypedSuggestion,
              onApply: onApplyCatalogSuggestion,
            ),
            const SizedBox(height: 8),
          ] else if (typedSuggestion != null) ...[
            _TypedCatalogSuggestionList(
              suggestions: [typedSuggestion!],
              typedSuggestion: typedSuggestion,
              onApplyTypedSuggestion: onApplyTypedSuggestion,
              onApply: onApplyCatalogSuggestion,
            ),
            const SizedBox(height: 8),
          ],
          _Field(
            controller: description,
            label: 'Receipt wording',
            hint: 'Optional: type the receipt abbreviation or store wording',
            onChanged: onChanged,
          ),
          const Text(
            'Start typing the common field name. The app will suggest a matching inventory item when it recognizes one.',
            style: TextStyle(
              color: Color(0xFFD2E2EA),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
