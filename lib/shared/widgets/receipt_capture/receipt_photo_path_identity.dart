import 'dart:collection';

import 'package:path/path.dart' as path;

String? normalizedReceiptPhotoPath(String photoPath) {
  final trimmed = photoPath.trim();
  if (trimmed.isEmpty || trimmed != photoPath) return null;
  final normalized = path.normalize(trimmed);
  if (normalized != trimmed) return null;
  return normalized;
}

List<String> uniqueNormalizedReceiptPhotoPaths(Iterable<String> photoPaths) {
  final uniquePaths = <String>[];
  final seenPaths = <String>{};
  for (final photoPath in photoPaths) {
    final normalized = normalizedReceiptPhotoPath(photoPath);
    if (normalized == null) continue;
    if (seenPaths.add(normalized)) uniquePaths.add(normalized);
  }
  return UnmodifiableListView(uniquePaths);
}

bool receiptPhotoPathsAreUniqueAndNormalized(List<String> photoPaths) {
  final uniquePaths = uniqueNormalizedReceiptPhotoPaths(photoPaths);
  if (uniquePaths.length != photoPaths.length) return false;
  for (var index = 0; index < photoPaths.length; index++) {
    if (uniquePaths[index] != photoPaths[index]) return false;
  }
  return true;
}
