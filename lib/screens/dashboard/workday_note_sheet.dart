import 'package:flutter/material.dart';

import '../../shared/theme/app_action_colors.dart';

Future<String?> openWorkdayNoteSheet(
  BuildContext context, {
  String title = 'Add Workday Note',
  String fieldLabel = 'Note',
  String hintText = 'What happened or what needs to be remembered?',
  String saveLabel = 'Save Note',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF172023),
    builder: (context) => _WorkdayNoteSheet(
      title: title,
      fieldLabel: fieldLabel,
      hintText: hintText,
      saveLabel: saveLabel,
    ),
  );
}

class _WorkdayNoteSheet extends StatefulWidget {
  const _WorkdayNoteSheet({
    required this.title,
    required this.fieldLabel,
    required this.hintText,
    required this.saveLabel,
  });

  final String title;
  final String fieldLabel;
  final String hintText;
  final String saveLabel;

  @override
  State<_WorkdayNoteSheet> createState() => _WorkdayNoteSheetState();
}

class _WorkdayNoteSheetState extends State<_WorkdayNoteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.trim().isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF2F5F6),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                hintText: widget.hintText,
                filled: true,
                fillColor: const Color(0xFFAAB4B9),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canSave
                      ? () => Navigator.of(context).pop(_controller.text.trim())
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppActionColors.positive,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.saveLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
