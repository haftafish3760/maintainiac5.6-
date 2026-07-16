part of 'receipt_attachment_panel.dart';

enum _ReceiptReadStatusKind { reading, success, warning, failed }

enum _ReceiptReadProgressPhase { idle, accepted, readingText, openingDetails }

class _ReceiptReadReviewStatus extends StatelessWidget {
  const _ReceiptReadReviewStatus({
    required this.reading,
    required this.status,
    required this.message,
    required this.progressPhase,
    required this.uiConfig,
    this.onRetry,
    this.onContinueManually,
  });

  final bool reading;
  final _ReceiptReadStatusKind status;
  final String message;
  final _ReceiptReadProgressPhase progressPhase;
  final ReceiptCaptureUiConfig uiConfig;
  final VoidCallback? onRetry;
  final VoidCallback? onContinueManually;

  @override
  Widget build(BuildContext context) {
    final text = message.trim().isEmpty
        ? uiConfig.readStatusLabel(
            'defaultMessage',
            'Preparing receipt details...',
          )
        : message;
    final effectiveStatus = reading ? _ReceiptReadStatusKind.reading : status;
    final defaultTitle = switch (effectiveStatus) {
      _ReceiptReadStatusKind.reading => 'Opening Receipt Details',
      _ReceiptReadStatusKind.success => 'Receipt Ready For Review',
      _ReceiptReadStatusKind.warning => 'Receipt Needs Review',
      _ReceiptReadStatusKind.failed => 'Receipt Could Not Be Read',
    };
    final statusKey = effectiveStatus.name;
    final title = uiConfig.readStatusLabel('${statusKey}Title', defaultTitle);
    final defaultRecoveryHint = switch (effectiveStatus) {
      _ReceiptReadStatusKind.reading =>
        'Keep this screen open. Your receipt details will appear here as soon as they are ready.',
      _ReceiptReadStatusKind.success =>
        'Check the store, date, totals, Business/Personal choice, and receipt lines.',
      _ReceiptReadStatusKind.warning =>
        'Check the highlighted fields and line items before saving.',
      _ReceiptReadStatusKind.failed =>
        'Use a clearer photo, choose Add Another Photo for a long receipt, or keep the proof and fill the receipt by hand.',
    };
    final recoveryHint = uiConfig.readStatusLabel(
      '${statusKey}RecoveryHint',
      defaultRecoveryHint,
    );
    final accent = switch (effectiveStatus) {
      _ReceiptReadStatusKind.reading => const Color(0xFFFFD166),
      _ReceiptReadStatusKind.success => const Color(0xFF8EF6A4),
      _ReceiptReadStatusKind.warning => const Color(0xFFFFD166),
      _ReceiptReadStatusKind.failed => const Color(0xFFFF8A80),
    };
    final icon = switch (effectiveStatus) {
      _ReceiptReadStatusKind.reading => null,
      _ReceiptReadStatusKind.success => Icons.fact_check_rounded,
      _ReceiptReadStatusKind.warning => Icons.warning_amber_rounded,
      _ReceiptReadStatusKind.failed => Icons.error_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF10171A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFFD166),
                  ),
                )
              : Icon(icon, color: accent, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveStatus == _ReceiptReadStatusKind.reading
                        ? accent
                        : const Color(0xFFE8ECEE),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recoveryHint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                    letterSpacing: 0,
                  ),
                ),
                if (reading && uiConfig.showReadProgressSteps) ...[
                  const SizedBox(height: 8),
                  _ReceiptReadProgressSteps(
                    phase: progressPhase,
                    uiConfig: uiConfig,
                  ),
                ],
                if (effectiveStatus == _ReceiptReadStatusKind.failed &&
                    (onRetry != null || onContinueManually != null)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onRetry != null)
                        OutlinedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: Text(
                            uiConfig.readStatusLabel(
                              'retryAction',
                              'Review Photos And Retry',
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE8ECEE),
                            side: BorderSide(color: accent),
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      if (onContinueManually != null)
                        TextButton.icon(
                          onPressed: onContinueManually,
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: Text(
                            uiConfig.readStatusLabel(
                              'manualRecoveryAction',
                              'Continue Manually',
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFE8ECEE),
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptReadProgressSteps extends StatelessWidget {
  const _ReceiptReadProgressSteps({
    required this.phase,
    required this.uiConfig,
  });

  final _ReceiptReadProgressPhase phase;
  final ReceiptCaptureUiConfig uiConfig;

  @override
  Widget build(BuildContext context) {
    const phases = [
      _ReceiptReadProgressPhase.accepted,
      _ReceiptReadProgressPhase.readingText,
      _ReceiptReadProgressPhase.openingDetails,
    ];
    final labels = [
      uiConfig.progressAcceptedLabel,
      uiConfig.progressReadingLabel,
      uiConfig.progressOpeningLabel,
    ];
    final current = phases.indexOf(phase).clamp(0, phases.length - 1);
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Text(
              labels[index],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: index <= current
                    ? const Color(0xFFFFD166)
                    : const Color(0xFF8FA0A8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1.12,
                letterSpacing: 0,
              ),
            ),
          ),
          if (index < labels.length - 1)
            Container(width: 10, height: 1, color: const Color(0xFF526168)),
        ],
      ],
    );
  }
}

class _ReceiptProofRemovalSheet extends StatelessWidget {
  const _ReceiptProofRemovalSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
