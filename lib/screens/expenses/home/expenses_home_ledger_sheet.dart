part of 'expenses_home_screen.dart';

class _ExpenseLedgerSheet extends StatelessWidget {
  const _ExpenseLedgerSheet({
    required this.title,
    required this.detail,
    required this.entries,
    required this.scrollController,
  });

  final String title;
  final String detail;
  final List<_LedgerEntryData> entries;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _SectionHeader(eyebrow: 'EXPENSE LIST', title: title, detail: detail),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const _EmptyLedgerMessage()
        else
          for (final entry in entries) _LedgerRow(entry: entry),
      ],
    );
  }
}

class _EmptyLedgerMessage extends StatelessWidget {
  const _EmptyLedgerMessage({this.actionLabel, this.onAction});

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _SolidSection(
      backgroundColor: _ink,
      borderColor: _line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'No matching entries yet.',
            style: TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            _DialogButton(label: actionLabel!, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

class _PickerTitle extends StatelessWidget {
  const _PickerTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF0F4F2),
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _PickerGrid extends StatelessWidget {
  const _PickerGrid({required this.categories});

  final List<ExpenseCategoryDefinition> categories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 2 : 3;
        final spacing = 8.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _QuickExpenseTile(category: category),
              ),
          ],
        );
      },
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _blue,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
