import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'odometer_correction_review.dart';
import 'odometer_mileage_review.dart';
import '../theme/app_action_colors.dart';
import '../state/global_odometer.dart';
import '../trip_tracking/trip_tracking_odometer_reconciliation.dart';
import '../trip_tracking/trip_tracking_session_store.dart';

part 'odometer_correction_review_panel.dart';

class OdometerEntrySheet extends StatefulWidget {
  const OdometerEntrySheet({
    super.key,
    required this.title,
    required this.saveLabel,
    this.onSaved,
    this.tripReview,
  });

  final String title;
  final String saveLabel;
  final VoidCallback? onSaved;
  final TripTrackingReviewRecord? tripReview;

  @override
  State<OdometerEntrySheet> createState() => _OdometerEntrySheetState();
}

class _OdometerEntrySheetState extends State<OdometerEntrySheet> {
  TextEditingController? _controller;
  final _businessMilesController = TextEditingController();
  GlobalOdometerController? _odometer;
  String? _errorText;
  String? _lastAutomaticOdometerText;
  var _odometerManuallyEdited = false;
  var _pendingConfirmation = false;
  int? _pendingDeltaMiles;
  int? _pendingCurrentReading;
  int? _pendingCandidateReading;
  OdometerMileageUse? _selectedUse;
  OdometerCorrectionReason? _selectedCorrectionReason;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final odometer = GlobalOdometerScope.of(context);
    if (_odometer != odometer) {
      _odometer?.removeListener(_syncOdometerTextFromScope);
      _odometer = odometer..addListener(_syncOdometerTextFromScope);
    }
    _controller ??= TextEditingController(text: odometer.reading.toString());
    _lastAutomaticOdometerText ??= _controller!.text;
    _syncOdometerTextFromScope();
  }

  @override
  void dispose() {
    _odometer?.removeListener(_syncOdometerTextFromScope);
    _controller?.dispose();
    _businessMilesController.dispose();
    super.dispose();
  }

  void _syncOdometerTextFromScope() {
    final controller = _controller;
    final odometer = _odometer;
    if (controller == null || odometer == null) return;
    final nextText = odometer.reading.toString();
    if (_odometerManuallyEdited &&
        controller.text != _lastAutomaticOdometerText) {
      return;
    }
    if (controller.text == nextText) {
      _lastAutomaticOdometerText = nextText;
      return;
    }
    controller.value = controller.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );
    _lastAutomaticOdometerText = nextText;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tripReconciliation = _tripReconciliation;
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              onChanged: (value) {
                if (value != _lastAutomaticOdometerText) {
                  _odometerManuallyEdited = true;
                }
                setState(() {
                  if (_pendingConfirmation ||
                      _pendingDeltaMiles != null ||
                      _pendingCurrentReading != null ||
                      _errorText != null) {
                    _pendingConfirmation = false;
                    _pendingDeltaMiles = null;
                    _pendingCurrentReading = null;
                    _pendingCandidateReading = null;
                    _selectedUse = null;
                    _selectedCorrectionReason = null;
                    _businessMilesController.clear();
                    _errorText = null;
                  }
                });
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
                errorMaxLines: 3,
                filled: true,
                fillColor: const Color(0xFFAAB4B9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            if (tripReconciliation != null) ...[
              const SizedBox(height: 12),
              _TripGpsReconciliationPanel(reconciliation: tripReconciliation),
            ],
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
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
    final tripReview = widget.tripReview;
    if (tripReview != null &&
        tripReview.vehicleId != GlobalOdometerScope.of(context).vehicleId) {
      setState(() {
        _errorText =
            'Switch to the vehicle used for this GPS trip before confirming its odometer.';
      });
      return;
    }
    final review = _buildMileageReview();
    final correctionReview = _buildCorrectionReview();
    final savedReading = int.tryParse(_controller?.text ?? '');
    final result = GlobalOdometerScope.of(context).updateFromText(
      _controller?.text ?? '',
      confirmSuspicious: _pendingConfirmation,
      mileageReview: review,
      correctionReview: correctionReview,
      sourceType: tripReview == null ? null : 'gps_trip_review',
      sourceId: tripReview?.id,
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
        _errorText = result.requiresCorrectionReview ? null : result.message;
      });
      return;
    }

    widget.onSaved?.call();
    Navigator.of(context).pop(savedReading);
  }

  TripOdometerReconciliation? get _tripReconciliation {
    final review = widget.tripReview;
    final candidate = int.tryParse(_controller?.text ?? '');
    if (review == null ||
        candidate == null ||
        candidate == review.startingOdometer) {
      return null;
    }
    return TripOdometerReconciliation.compare(
      review: review,
      confirmedEndingOdometer: candidate,
    );
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

class _TripGpsReconciliationPanel extends StatelessWidget {
  const _TripGpsReconciliationPanel({required this.reconciliation});

  final TripOdometerReconciliation reconciliation;

  @override
  Widget build(BuildContext context) {
    final needsReview =
        reconciliation.status ==
        TripOdometerReconciliationStatus.reviewRecommended;
    final invalid =
        reconciliation.status == TripOdometerReconciliationStatus.invalid;
    final color = invalid || needsReview
        ? const Color(0xFFFFD27A)
        : const Color(0xFF75D6A5);
    final message = invalid
        ? 'The confirmed odometer cannot be lower than the trip start.'
        : needsReview
        ? 'GPS differs materially. Confirmed odometer remains authoritative.'
        : 'GPS is within the review tolerance. Confirmed odometer remains authoritative.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GPS TRIP COMPARISON',
              style: TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Confirmed: ${reconciliation.confirmedOdometerDeltaMiles.toStringAsFixed(0)} mi • '
              'GPS: ${reconciliation.filteredGpsMiles.toStringAsFixed(1)} mi',
              style: const TextStyle(color: Color(0xFFC8D0D3), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
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
