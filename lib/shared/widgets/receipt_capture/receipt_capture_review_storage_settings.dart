part of 'receipt_attachment_panel.dart';

class _ReceiptDataSaverDefaultPicker extends StatelessWidget {
  const _ReceiptDataSaverDefaultPicker({required this.settings});

  final ReceiptCaptureSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final cloudAssistPlan = settings.defaultDataSaverCloudAssistPlan;
    final installChoice = settings.defaultDataSaverParserPackInstallChoice;
    final routingPlan = settings.defaultDataSaverParserPackRoutingPlan;
    final receiptBrain = settings.defaultDataSaverReceiptBrain;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Saved Receipt Proof Size',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose the default saved proof size for receipt photos. Smaller files save phone space and cloud backup storage. OCR still uses the clearest receipt source first.',
            style: TextStyle(
              color: Color(0xFFC7D0D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          const _ReceiptSettingsNote(
            icon: Icons.visibility_rounded,
            text:
                'You preview the actual saved proof after taking a photo. On the photo review screen, open Receipt Details And Saved Proof to see what this size looks like before keeping it.',
          ),
          const SizedBox(height: 6),
          _ReceiptSettingsNote(
            icon: Icons.photo_size_select_large_rounded,
            text: settings.defaultDataSaverProofTargetSummary,
          ),
          if (cloudAssistPlan.hasOptionalCloudAssist ||
              settings.defaultDataSaverShouldOfferOptionalLocalParserPacks) ...[
            const SizedBox(height: 6),
            _ReceiptSettingsNote(
              icon: Icons.cloud_queue_rounded,
              text: installChoice.userFacingDownloadChoiceLabel,
            ),
          ],
          const SizedBox(height: 6),
          _ReceiptSettingsNote(
            icon: Icons.memory_rounded,
            text: settings.defaultDataSaverReceiptCapabilitySummary,
          ),
          const SizedBox(height: 6),
          _ReceiptSettingsNote(
            icon: settings.defaultDataSaverCanRunBaseReceiptFlowLocallyNow
                ? Icons.offline_bolt_rounded
                : Icons.report_problem_rounded,
            text: settings.defaultDataSaverLocalOnlyReadinessSummary,
          ),
          const SizedBox(height: 6),
          _ReceiptSettingsNote(
            icon: Icons.mobile_friendly_rounded,
            text: settings.defaultDataSaverFirstInstallBoundarySummary,
          ),
          const SizedBox(height: 6),
          _ReceiptSettingsNote(
            icon: Icons.system_update_alt_rounded,
            text: settings
                .defaultDataSaverFootprintSummary
                .userFacingInstallChoiceSummary,
          ),
          const SizedBox(height: 6),
          _ReceiptSettingsNote(
            icon: Icons.inventory_2_rounded,
            text: settings
                .defaultDataSaverFootprintSummary
                .userFacingBaseVersusFullOfflineSummary,
          ),
          const SizedBox(height: 6),
          _ReceiptSettingsNote(
            icon: Icons.route_rounded,
            text: routingPlan.userFacingCategoryPackSummary,
          ),
          if (receiptBrain.userFacingStorageWarning.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _ReceiptSettingsNote(
              icon: Icons.sd_storage_rounded,
              text: receiptBrain.userFacingStorageWarning,
            ),
          ],
          if (settings.defaultDataSaverUsesDeviceRecommendation) ...[
            const SizedBox(height: 6),
            Text(
              'Current default: ${settings.deviceCapability.recommendedSpaceSavingLabel}.',
              style: const TextStyle(
                color: Color(0xFF9BA8AE),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ReceiptRecommendedDataSaverChoice(
                selected: settings.defaultDataSaverUsesDeviceRecommendation,
                onTap: settings.useRecommendedDataSaverLevel,
              ),
              for (final level in _receiptBackupLevels)
                _ReceiptDataSaverChoice(
                  level: level,
                  selected: settings.defaultDataSaverLevel == level,
                  onTap: () => settings.setDefaultDataSaverLevel(level),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static const _receiptBackupLevels = [
    ReceiptDataSaverLevel.light,
    ReceiptDataSaverLevel.balanced,
    ReceiptDataSaverLevel.strong,
    ReceiptDataSaverLevel.maximum,
  ];
}

class _ReceiptRecommendedDataSaverChoice extends StatelessWidget {
  const _ReceiptRecommendedDataSaverChoice({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: const Text('Recommended Size'),
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFD166),
      backgroundColor: const Color(0xFF172126),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF101416) : const Color(0xFFE8ECEE),
        fontWeight: FontWeight.w900,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFFFFD166) : const Color(0xFF526168),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }
}

class _ReceiptDataSaverChoice extends StatelessWidget {
  const _ReceiptDataSaverChoice({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ReceiptDataSaverLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _choiceLabel(level);
    final tooltip = _choiceTooltip(level);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label. $tooltip',
        child: ChoiceChip(
          selected: selected,
          label: Text(label),
          onSelected: (_) => onTap(),
          selectedColor: const Color(0xFFFFD166),
          backgroundColor: const Color(0xFF172126),
          labelStyle: TextStyle(
            color: selected ? const Color(0xFF101416) : const Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
          side: BorderSide(
            color: selected ? const Color(0xFFFFD166) : const Color(0xFF526168),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }

  static String _choiceLabel(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original => 'Original: Local only',
      ReceiptDataSaverLevel.light => 'High Quality: 500-700 KB',
      ReceiptDataSaverLevel.balanced => 'Normal: 200-300 KB',
      ReceiptDataSaverLevel.strong => 'Low Storage: 100-150 KB',
      ReceiptDataSaverLevel.maximum => 'Tiny Proof: 40-100 KB',
    };
  }

  static String _choiceTooltip(ReceiptDataSaverLevel level) {
    return switch (level) {
      ReceiptDataSaverLevel.original =>
        'Keeps the full photo only on this phone unless the user chooses otherwise.',
      ReceiptDataSaverLevel.light =>
        'Largest saved proof. Easiest to review, uses more phone and cloud space.',
      ReceiptDataSaverLevel.balanced =>
        'Everyday saved proof size. Good balance for review, phone space, and cloud backup.',
      ReceiptDataSaverLevel.strong =>
        'Smaller saved proof for tight phone storage or lower cloud backup use.',
      ReceiptDataSaverLevel.maximum =>
        'Smallest saved proof. Saves the most space, review it before keeping it.',
    };
  }
}
