import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class PdfSecurityFixtureFactory {
  const PdfSecurityFixtureFactory._();

  static Uint8List rawPdf(String body) {
    return Uint8List.fromList(
      latin1.encode(
        '%PDF-1.7\n$body\nxref\ntrailer << /Root 1 0 R >>\nstartxref\n0\n%%EOF',
      ),
    );
  }

  static Uint8List flateStreamPdf(String streamText) {
    final stream = zlib.encode(latin1.encode(streamText));
    return Uint8List.fromList([
      ...latin1.encode('%PDF-1.7\n9 0 obj << /Filter /FlateDecode >> stream\n'),
      ...stream,
      ...latin1.encode(
        '\nendstream endobj\nxref\ntrailer << /Root 1 0 R >>\nstartxref\n0\n%%EOF',
      ),
    ]);
  }

  static Uint8List brokenFlateStreamPdf(String streamText) {
    return Uint8List.fromList(
      latin1.encode(
        '%PDF-1.7\n'
        '9 0 obj << /Filter /FlateDecode >> stream\n'
        '$streamText\n'
        'endstream endobj\n'
        'xref\ntrailer << /Root 1 0 R >>\nstartxref\n0\n%%EOF',
      ),
    );
  }

  static String activeActionBody() {
    return '1 0 obj << /Type /Page /OpenAction 2 0 R /AA 3 0 R >> endobj\n'
        '2 0 obj << /JavaScript 4 0 R /Launch 5 0 R /EmbeddedFile 6 0 R /RichMedia 7 0 R /SubmitForm 8 0 R /URI (https://example.com) >> endobj\n'
        '3 0 obj << /AcroForm 9 0 R /XFA 10 0 R >> endobj';
  }

  static String escapedActiveNameBody() {
    return '1 0 obj << /Type /Page /Open#41ction 2 0 R /A#41 3 0 R >> endobj\n'
        '2 0 obj << /Java#53cript 4 0 R /Launch 5 0 R /Embedded#46ile 6 0 R /Rich#4Dedia 7 0 R /Submit#46orm 8 0 R /U#52I (https://example.com) >> endobj\n'
        '3 0 obj << /Acro#46orm 9 0 R /X#46A 10 0 R >> endobj';
  }

  static String formDataActionBody() {
    return '1 0 obj << /Type /Page /AA 2 0 R >> endobj\n'
        '2 0 obj << /S /ResetForm /Fields [3 0 R] >> endobj\n'
        '3 0 obj << /S /ImportData /F (submitted.fdf) >> endobj';
  }

  static String namedMediaActionBody() {
    return '1 0 obj << /Type /Page /AA 2 0 R >> endobj\n'
        '2 0 obj << /S /Named /N /Print /Rendition 3 0 R >> endobj\n'
        '3 0 obj << /Movie 4 0 R /Sound 5 0 R >> endobj';
  }

  static String remoteNavigationActionBody() {
    return '1 0 obj << /Type /Page /AA 2 0 R >> endobj\n'
        '2 0 obj << /S /URI /URI <68747470733a2f2f6578616d706c652e636f6d> >> endobj\n'
        '3 0 obj << /S /GoToR /F (other.pdf) >> endobj\n'
        '4 0 obj << /S /GoToE /T 5 0 R >> endobj';
  }

  static String compressedActiveActionBody() {
    return '1 0 obj << /OpenAction 2 0 R /AA 3 0 R >> endobj\n'
        '2 0 obj << /JavaScript 4 0 R /Launch 5 0 R >> endobj\n'
        '3 0 obj << /SubmitForm 6 0 R /URI (https://example.com) >> endobj';
  }

  static String privateExportText() {
    return 'Passenger: Jane Customer\n'
        'VIN 1HGCM82633A004352\n'
        '/Users/owner/Documents/private-receipt.pdf';
  }

  static String flateDecodedProbeText() {
    return 'BT /JavaScript (bad) Tj VIN 1HGCM82633A004352 ET';
  }
}
