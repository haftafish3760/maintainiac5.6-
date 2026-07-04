import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_pdf_text_decoder.dart';

import 'helpers/pdf_security_fixture_factory.dart';

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

  test('shared PDF text decoder extracts FlateDecode stream text', () {
    final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(
      PdfSecurityFixtureFactory.flateStreamPdf(
        PdfSecurityFixtureFactory.flateDecodedProbeText(),
      ),
    );

    expect(decoded, contains('/JavaScript'));
    expect(decoded, contains('VIN 1HGCM82633A004352'));
  });

  test('shared PDF text decoder extracts ToUnicode CMap glyph text', () {
    final decoded = AppPdfTextDecoder.withDecodedHexStrings(
      '/CIDInit/ProcSet findresource begin\n'
      '12 dict begin\n'
      'begincmap\n'
      '5 beginbfchar\n'
      '<0029> <0024>\n'
      '<002A> <0031>\n'
      '<002B> <0038>\n'
      '<0034> <0031>\n'
      '<0035> <0035>\n'
      'endbfchar\n'
      '1 beginbfrange\n'
      '<002C> <002D> [<0036> <002E>]\n'
      'endbfrange\n'
      'endcmap\n'
      'BT <0029002A002B002C002D002A00340035> Tj ET',
    );

    expect(decoded, contains(r'$186.1'));
  });

  test('shared PDF text decoder ignores broken FlateDecode streams safely', () {
    final decoded = AppPdfTextDecoder.textWithDecodedPdfStreams(
      PdfSecurityFixtureFactory.brokenFlateStreamPdf('not really compressed'),
    );

    expect(decoded, contains('%PDF-1.7'));
    expect(decoded, isNot(contains('VIN 1HGCM82633A004352')));
  });
}
