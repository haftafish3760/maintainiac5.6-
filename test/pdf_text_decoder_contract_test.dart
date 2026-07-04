import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_pdf_text_decoder.dart';

void main() {
  test('shared PDF text decoder extracts latin and UTF-16 hex strings', () {
    final decoded = AppPdfTextDecoder.decodedHexStrings(
      '<544F54414C2031322E3334>\n'
      '<FEFF00560049004E00200031004800470043004D003800320036003300330041003000300034003300350032>',
    );

    expect(decoded, contains('TOTAL 12.34'));
    expect(decoded, contains('VIN 1HGCM82633A004352'));
  });

  test('shared PDF text decoder skips binary payloads', () {
    final decoded = AppPdfTextDecoder.withDecodedHexStrings(
      '%PDF-1.7\n<FEFF000100020003>\n%%EOF',
    );

    expect(decoded, contains('%PDF-1.7'));
    expect(decoded, isNot(contains('VIN')));
    expect(AppPdfTextDecoder.decodedHexStrings(decoded), isEmpty);
  });
}
