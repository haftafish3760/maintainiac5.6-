import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt capture flow does not silently enable Receipt Assist', () async {
    final settingsStore = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart',
    ).readAsString();
    final flowHelpers = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart',
    ).readAsString();
    final nativeSettings = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_settings.dart',
    ).readAsString();
    final nativeDescriptors = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_settings_descriptors.dart',
    ).readAsString();
    final androidSessionReader = await File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSessionArguments.kt',
    ).readAsString();
    final iosSessionReader = await File(
      'ios/Runner/ReceiptCameraViewControllerSessionArguments.swift',
    ).readAsString();
    final photoReviewScreen = await _readReceiptPhotoReviewSource();
    final readBoundarySource = await _readReceiptReadBoundarySource();

    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedReceiptFill, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedExpenses, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedMaterials, false)'),
    );
    expect(
      settingsStore,
      contains('_readBool(_Keys.appAssistedMaintenance, false)'),
    );
    expect(
      flowHelpers,
      contains('settings?.appAssistedEnabledFor(area) ?? false'),
    );
    expect(
      androidSessionReader,
      contains('intent.getBooleanExtra("assistedReceiptFill", false)'),
    );
    expect(
      iosSessionReader,
      contains('arguments["assistedReceiptFill"] as? Bool ?? false'),
    );
    expect(nativeSettings, contains('this.assistedReceiptFill = false'));
    expect(nativeDescriptors, contains('defaultEnabled: false'));
    expect(photoReviewScreen, contains('this.assistedReceiptFill = false'));
    expect(
      photoReviewScreen,
      contains('assistedReceiptFill: widget.assistedReceiptFill'),
    );
    expect(photoReviewScreen, isNot(contains('assistedReceiptFill: true')));
    expect(
      readBoundarySource,
      contains('assistedReceiptFill: _appAssistedReceiptFillEnabled'),
    );
    expect(flowHelpers, isNot(contains('area == null ? true')));
    expect(flowHelpers, isNot(contains('?? true)')));
    expect(readBoundarySource, contains('_appAssistedReceiptFillEnabled'));
    expect(
      readBoundarySource,
      contains('appAssistedEnabledFor(widget.area) ==\n        true'),
    );
    expect(
      readBoundarySource,
      isNot(contains('appAssistedEnabledFor(widget.area) != false')),
    );
    expect(
      readBoundarySource,
      isNot(contains('appAssistedEnabledFor(widget.area) == false')),
    );
  });

  test('first receipt camera choice stays assist-only before capture', () async {
    final firstUseSheet = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
    ).readAsString();
    final uiConfig = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_ui_config.dart',
    ).readAsString();
    final cameraActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
    ).readAsString();
    final settingsSheet =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_storage_settings.dart',
        ).readAsString();
    final importActions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
        ).readAsString();

    expect(firstUseSheet, contains('uiConfig.firstUseTitle'));
    expect(firstUseSheet, contains('uiConfig.firstUsePrompt'));
    expect(firstUseSheet, contains('uiConfig.enableAssistLabel'));
    expect(firstUseSheet, contains('uiConfig.manualEntryLabel'));
    expect(uiConfig, contains('class ReceiptCaptureUiConfig'));
    expect(
      uiConfig,
      contains(
        'Receipt Assist reads the accepted photo and suggests totals and lines. You review everything before saving.',
      ),
    );
    expect(
      importActions,
      contains(
        'enum _ReceiptFirstUseCameraAction { useReceiptAssist, manualEntry }',
      ),
    );
    expect(importActions, contains('_showFirstUseReceiptCameraIntro'));
    expect(
      importActions,
      contains('!settings.hasReceiptAssistChoiceFor(widget.area)'),
    );
    expect(
      importActions,
      contains('settings.setReceiptAssistChoiceMadeFor(widget.area, true)'),
    );

    expect(firstUseSheet, isNot(contains('Saved Receipt Proof Size')));
    expect(firstUseSheet, isNot(contains('Saved proof')));
    expect(firstUseSheet, isNot(contains('Compression')));
    expect(firstUseSheet, isNot(contains('compress')));
    expect(firstUseSheet, isNot(contains('storage')));
    expect(firstUseSheet, isNot(contains('Storage')));
    expect(firstUseSheet, isNot(contains('Cloud backup')));
    expect(firstUseSheet, isNot(contains('backup storage')));
    expect(firstUseSheet, isNot(contains('Original photo')));
    expect(firstUseSheet, isNot(contains('high quality')));
    expect(firstUseSheet, isNot(contains('maximum savings')));

    expect(settingsSheet, contains('Saved Proof Size'));
    expect(settingsSheet, contains('required this.hasSavedReceiptProof'));
    expect(settingsSheet, contains('if (!hasSavedReceiptProof) ...['));
    expect(
      settingsSheet,
      contains(
        'After a receipt photo is attached, the review screen shows the actual proof size',
      ),
    );
    expect(
      settingsSheet,
      contains('OCR still reads from the clearest source first'),
    );

    final introHelperStart = cameraActions.indexOf(
      'Future<bool> _showFirstUseReceiptCameraIntro',
    );
    final introHelperEnd = cameraActions.indexOf(
      'Future<void> _applyFirstUseReceiptAssistChoice',
      introHelperStart,
    );
    final introHelper = cameraActions.substring(
      introHelperStart,
      introHelperEnd,
    );

    expect(
      introHelper,
      contains('if (!mounted || action == null) return false;'),
    );
    expect(
      introHelper,
      contains('await _applyFirstUseReceiptAssistChoice(settings, action);'),
    );
    expect(
      introHelper,
      contains(
        'await settings.setReceiptAssistChoiceMadeFor(widget.area, true);',
      ),
    );
    expect(
      introHelper.indexOf(
        'await _applyFirstUseReceiptAssistChoice(settings, action);',
      ),
      lessThan(
        introHelper.indexOf(
          'await settings.setReceiptAssistChoiceMadeFor(widget.area, true);',
        ),
      ),
    );
    expect(
      introHelper.indexOf(
        'await settings.setReceiptAssistChoiceMadeFor(widget.area, true);',
      ),
      lessThan(introHelper.indexOf('return true;')),
    );

    final takePhotoStart = cameraActions.indexOf(
      'Future<void> takeReceiptPhoto',
    );
    final takePhotoEnd = cameraActions.indexOf(
      'Future<_MaintainiacNativeCameraPhotoOutcome>',
      takePhotoStart,
    );
    final takePhotoBlock = cameraActions.substring(
      takePhotoStart,
      takePhotoEnd,
    );
    expect(
      takePhotoBlock.indexOf(
        'final ready = await _showFirstUseReceiptCameraIntro(settings);',
      ),
      lessThan(
        takePhotoBlock.indexOf(
          'final nativeOutcome = await _takeMaintainiacNativeCameraPhoto(settings);',
        ),
      ),
    );
    expect(
      takePhotoBlock,
      contains(
        'if (!ready) {\n          await returnToReceiptImportOptions();\n          return;\n        }',
      ),
    );
    expect(
      takePhotoBlock.indexOf('await returnToReceiptImportOptions();'),
      lessThan(
        takePhotoBlock.indexOf(
          'final nativeOutcome = await _takeMaintainiacNativeCameraPhoto(settings);',
        ),
      ),
    );
  });
}

Future<String> _readReceiptReadBoundarySource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_panel_build.dart',
    'lib/shared/widgets/receipt_capture/receipt_pdf_import_sheets.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_text_document_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> _readReceiptPhotoReviewSource() async {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    'lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart',
    'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery.dart',
    'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}
