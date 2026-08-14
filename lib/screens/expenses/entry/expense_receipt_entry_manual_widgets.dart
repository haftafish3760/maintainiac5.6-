part of 'expense_receipt_entry_screen.dart';

const _receiptReferenceSurface = Color(0xFF0E1112);
const _receiptReferencePage = Color(0xFF2A3337);
const _receiptSetupPanel = Color(0xFF1A2226);
const _receiptSetupPanelBorder = Color(0xFF445159);
const _receiptSetupChoiceSurface = Color(0xFF101719);
const _receiptReferenceBorder = Color(0xFF3D474D);
const _receiptReferenceText = Color(0xFFF5F7F8);
const _receiptReferenceMuted = Color(0xFFADB5BA);
const _receiptReferenceOrange = Color(0xFFFF7D00);
const _receiptReferenceBlue = Color(0xFF2E78B7);
const _receiptReferenceGreen = Color(0xFF2B9947);

class _ReceiptSetupSection extends StatelessWidget {
  const _ReceiptSetupSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _receiptSetupPanel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _receiptSetupPanelBorder, width: 1.25),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Padding(padding: const EdgeInsets.all(10), child: child),
  );
}

class _ReferenceReceiptAppBar extends StatelessWidget {
  const _ReferenceReceiptAppBar({
    required this.title,
    required this.entryModeLabel,
    required this.onBack,
    required this.onSettings,
  });

  final String title;
  final String entryModeLabel;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            color: _receiptReferenceText,
            iconSize: 30,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _receiptReferenceText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  entryModeLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _receiptReferenceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSettings,
            tooltip: 'Receipt settings',
            icon: const Icon(Icons.settings_rounded),
            color: _receiptReferenceText,
            iconSize: 28,
          ),
        ],
      ),
    );
  }
}

class _ReferenceReceiptContextRow extends StatelessWidget {
  const _ReferenceReceiptContextRow({
    required this.vehicleLabel,
    required this.workProfileLabel,
    required this.onVehicleTap,
    required this.onWorkProfileTap,
  });

  final String vehicleLabel;
  final String workProfileLabel;
  final VoidCallback onVehicleTap;
  final VoidCallback onWorkProfileTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ReferenceContextButton(
          label: 'VEHICLE',
          value: vehicleLabel,
          icon: Icons.directions_car_filled_outlined,
          onTap: onVehicleTap,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ReferenceContextButton(
          label: 'WORK PROFILE',
          value: workProfileLabel,
          icon: Icons.person_outline_rounded,
          onTap: onWorkProfileTap,
        ),
      ),
    ],
  );
}

class _ReferenceContextButton extends StatelessWidget {
  const _ReferenceContextButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 82,
        padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
        decoration: BoxDecoration(
          color: _receiptReferenceSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _receiptReferenceBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: _receiptReferenceText, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _receiptReferenceMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        color: _receiptReferenceText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _receiptReferenceMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReferenceReceiptTotalField extends StatelessWidget {
  const _ReferenceReceiptTotalField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECEIPT TOTAL (REQUIRED)',
          style: TextStyle(
            color: _receiptReferenceMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 108,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: const Color(0xFF241416),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF9D4141), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: _receiptReferenceOrange,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: _receiptReferenceOrange,
                    fontSize: 43,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    prefixText: r'$ ',
                    prefixStyle: TextStyle(
                      color: _receiptReferenceOrange,
                      fontSize: 43,
                      fontWeight: FontWeight.w800,
                    ),
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Color(0xFFFFB46B)),
                    filled: true,
                    fillColor: Color(0xFF161012),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Icon(
                Icons.calculate_outlined,
                color: _receiptReferenceMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReferenceReceiptSelectionContext extends StatelessWidget {
  const _ReferenceReceiptSelectionContext({
    required this.classification,
    required this.category,
  });

  final String classification;
  final String category;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF111719),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _receiptReferenceBorder),
    ),
    child: Row(
      children: [
        Expanded(
          child: _ReceiptSelectionContextValue(
            label: 'RECEIPT CLASSIFICATION',
            value: classification,
            valueColor: _receiptReferenceOrange,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 52, color: _receiptReferenceBorder),
        const SizedBox(width: 8),
        Expanded(
          child: _ReceiptSelectionContextValue(
            label: 'RECEIPT CATEGORY',
            value: category,
            valueColor: const Color(0xFF72B8FF),
          ),
        ),
      ],
    ),
  );
}

class _ReceiptSelectionContextValue extends StatelessWidget {
  const _ReceiptSelectionContextValue({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _receiptReferenceText,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: valueColor,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _ReferenceReceiptClassificationRow extends StatelessWidget {
  const _ReferenceReceiptClassificationRow({
    required this.selected,
    required this.onChanged,
  });

  final _ExpenseLineUse? selected;
  final ValueChanged<_ExpenseLineUse> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <Widget>[
      _ReferenceReceiptClassificationButton(
        label: 'Business',
        icon: Icons.business_center_outlined,
        selected: selected == _ExpenseLineUse.business,
        onTap: () => onChanged(_ExpenseLineUse.business),
      ),
      _ReferenceReceiptClassificationButton(
        label: 'Personal',
        icon: Icons.person_outline_rounded,
        selected: selected == _ExpenseLineUse.personal,
        onTap: () => onChanged(_ExpenseLineUse.personal),
      ),
      _ReferenceReceiptClassificationButton(
        label: 'Split',
        icon: Icons.call_split_rounded,
        selected: selected == _ExpenseLineUse.split,
        onTap: () => onChanged(_ExpenseLineUse.split),
      ),
      _ReferenceReceiptClassificationButton(
        label: 'Not sure yet',
        icon: Icons.help_outline_rounded,
        selected: selected == _ExpenseLineUse.unclassified,
        onTap: () => onChanged(_ExpenseLineUse.unclassified),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < options.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: options[index]),
                ],
              ],
            ),
          );
        }
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: options[0]),
                  const SizedBox(width: 8),
                  Expanded(child: options[1]),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: options[2]),
                  const SizedBox(width: 8),
                  Expanded(child: options[3]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReceiptCategoryEntryOptions extends StatelessWidget {
  const _ReceiptCategoryEntryOptions({
    required this.selected,
    required this.onChanged,
  });

  final _ReceiptCategoryEntryChoice? selected;
  final ValueChanged<_ReceiptCategoryEntryChoice> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mixed = _ReceiptCategoryEntryOption(
        label: 'Mixed items',
        helper: 'Choose a category for each item.',
        icon: Icons.category_outlined,
        selected: selected == _ReceiptCategoryEntryChoice.mixedItems,
        onTap: () => onChanged(_ReceiptCategoryEntryChoice.mixedItems),
      );
      final undecided = _ReceiptCategoryEntryOption(
        label: 'Not sure yet',
        helper: 'Decide the category later.',
        icon: Icons.help_outline_rounded,
        selected: selected == _ReceiptCategoryEntryChoice.notSureYet,
        onTap: () => onChanged(_ReceiptCategoryEntryChoice.notSureYet),
      );
      final scaledLabelSize = MediaQuery.textScalerOf(context).scale(15);
      if (constraints.maxWidth >= 300 && scaledLabelSize <= 21) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mixed),
              const SizedBox(width: 8),
              Expanded(child: undecided),
            ],
          ),
        );
      }
      return Column(children: [mixed, const SizedBox(height: 8), undecided]);
    },
  );
}

class _ReceiptCategoryEntryOption extends StatelessWidget {
  const _ReceiptCategoryEntryOption({
    required this.label,
    required this.helper,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String helper;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _receiptReferenceBlue : _receiptReferenceText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _receiptSetupChoiceSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? color : _receiptReferenceBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        helper,
                        style: const TextStyle(
                          color: _receiptReferenceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceReceiptClassificationButton extends StatelessWidget {
  const _ReferenceReceiptClassificationButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _receiptReferenceBlue : _receiptReferenceText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _receiptSetupChoiceSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? color : _receiptReferenceBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferenceReceiptCategoryTile extends StatelessWidget {
  const _ReferenceReceiptCategoryTile({
    required this.category,
    required this.onTap,
  });

  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = category == 'Uncategorized' ? 'Choose a category' : category;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: _receiptSetupChoiceSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _receiptReferenceBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.sell_outlined, color: _receiptReferenceMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _receiptReferenceText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.expand_more_rounded,
                color: _receiptReferenceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReferenceReceiptSectionLabel extends StatelessWidget {
  const _ReferenceReceiptSectionLabel({
    required this.label,
    required this.helper,
  });

  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) => RichText(
    text: TextSpan(
      style: const TextStyle(
        color: _receiptReferenceText,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      children: [
        TextSpan(text: label),
        TextSpan(
          text: ' ($helper)',
          style: const TextStyle(
            color: _receiptReferenceMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// Retained for compatibility with existing draft routing; new receipts use
// _ReferenceReceiptAppBar, which is the approved Figma layout.
// ignore: unused_element
class _ManualReceiptHeader extends StatelessWidget {
  const _ManualReceiptHeader({
    required this.step,
    required this.onBack,
    required this.onStepSelected,
  });

  final _ManualReceiptStep step;
  final VoidCallback onBack;
  final ValueChanged<_ManualReceiptStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Details', 'Items', 'Review'];
    final index = step.index;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: index == 0 ? 'Leave receipt' : 'Previous step',
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFFE8ECEE),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Receipt',
                      style: TextStyle(
                        color: Color(0xFFF2F7F8),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Step ${index + 1} of 3 · ${labels[index]}',
                      style: const TextStyle(
                        color: Color(0xFFB7C8CE),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var itemIndex = 0; itemIndex < labels.length; itemIndex++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: itemIndex == labels.length - 1 ? 0 : 6,
                    ),
                    child: _ManualReceiptStepButton(
                      label: labels[itemIndex],
                      step: _ManualReceiptStep.values[itemIndex],
                      selected: itemIndex == index,
                      completed: itemIndex < index,
                      enabled: true,
                      onPressed: onStepSelected,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManualReceiptStepButton extends StatelessWidget {
  const _ManualReceiptStepButton({
    required this.label,
    required this.step,
    required this.selected,
    required this.completed,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final _ManualReceiptStep step;
  final bool selected;
  final bool completed;
  final bool enabled;
  final ValueChanged<_ManualReceiptStep> onPressed;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFFFFD166)
        : completed
        ? const Color(0xFF2D7A4B)
        : const Color(0xFF344247);
    final foreground = selected
        ? const Color(0xFF1F2528)
        : completed
        ? Colors.white
        : const Color(0xFFB7C8CE);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$label step',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: enabled ? () => onPressed(step) : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualReceiptActionTile extends StatelessWidget {
  const _ManualReceiptActionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.actionLabel,
    this.color = const Color(0xFF8FC9FF),
    this.referenceChevronOnly = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? actionLabel;
  final Color color;
  final bool referenceChevronOnly;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: enabled,
      label: '$label. $value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: referenceChevronOnly
                ? const BoxConstraints(minHeight: 78)
                : const BoxConstraints(),
            child: Ink(
              decoration: BoxDecoration(
                color: _receiptReferenceSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _receiptReferenceBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: _receiptReferenceText,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            style: const TextStyle(
                              color: _receiptReferenceMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!referenceChevronOnly)
                      Text(
                        actionLabel ?? 'Edit',
                        style: TextStyle(
                          color: enabled ? color : const Color(0xFF91A4AB),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: referenceChevronOnly
                          ? _receiptReferenceText
                          : enabled
                          ? color
                          : const Color(0xFF91A4AB),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualReceiptPrimaryButton extends StatelessWidget {
  const _ManualReceiptPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _receiptReferenceGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

class _ManualReceiptItemCard extends StatelessWidget {
  const _ManualReceiptItemCard({
    required this.lineNumber,
    required this.line,
    required this.onEdit,
    required this.onDelete,
  });

  final int lineNumber;
  final _ExpenseReceiptLine line;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unitPrice = line.unitPrice;
    final quantityLabel = line.quantity == 1 && unitPrice == null
        ? ''
        : 'Qty ${line.quantityText}';
    final priceLabel = unitPrice == null ? '' : '${_money(unitPrice)} each';
    final categoryLabel = line.category == 'Uncategorized'
        ? ''
        : ' · ${line.category}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF283337),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF41545B)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$lineNumber.',
                  style: const TextStyle(
                    color: Color(0xFF8FC9FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.displayDescription,
                    style: const TextStyle(
                      color: Color(0xFFF2F7F8),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit item $lineNumber',
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFF8FC9FF),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete item $lineNumber',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFFF9B8E),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${line.use.label}$categoryLabel${[quantityLabel, priceLabel].where((label) => label.isNotEmpty).map((label) => ' · $label').join()}',
                    style: const TextStyle(
                      color: Color(0xFFB7C8CE),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _money(line.subtotal),
                  style: const TextStyle(
                    color: Color(0xFFF2F7F8),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (line.use == _ExpenseLineUse.split) ...[
              const SizedBox(height: 3),
              Text(
                line.allocationDetail,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
