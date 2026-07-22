import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_pdf_text_decoder.dart';

void main() {
  test('PDF text decoder reads UTF-16 big-endian hex receipt text', () {
    final decoded = AppPdfTextDecoder.decodedHexStrings(
      '<FEFF0053005500420054004F00540041004C002000310032002E00330034>',
    );

    expect(decoded, contains('SUBTOTAL 12.34'));
  });

  test('PDF text decoder reads UTF-16 little-endian hex receipt text', () {
    final decoded = AppPdfTextDecoder.decodedHexStrings(
      '<FFFE53005500420054004F00540041004C002000310032002E0033003400>',
    );

    expect(decoded, contains('SUBTOTAL 12.34'));
  });

  test('PDF text decoder rejects binary UTF-16 hex payloads', () {
    final decoded = AppPdfTextDecoder.decodedHexStrings('<FEFF000100020003>');

    expect(decoded, isEmpty);
  });
}
