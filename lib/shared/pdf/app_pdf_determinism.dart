import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class AppPdfDeterminism {
  const AppPdfDeterminism._();

  static Uint8List normalizeDocumentId(Uint8List bytes, String stableSeed) {
    final source = latin1.decode(bytes, allowInvalid: true);
    final documentId = sha256.convert(utf8.encode(stableSeed)).toString();
    final normalized = source.replaceFirstMapped(
      RegExp(r'/ID\s*\[\s*<([0-9a-fA-F]{64})>\s*<([0-9a-fA-F]{64})>\s*\]'),
      (_) => '/ID[<$documentId><$documentId>]',
    );
    if (identical(normalized, source) || normalized == source) {
      return Uint8List.fromList(bytes);
    }
    return Uint8List.fromList(latin1.encode(normalized));
  }
}
