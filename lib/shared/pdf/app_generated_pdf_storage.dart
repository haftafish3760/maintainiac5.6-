import 'dart:io';

import 'package:path/path.dart' as path;

import 'app_generated_pdf_models.dart';

class AppGeneratedPdfStorage {
  const AppGeneratedPdfStorage._();

  static const int maxCopyAttempts = 1000;

  static Future<File?> availableDestination({
    required Directory directory,
    required String requestedFileName,
  }) async {
    final fileName = AppGeneratedPdfFileName.clean(requestedFileName);
    final first = File(path.join(directory.path, fileName));
    if (await _isAvailable(first)) return first;

    final extension = path.extension(fileName);
    final baseName = path.basenameWithoutExtension(fileName);
    for (var index = 2; index < maxCopyAttempts; index += 1) {
      final candidate = File(
        path.join(directory.path, '$baseName-copy-$index$extension'),
      );
      if (await _isAvailable(candidate)) return candidate;
    }
    return null;
  }

  static Future<bool> _isAvailable(File file) async {
    if (await _entityExistsWithoutFollowingLinks(file.path)) return false;
    return !await _entityExistsWithoutFollowingLinks('${file.path}.partial');
  }

  static Future<bool> _entityExistsWithoutFollowingLinks(
    String entityPath,
  ) async {
    final type = await FileSystemEntity.type(entityPath, followLinks: false);
    return type != FileSystemEntityType.notFound;
  }
}
