part of 'expenses_home_screen.dart';

class _QuickActionSettingsSheet extends StatefulWidget {
  const _QuickActionSettingsSheet({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_QuickActionSettingsSheet> createState() =>
      _QuickActionSettingsSheetState();
}

class _QuickActionSettingsSheetState extends State<_QuickActionSettingsSheet> {
  final List<ExpenseCategoryDefinition> _pinned = [];
  var _loadedPinned = false;
  int? _draggingIndex;
  int? _hoverIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedPinned) return;
    _loadedPinned = true;
    _pinned.addAll(
      _quickCategoriesFromSettings(ExpenseSettingsScope.of(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ExpenseSettingsScope.of(context);
    final available = [...defaultExpenseCategories, ...otherExpenseCategories]
        .where(
          (category) =>
              !_pinned.any((item) => item.category == category.category),
        );

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        const _PickerTitle('Home Screen Expense Buttons'),
        const SizedBox(height: 4),
        _HomeButtonModePanel(
          topTenEnabled: settings.autoTrackQuickCategories,
          onChanged: settings.setAutoTrackQuickCategories,
        ),
        const SizedBox(height: 10),
        const Text(
          'Choose Mine layout. Drag to rearrange. Use minus to remove a category from this screen.',
          style: TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.18,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 360 ? 2 : 3;
            final spacing = 8.0;
            final width =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            final displayPinned = _previewPinnedOrder();
            return Wrap(
              spacing: spacing,
              runSpacing: 8,
              children: [
                for (final category in displayPinned)
                  SizedBox(
                    width: width,
                    child: _PinnedQuickActionTile(
                      category: category,
                      index: _pinnedIndexFor(category),
                      dragging: _draggingIndex != null,
                      onMove: _movePinned,
                      onHover: _setHoverIndex,
                      onDragStarted: _setDraggingIndex,
                      onDragEnded: _clearDragPreview,
                      onRemove: () => _removePinned(_pinnedIndexFor(category)),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        const _PickerTitle('Add More Categories'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 360 ? 2 : 3;
            final spacing = 8.0;
            final width =
                (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: 8,
              children: [
                for (final category in available)
                  SizedBox(
                    width: width,
                    child: _AddQuickActionTile(
                      category: category,
                      onAdd: _pinned.length >= 9
                          ? null
                          : () => _addPinned(category),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _movePinned(int from, int to) {
    if (from == to || from < 0 || from >= _pinned.length) {
      return;
    }
    setState(() {
      final item = _pinned.removeAt(from);
      final insertAt = to.clamp(0, _pinned.length);
      _pinned.insert(insertAt, item);
    });
    _savePinned();
  }

  int _pinnedIndexFor(ExpenseCategoryDefinition category) {
    return _pinned.indexWhere((item) => item.category == category.category);
  }

  List<ExpenseCategoryDefinition> _previewPinnedOrder() {
    final from = _draggingIndex;
    final to = _hoverIndex;
    if (from == null ||
        to == null ||
        from == to ||
        from < 0 ||
        from >= _pinned.length ||
        to < 0 ||
        to >= _pinned.length) {
      return [..._pinned];
    }
    final preview = [..._pinned];
    final item = preview.removeAt(from);
    preview.insert(to.clamp(0, preview.length), item);
    return preview;
  }

  void _setDraggingIndex(int index) {
    setState(() {
      _draggingIndex = index;
      _hoverIndex = index;
    });
  }

  void _setHoverIndex(int index) {
    if (_hoverIndex == index) return;
    setState(() => _hoverIndex = index);
  }

  void _clearDragPreview() {
    if (_draggingIndex == null && _hoverIndex == null) return;
    setState(() {
      _draggingIndex = null;
      _hoverIndex = null;
    });
  }

  void _removePinned(int index) {
    setState(() => _pinned.removeAt(index));
    _savePinned();
  }

  void _addPinned(ExpenseCategoryDefinition category) {
    setState(() => _pinned.add(category));
    _savePinned();
  }

  void _savePinned() {
    ExpenseSettingsScope.of(context).setQuickCategoryOrder(
      _pinned.map((category) => category.category).toList(),
    );
  }
}

class _HomeButtonModePanel extends StatelessWidget {
  const _HomeButtonModePanel({
    required this.topTenEnabled,
    required this.onChanged,
  });

  final bool topTenEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SolidSection(
      backgroundColor: _ink,
      borderColor: _line,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: topTenEnabled,
        onChanged: onChanged,
        activeThumbColor: _gold,
        title: const Text(
          'Show Top 10 Automatically',
          style: TextStyle(
            color: Color(0xFFF0F4F2),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        subtitle: const Text(
          'Turn off to use the custom order below.',
          style: TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _PinnedQuickActionTile extends StatelessWidget {
  const _PinnedQuickActionTile({
    required this.category,
    required this.index,
    required this.dragging,
    required this.onMove,
    required this.onHover,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onRemove,
  });

  final ExpenseCategoryDefinition category;
  final int index;
  final bool dragging;
  final void Function(int from, int to) onMove;
  final ValueChanged<int> onHover;
  final ValueChanged<int> onDragStarted;
  final VoidCallback onDragEnded;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onMove: (_) => onHover(index),
      onAcceptWithDetails: (details) => onMove(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          onDragStarted: () => onDragStarted(index),
          onDragEnd: (_) => onDragEnded(),
          onDraggableCanceled: (_, _) => onDragEnded(),
          onDragCompleted: onDragEnded,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 112,
              child: _PinnedTileSurface(
                category: category,
                highlighted: true,
                onRemove: null,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: dragging ? .15 : .35,
            child: _PinnedTileSurface(
              category: category,
              highlighted: false,
              onRemove: onRemove,
            ),
          ),
          child: _PinnedTileSurface(
            category: category,
            highlighted: highlighted,
            onRemove: onRemove,
          ),
        );
      },
    );
  }
}

class _PinnedTileSurface extends StatelessWidget {
  const _PinnedTileSurface({
    required this.category,
    required this.highlighted,
    required this.onRemove,
  });

  final ExpenseCategoryDefinition category;
  final bool highlighted;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 88,
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlighted ? _gold : const Color(0xFF385864),
            width: highlighted ? 1.6 : 1.1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF071013),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: category.gradient.first,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        _iconFor(category.icon),
                        color: category.gradient.first,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.drag_indicator_rounded,
                      color: Color(0xFFBFD0D6),
                      size: 20,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  category.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            Positioned(
              top: -9,
              right: -9,
              child: IconButton(
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                icon: Icon(Icons.remove_circle_rounded, color: _red, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddQuickActionTile extends StatelessWidget {
  const _AddQuickActionTile({required this.category, required this.onAdd});

  final ExpenseCategoryDefinition category;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 82,
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF385864), width: 1.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    _iconFor(category.icon),
                    color: onAdd == null ? const Color(0xFF7E898E) : _gold,
                    size: 20,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.add_circle_rounded,
                    color: onAdd == null ? const Color(0xFF7E898E) : _green,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                category.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onAdd == null
                      ? const Color(0xFF9FAAAF)
                      : const Color(0xFFF0F4F2),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
