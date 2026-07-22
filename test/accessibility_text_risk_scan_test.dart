import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/accessibility_text_risk_scan.dart';

void main() {
  test(
    'accessibility scan groups candidates without calling them defects',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'a11y_text_scan_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final screen = File('${directory.path}/screens/jobs/jobs_screen.dart');
      await screen.parent.create(recursive: true);
      await screen.writeAsString('''
Text('Job', maxLines: 1, overflow: TextOverflow.ellipsis);
FittedBox(child: Text('Total'));
''');

      final report = await scanAccessibilityTextRisks(directory);

      expect(report.filesScanned, 1);
      expect(report.filesWithRisks, 1);
      expect(report.globalOverrideCount, 0);
      expect(report.countsByKind['single_line_limit'], 1);
      expect(report.countsByKind['ellipsis_overflow'], 1);
      expect(report.countsByKind['fitted_box_text_risk'], 1);
      expect(report.toMarkdown(), contains('not a defect count'));
    },
  );

  test('accessibility scan reports global scaling overrides', () async {
    final directory = await Directory.systemTemp.createTemp('a11y_override_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final app = File('${directory.path}/app.dart');
    await app.writeAsString('TextScaler.noScaling;');

    final report = await scanAccessibilityTextRisks(directory);

    expect(report.globalOverrideCount, 1);
    expect(report.countsByKind['global_text_scale_disabled'], 1);
  });
}
