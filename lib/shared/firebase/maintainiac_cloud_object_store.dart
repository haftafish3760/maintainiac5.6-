import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Module-neutral binary transfer boundary owned by shared Firebase code.
abstract interface class MaintainiacCloudObjectStore {
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  });

  Future<Uint8List> download({required String path, required int maxBytes});
}

class FirebaseMaintainiacCloudObjectStore
    implements MaintainiacCloudObjectStore {
  FirebaseMaintainiacCloudObjectStore({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    required Map<String, String> metadata,
  }) async {
    await _storage
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(contentType: contentType, customMetadata: metadata),
        );
  }

  @override
  Future<Uint8List> download({
    required String path,
    required int maxBytes,
  }) async {
    final bytes = await _storage.ref(path).getData(maxBytes);
    if (bytes == null) throw StateError('Cloud object is unavailable.');
    return bytes;
  }
}
