import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_action_colors.dart';
import '../state/global_odometer.dart';

class OdometerEntrySheet extends StatefulWidget {
  const OdometerEntrySheet({
    super.key,
    required this.title,
    required this.saveLabel,
    this.onSaved,
  });

  final String title;
  final String saveLabel;
  final VoidCallback? onSaved;

  @override
  State<OdometerEntrySheet> createState() => _OdometerEntrySheetState();
}

class _OdometerEntrySheetState extends State<OdometerEntrySheet> {
  TextEditingController? _controller;
  String? _errorText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= TextEditingController(
      text: GlobalOdometerScope.of(context).reading.toString(),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Color(0xFF101416),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              onSubmitted: (_) => _saveReading(),
              decoration: InputDecoration(
                labelText: 'Current odometer reading',
                hintText: '298150',
                errorText: _errorText,
                filled: true,
                fillColor: const Color(0xFFAAB4B9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saveReading,
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

  void _saveReading() {
    final result = GlobalOdometerScope.of(
      context,
    ).updateFromText(_controller?.text ?? '');

    if (!result.ok) {
      setState(() => _errorText = result.message);
      return;
    }

    widget.onSaved?.call();
    Navigator.of(context).pop(true);
  }
}
