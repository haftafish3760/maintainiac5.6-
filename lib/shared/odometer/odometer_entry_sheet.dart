import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'odometer_correction_review.dart';
import 'odometer_mileage_review.dart';
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
  final _businessMilesController = TextEditingController();
  String? _errorText;
  var _pendingConfirmation = false;
  int? _pendingDeltaMiles;
  int? _pendingCurrentReading;
  int? _pendingCandidateReading;
  OdometerMileageUse? _selectedUse;
  OdometerCorrectionReason? _selectedCorrectionReason;

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
    _businessMilesController.dispose();
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
              style: const TextStyle(
                color: Color(0xFF101416),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              onSubmitted: (_) => _saveReading(),
              onChanged: (_) {
                if (_pendingConfirmation ||
                    _pendingDeltaMiles != null ||
                    _pendingCurrentReading != null ||
                    _errorText != null) {
                  setState(() {
                    _pendingConfirmation = false;
                    _pendingDeltaMiles = null;
                    _pendingCurrentReading = null;
                    _pendingCandidateReading = null;
                    _selectedUse = null;
                    _selectedCorrectionReason = null;
                    _businessMilesController.clear();
                    _errorText = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Current odometer reading',
                // The focused outline must not run through the floating label.
                // Match the field surface so the label stays legible on the
                // Start Day sheet on high-contrast Android displays.
                floatingLabelStyle: const TextStyle(
                  color: Color(0xFF101416),
                  backgroundColor: Color(0xFFAAB4B9),
                  fontWeight: FontWeight.w800,
                ),
                hintText: '298150',
                errorText: _errorText,
                filled: true,
                fillColor: const Color(0xFFAAB4B9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            if (_pendingCurrentReading != null &&
                _pendingCandidateReading != null) ...[
              const SizedBox(height: 12),
              _CorrectionReviewPanel(
                currentReading: _pendingCurrentReading!,
                candidateReading: _pendingCandidateReading!,
                selectedReason: _selectedCorrectionReason,
                onReasonChanged: (reason) {
                  setState(() {
                    _selectedCorrectionReason = reason;
                    _errorText = null;
                  });
                },
              ),
            ],
            if (_pendingDeltaMiles != null) ...[
              const SizedBox(height: 12),
              _MileageReviewPanel(
                deltaMiles: _pendingDeltaMiles!,
                selectedUse: _selectedUse,
                businessMilesController: _businessMilesController,
                onUseChanged: (use) {
                  setState(() {
                    _selectedUse = use;
                    _errorText = null;
                    if (use != OdometerMileageUse.split) {
                      _businessMilesController.clear();
                    }
                  });
                },
              ),
            ],
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
                  child: Text(
                    _pendingDeltaMiles != null
                        ? 'Save Miles'
                        : _pendingCurrentReading != null
                        ? 'Save Review'
                        : _pendingConfirmation
                        ? 'Confirm Reading'
                        : widget.saveLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveReading() {
    final review = _buildMileageReview();
    final correctionReview = _buildCorrectionReview();
    final result = GlobalOdometerScope.of(context).updateFromText(
      _controller?.text ?? '',
      confirmSuspicious: _pendingConfirmation,
      mileageReview: review,
      correctionReview: correctionReview,
    );

    if (!result.ok) {
      setState(() {
        _pendingConfirmation = result.requiresConfirmation;
        _pendingDeltaMiles = result.requiresMileageReview
            ? result.deltaMiles
            : _pendingDeltaMiles;
        if (result.requiresCorrectionReview) {
          _pendingCurrentReading = result.currentReading;
          _pendingCandidateReading = result.candidateReading;
        }
        _errorText = result.message;
      });
      return;
    }

    widget.onSaved?.call();
    Navigator.of(context).pop(true);
  }

  OdometerMileageReview? _buildMileageReview() {
    if (_pendingDeltaMiles == null) return null;
    final use = _selectedUse;
    if (use == null) return null;
    final businessMiles = use == OdometerMileageUse.split
        ? int.tryParse(_businessMilesController.text.trim())
        : null;
    return OdometerMileageReview(use: use, businessMiles: businessMiles);
  }

  OdometerCorrectionReview? _buildCorrectionReview() {
    if (_pendingCurrentReading == null || _pendingCandidateReading == null) {
      return null;
    }
    final reason = _selectedCorrectionReason;
    if (reason == null) return null;
    return OdometerCorrectionReview(reason: reason);
  }
}

class _CorrectionReviewPanel extends StatelessWidget {
  const _CorrectionReviewPanel({
    required this.currentReading,
    required this.candidateReading,
    required this.selectedReason,
    required this.onReasonChanged,
  });

  final int currentReading;
  final int candidateReading;
  final OdometerCorrectionReason? selectedReason;
  final ValueChanged<OdometerCorrectionReason> onReasonChanged;

  @override
  Widget build(BuildContext context) {
    final difference = currentReading - candidateReading;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5A3838)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is ${_comma(difference)} miles lower.',
              style: const TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Current odometer is ${_comma(currentReading)}. What happened?',
              style: const TextStyle(color: Color(0xFFC8D0D3), fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OdometerCorrectionReason.values.map((reason) {
                final selected = selectedReason == reason;
                return ChoiceChip(
                  label: Text(reason.label),
                  selected: selected,
                  onSelected: (_) => onReasonChanged(reason),
                  selectedColor: const Color(0xFFFFC857),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : const Color(0xFFE3E8EA),
                    fontWeight: FontWeight.w800,
                  ),
                  backgroundColor: const Color(0xFF1B2427),
                  side: const BorderSide(color: Color(0xFF344247)),
                );
              }).toList(),
            ),
            if (selectedReason == OdometerCorrectionReason.previousEntryWrong ||
                selectedReason == OdometerCorrectionReason.odometerReplaced)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'This will need the full correction flow so the audit trail stays clean.',
                  style: TextStyle(color: Color(0xFFFFD27A), fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MileageReviewPanel extends StatelessWidget {
  const _MileageReviewPanel({
    required this.deltaMiles,
    required this.selectedUse,
    required this.businessMilesController,
    required this.onUseChanged,
  });

  final int deltaMiles;
  final OdometerMileageUse? selectedUse;
  final TextEditingController businessMilesController;
  final ValueChanged<OdometerMileageUse> onUseChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3A3E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You added ${_comma(deltaMiles)} miles.',
              style: const TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'How should these miles be counted?',
              style: TextStyle(color: Color(0xFFC8D0D3), fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OdometerMileageUse.values.map((use) {
                final selected = selectedUse == use;
                return ChoiceChip(
                  label: Text(use.label),
                  selected: selected,
                  onSelected: (_) => onUseChanged(use),
                  selectedColor: AppActionColors.positive,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFFE3E8EA),
                    fontWeight: FontWeight.w800,
                  ),
                  backgroundColor: const Color(0xFF1B2427),
                  side: const BorderSide(color: Color(0xFF344247)),
                );
              }).toList(),
            ),
            if (selectedUse == OdometerMileageUse.split) ...[
              const SizedBox(height: 12),
              TextField(
                controller: businessMilesController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: 'Business miles',
                  hintText: '0',
                  helperText: 'Personal miles are calculated from the rest.',
                  filled: true,
                  fillColor: const Color(0xFFAAB4B9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _comma(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    final remaining = raw.length - index;
    buffer.write(raw[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
