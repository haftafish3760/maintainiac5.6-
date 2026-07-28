import 'dart:io';

class IosReceiptCameraBridgeSources {
  IosReceiptCameraBridgeSources({
    required this.appDelegate,
    required this.cameraController,
    required this.xcodeProject,
  });

  final String appDelegate;
  final String cameraController;
  final String xcodeProject;
}

Future<IosReceiptCameraBridgeSources>
readIosReceiptCameraBridgeSources() async {
  return IosReceiptCameraBridgeSources(
    appDelegate: await File('ios/Runner/AppDelegate.swift').readAsString(),
    cameraController: await readIosReceiptCameraUnit(),
    xcodeProject: await File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsString(),
  );
}

Future<String> readIosReceiptCameraUnit() async {
  final directory = Directory('ios/Runner');
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) {
            final name = file.uri.pathSegments.last;
            return (name.startsWith('ReceiptCameraViewController') ||
                    name.startsWith('ReceiptCameraFullScreenSettings')) &&
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
