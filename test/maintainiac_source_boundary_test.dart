import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('source boundary scanner catches forbidden live-service code', () {
    final scanner = MaintainiacSourceBoundaryScanner.productionDefaults();
    final directory = Directory.systemTemp.createTempSync(
      'maintainiac_source_boundary_',
    );
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    File('${directory.path}/parser_contract.dart').writeAsStringSync('''
void unsafe() {
  FirebaseFirestore.instance;
  GoogleVision.call();
  MLKit.scan();
  CameraController();
}
''');

    final violations = scanner.scanDirectory(directory);

    expect(violations.map((violation) => violation.ruleId), {
      'no_live_firestore_in_qa',
      'no_google_vision_in_parser_qa',
      'no_mlkit_in_parser_qa',
      'no_camera_controller_in_parser_qa',
    });
    expect(violations.every((violation) => violation.line > 0), isTrue);
  });

  test('source boundary scanner honors allowed emulator paths', () {
    final scanner = MaintainiacSourceBoundaryScanner.productionDefaults();
    final directory = Directory.systemTemp.createTempSync(
      'maintainiac_source_boundary_allowed_',
    );
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    final allowed = Directory('${directory.path}/firebase_emulator_tests')
      ..createSync(recursive: true);
    File(
      '${allowed.path}/rules_test.dart',
    ).writeAsStringSync('final firestore = FirebaseFirestore.instance;');

    expect(scanner.scanDirectory(directory), isEmpty);
  });

  test('source boundary scanner catches OCR and camera package imports', () {
    final scanner = MaintainiacSourceBoundaryScanner.productionDefaults();
    final directory = Directory.systemTemp.createTempSync(
      'maintainiac_source_boundary_imports_',
    );
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    File('${directory.path}/parser_package_imports.dart').writeAsStringSync('''
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
''');

    final violations = scanner.scanDirectory(directory);

    expect(violations.map((violation) => violation.ruleId), {
      'no_camera_package_in_parser_qa',
      'no_google_mlkit_package_in_parser_qa',
    });
  });

  test('source boundary scanner skips generated build folders', () {
    final scanner = MaintainiacSourceBoundaryScanner.productionDefaults();
    final directory = Directory.systemTemp.createTempSync(
      'maintainiac_source_boundary_build_',
    );
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    final generated = Directory('${directory.path}/build/generated')
      ..createSync(recursive: true);
    File('${generated.path}/ignored.dart').writeAsStringSync(
      'GoogleVision MLKit CameraController FirebaseFirestore.instance',
    );

    expect(scanner.scanDirectory(directory), isEmpty);
  });
}
