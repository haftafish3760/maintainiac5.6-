part of 'maintenance_item_detail_screen.dart';

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.itemLabel,
    required this.onPreset,
    required this.onCustom,
  });

  static const selectValue = -2;
  static const customValue = -1;

  final String label;
  final int value;
  final List<int> options;
  final String Function(int value) itemLabel;
  final ValueChanged<int> onPreset;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final items = <int>[selectValue, ...options, customValue];
    final selected = options.contains(value) ? value : selectValue;
    return _CompactDropdownField<int>(
      label: label,
      value: selected,
      items: items,
      itemLabel: (item) {
        if (item == selectValue) return 'Select';
        if (item == customValue) return 'Custom';
        return itemLabel(item);
      },
      onChanged: (selected) {
        if (selected == selectValue) return;
        if (selected == customValue) {
          onCustom();
          return;
        }
        onPreset(selected);
      },
    );
  }
}

class _CompactDropdownField<T> extends StatelessWidget {
  const _CompactDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFAAB4B9),
            contentPadding: const EdgeInsets.fromLTRB(9, 14, 9, 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: const BorderSide(color: Color(0xFF879299)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: const BorderSide(color: Color(0xFFE2E8EA), width: 2),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
          ),
          dropdownColor: const Color(0xFFAAB4B9),
          iconEnabledColor: const Color(0xFF101416),
          style: const TextStyle(
            color: Color(0xFF101416),
            fontWeight: FontWeight.w800,
          ),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    itemLabel(item),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              )
              .toList(),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF101416),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
        Positioned(
          left: 8,
          top: -8,
          child: Container(
            color: const Color(0xFF11181B),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<int?> _showCustomNumberDialog({
  required BuildContext context,
  required String title,
  required String label,
  required int initialValue,
}) async {
  final controller = TextEditingController(
    text: initialValue <= 0 ? '' : initialValue.toString(),
  );
  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF182023),
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: Color(0xFFE7EEF1),
          fontWeight: FontWeight.w900,
        ),
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(controller.text.trim());
            Navigator.of(
              context,
            ).pop(value == null || value <= 0 ? null : value);
          },
          child: const Text('Use Custom'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

class _ThresholdBandColumns extends StatelessWidget {
  const _ThresholdBandColumns({
    required this.showMileage,
    required this.longTimeWindow,
  });

  final bool showMileage;
  final bool longTimeWindow;

  @override
  Widget build(BuildContext context) {
    final timeBands = longTimeWindow
        ? const [
            _ThresholdBandData('43+ days', AppActionColors.positive),
            _ThresholdBandData('29-42 days', AppColors.yellow),
            _ThresholdBandData('15-28 days', AppColors.orange),
            _ThresholdBandData('0-14 days', AppColors.red),
          ]
        : const [
            _ThresholdBandData('31+ days', AppActionColors.positive),
            _ThresholdBandData('21-30 days', AppColors.yellow),
            _ThresholdBandData('11-20 days', AppColors.orange),
            _ThresholdBandData('0-10 days', AppColors.red),
          ];
    const mileageBands = [
      _ThresholdBandData('900+ miles', AppActionColors.positive),
      _ThresholdBandData('601-900 miles', AppColors.yellow),
      _ThresholdBandData('301-600 miles', AppColors.orange),
      _ThresholdBandData('0-300 miles', AppColors.red),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'These ranges control when this item changes color on the maintenance home screen.',
          style: TextStyle(
            color: Color(0xFFCAD2D5),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        _ThresholdGrid(
          showMileage: showMileage,
          mileageBands: mileageBands,
          timeBands: timeBands,
        ),
      ],
    );
  }
}

class _ThresholdGrid extends StatelessWidget {
  const _ThresholdGrid({
    required this.showMileage,
    required this.mileageBands,
    required this.timeBands,
  });

  final bool showMileage;
  final List<_ThresholdBandData> mileageBands;
  final List<_ThresholdBandData> timeBands;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3D4A50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              children: [
                if (showMileage)
                  const Expanded(
                    child: _ThresholdHeaderCell(label: 'Mileage Window'),
                  ),
                if (showMileage) const SizedBox(width: 8),
                const Expanded(
                  child: _ThresholdHeaderCell(label: 'Time Window'),
                ),
              ],
            ),
          ),
          for (var index = 0; index < timeBands.length; index++)
            _ThresholdBandRow(
              mileage: showMileage ? mileageBands[index] : null,
              time: timeBands[index],
            ),
        ],
      ),
    );
  }
}

class _ThresholdHeaderCell extends StatelessWidget {
  const _ThresholdHeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFE7EEF1),
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ThresholdBandRow extends StatelessWidget {
  const _ThresholdBandRow({required this.mileage, required this.time});

  final _ThresholdBandData? mileage;
  final _ThresholdBandData time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          if (mileage != null) Expanded(child: _ThresholdBand(data: mileage!)),
          if (mileage != null) const SizedBox(width: 8),
          Expanded(child: _ThresholdBand(data: time)),
        ],
      ),
    );
  }
}

class _ThresholdBand extends StatelessWidget {
  const _ThresholdBand({required this.data});

  final _ThresholdBandData data;

  @override
  Widget build(BuildContext context) {
    final textColor = data.color == AppColors.yellow
        ? const Color(0xFF101416)
        : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        data.range,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ThresholdBandData {
  const _ThresholdBandData(this.range, this.color);

  final String range;
  final Color color;
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.inApp,
    required this.push,
    required this.sound,
    required this.onInApp,
    required this.onPush,
    required this.onSound,
  });

  final bool inApp;
  final bool push;
  final bool sound;
  final ValueChanged<bool> onInApp;
  final ValueChanged<bool> onPush;
  final ValueChanged<bool> onSound;

  @override
  Widget build(BuildContext context) {
    return _SetupSection(
      title: 'Item Reminders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose reminders for this item.',
            style: TextStyle(
              color: Color(0xFFCAD2D5),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          _NotificationSwitch(
            label: 'In-app maintenance notice',
            helper: 'Shows this item in maintenance alerts inside the app.',
            value: inApp,
            onChanged: onInApp,
          ),
          _NotificationSwitch(
            label: 'Push notification',
            helper:
                'Uses the app notification channel after permissions are set up.',
            value: push,
            onChanged: onPush,
          ),
          _NotificationSwitch(
            label: 'Audible reminder',
            helper:
                'Uses sound only after the app notification channel allows it.',
            value: sound,
            onChanged: onSound,
          ),
        ],
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  const _NotificationSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final String? helper;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeThumbColor: AppActionColors.positive,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: helper == null ? null : Text(helper!),
      onChanged: onChanged,
    );
  }
}
