import 'dart:io';

class AndroidReceiptCameraBridgeSources {
  AndroidReceiptCameraBridgeSources({
    required this.activity,
    required this.cameraActivity,
    required this.importActions,
    required this.captureFlow,
    required this.imagePicker,
    required this.gradle,
    required this.manifest,
  });

  final String activity;
  final String cameraActivity;
  final String importActions;
  final String captureFlow;
  final String imagePicker;
  final String gradle;
  final String manifest;
}

Future<AndroidReceiptCameraBridgeSources>
readAndroidReceiptCameraBridgeSources() async {
  return AndroidReceiptCameraBridgeSources(
    activity: await File(
      'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt',
    ).readAsString(),
    cameraActivity: await readAndroidReceiptCameraUnit(),
    importActions: await readDartLibraryWithParts(
      'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
    ),
    captureFlow: await readDartLibraryWithParts(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
    ),
    imagePicker: await File(
      'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
    ).readAsString(),
    gradle: await File('android/app/build.gradle.kts').readAsString(),
    manifest: await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString(),
  );
}

Future<String> readAndroidReceiptCameraUnit() async {
  final directory = Directory('android/app/src/main/kotlin/com/maintainiac');
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where(
            (file) => file.uri.pathSegments.last.startsWith('ReceiptCamera'),
          )
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  final contents = <String>[];
  for (final file in files) {
    contents.add(await file.readAsString());
  }
  return contents.join('\n');
}

Future<String> readIosReceiptCameraUnit() async {
  final directory = Directory('ios/Runner');
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) {
            final name = file.uri.pathSegments.last;
            return name.startsWith('ReceiptCameraViewController') &&
                name.endsWith('.swift');
          })
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  final contents = <String>[];
  for (final file in files) {
    contents.add(await file.readAsString());
  }
  return contents.join('\n');
}

Future<String> readDartLibraryWithParts(String entryPath) async {
  final entryFile = File(entryPath);
  final entry = await entryFile.readAsString();
  final directory = entryFile.parent.path;
  final contents = <String>[entry];
  final partPattern = RegExp(r"^part '([^']+)';", multiLine: true);
  for (final match in partPattern.allMatches(entry)) {
    contents.add(await File('$directory/${match.group(1)}').readAsString());
  }
  return contents.join('\n');
}
