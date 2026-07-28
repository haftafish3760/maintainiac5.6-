part of 'expense_receipt_entry_screen.dart';

class _ReceiptReadHandoffPanel extends StatelessWidget {
  const _ReceiptReadHandoffPanel({
    required this.savedProofCount,
    required this.ocrSourceCount,
    required this.processingInFlight,
    required this.decisionLabel,
    required this.actionLabel,
    required this.stageLabel,
    required this.routeResultLabel,
    required this.coverageWarningLabel,
    required this.onReviewDetails,
    required this.onAddOrRetakePhoto,
  });

  final int savedProofCount;
  final int ocrSourceCount;
  final bool processingInFlight;
  final String decisionLabel;
  final String actionLabel;
  final String stageLabel;
  final String routeResultLabel;
  final String coverageWarningLabel;
  final VoidCallback onReviewDetails;
  final VoidCallback onAddOrRetakePhoto;

  @override
  Widget build(BuildContext context) {
    final presentation = _ReceiptHandoffPresentation.from(
      processingInFlight: processingInFlight,
      decisionLabel: decisionLabel,
      actionLabel: actionLabel,
      stageLabel: stageLabel,
      routeResultLabel: routeResultLabel,
      coverageWarningLabel: coverageWarningLabel,
    );
    return Semantics(
      liveRegion: processingInFlight,
      label: '${presentation.title}. ${presentation.status}',
      child: ReceiptFormPanel(
        title: presentation.title,
        subtitle: presentation.subtitle,
        icon: presentation.icon,
        accentColor: presentation.accent,
        children: [
          _ReceiptHandoffStatus(
            processingInFlight: processingInFlight,
            status: presentation.status,
            supportingText: presentation.supportingText,
            currentStep: presentation.currentStep,
          ),
          if (!processingInFlight) ...[
            const SizedBox(height: 10),
            Text(
              _sourceSummary,
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onReviewDetails,
                  icon: const Icon(Icons.fact_check_rounded),
                  label: Text(presentation.primaryActionLabel),
                  style: _primaryButtonStyle(presentation.accent),
                ),
                OutlinedButton.icon(
                  onPressed: onAddOrRetakePhoto,
                  icon: Icon(presentation.photoActionIcon),
                  label: Text(presentation.photoActionLabel),
                  style: _photoButtonStyle,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String get _sourceSummary {
    final proof = savedProofCount == 1
        ? '1 receipt photo saved'
        : '$savedProofCount receipt photos saved';
    if (ocrSourceCount <= 0) return '$proof. Manual entry remains available.';
    final source = ocrSourceCount == 1
        ? '1 clear photo was read'
        : '$ocrSourceCount clear photos were read';
    return '$proof. $source.';
  }

  ButtonStyle _primaryButtonStyle(Color accent) {
    return FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: const Color(0xFF101618),
      minimumSize: const Size(180, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }

  ButtonStyle get _photoButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFFFD166),
      side: const BorderSide(color: Color(0xFFFFD166), width: 1.2),
      minimumSize: const Size(180, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }
}

class _ReceiptHandoffStatus extends StatelessWidget {
  const _ReceiptHandoffStatus({
    required this.processingInFlight,
    required this.status,
    required this.supportingText,
    required this.currentStep,
  });

  final bool processingInFlight;
  final String status;
  final String supportingText;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF182124),
        border: Border.all(color: const Color(0xFF43515A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (processingInFlight)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xFFFFD166),
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.fact_check_rounded,
                    size: 22,
                    color: Color(0xFF8EF6A4),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            if (processingInFlight) ...[
              const SizedBox(height: 10),
              _ReceiptHandoffSteps(currentStep: currentStep),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: currentStep / 3,
                minHeight: 4,
                color: const Color(0xFFFFD166),
                backgroundColor: const Color(0xFF43515A),
              ),
            ],
            if (supportingText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                supportingText,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReceiptHandoffSteps extends StatelessWidget {
  const _ReceiptHandoffSteps({required this.currentStep});

  final int currentStep;

  static const _labels = [
    'Reading receipt',
    'Preparing details',
    'Opening review',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Step $currentStep of ${_labels.length}',
          style: const TextStyle(
            color: Color(0xFFFFD166),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        for (var index = 0; index < _labels.length; index++)
          _ReceiptHandoffStep(
            label: _labels[index],
            isCurrent: index + 1 == currentStep,
            isComplete: index + 1 < currentStep,
          ),
      ],
    );
  }
}

class _ReceiptHandoffStep extends StatelessWidget {
  const _ReceiptHandoffStep({
    required this.label,
    required this.isCurrent,
    required this.isComplete,
  });

  final String label;
  final bool isCurrent;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? const Color(0xFFFFD166)
        : isComplete
        ? const Color(0xFF8EF6A4)
        : const Color(0xFF71808A);
    // The user should be able to tell the active operation at a glance.
    // Completed steps stay visible as evidence; future steps deliberately
    // recede instead of looking like parallel, active work.
    final opacity = isCurrent
        ? 1.0
        : isComplete
        ? 0.68
        : 0.42;
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              isComplete ? Icons.check_circle_rounded : Icons.circle_rounded,
              color: color,
              size: 15,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptHandoffPresentation {
  const _ReceiptHandoffPresentation({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.supportingText,
    required this.primaryActionLabel,
    required this.photoActionLabel,
    required this.photoActionIcon,
    required this.icon,
    required this.accent,
    required this.currentStep,
  });

  factory _ReceiptHandoffPresentation.from({
    required bool processingInFlight,
    required String decisionLabel,
    required String actionLabel,
    required String stageLabel,
    required String routeResultLabel,
    required String coverageWarningLabel,
  }) {
    final decision = decisionLabel.trim();
    final action = actionLabel.trim();
    final stage = stageLabel.trim();
    final route = routeResultLabel.trim();
    final warning = coverageWarningLabel.trim();
    if (processingInFlight) {
      return _ReceiptHandoffPresentation(
        title: 'Extracting Receipt Information',
        subtitle:
            'Maintainiac is reading the saved receipt photo and preparing editable fields.',
        status: stage.isEmpty ? 'Reading receipt text' : stage,
        supportingText:
            'This should finish shortly. If the receipt cannot be read, the saved photo and manual receipt form remain available.',
        primaryActionLabel: 'Review Receipt',
        photoActionLabel: 'Retake / Add Photo',
        photoActionIcon: Icons.add_photo_alternate_rounded,
        icon: Icons.document_scanner_rounded,
        accent: const Color(0xFFFFD166),
        currentStep: _progressStepFor(stage),
      );
    }
    final needsBottom = '$decision $stage $route $warning'
        .toLowerCase()
        .contains('bottom');
    final manual = '$decision $stage $route'.toLowerCase().contains('manual');
    final ready = !manual && !needsBottom;
    return _ReceiptHandoffPresentation(
      title: ready ? 'Receipt Ready To Review' : 'Receipt Needs Review',
      subtitle: ready
          ? 'Check every filled field against the saved receipt before saving.'
          : 'The saved receipt is available while you correct or complete its details.',
      status: stage.isNotEmpty
          ? stage
          : decision.isNotEmpty
          ? decision
          : ready
          ? 'Editable receipt details are ready'
          : 'Manual receipt review is ready',
      supportingText: warning.isNotEmpty
          ? warning
          : action.isNotEmpty
          ? action
          : route,
      primaryActionLabel: manual ? 'Open Receipt Form' : 'Review Receipt',
      photoActionLabel: needsBottom
          ? 'Add Bottom Section'
          : 'Retake / Add Photo',
      photoActionIcon: needsBottom
          ? Icons.vertical_align_bottom_rounded
          : Icons.add_photo_alternate_rounded,
      icon: ready ? Icons.fact_check_rounded : Icons.edit_note_rounded,
      accent: ready ? const Color(0xFF8EF6A4) : const Color(0xFFFFD166),
      currentStep: 3,
    );
  }

  final String title;
  final String subtitle;
  final String status;
  final String supportingText;
  final String primaryActionLabel;
  final String photoActionLabel;
  final IconData photoActionIcon;
  final IconData icon;
  final Color accent;
  final int currentStep;

  static int _progressStepFor(String stage) {
    final normalized = stage.toLowerCase();
    if (normalized.contains('preparing') || normalized.contains('filling')) {
      return 2;
    }
    return 1;
  }
}
