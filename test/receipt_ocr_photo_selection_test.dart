import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  ReceiptAttachmentRecord photo(
    String id,
    int? quality, {
    List<String> documentSignals = const [],
  }) {
    return ReceiptAttachmentRecord(
      id: id,
      path: '/tmp/$id.jpg',
      kind: ReceiptAttachmentKind.photo,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 7, 14),
      photoQualityScore: quality,
      documentSignals: documentSignals,
    );
  }

  test('selects clearer photos without changing their capture order', () {
    final selected = prioritizeReceiptPhotosForOcr([
      photo('first-medium', 75),
      photo('second-low', 12),
      photo('third-high', 95),
    ], maximum: 2);

    expect(selected.map((item) => item.id), ['first-medium', 'third-high']);
  });

  test('keeps unknown-quality photos behind measured quality sources', () {
    final selected = prioritizeReceiptPhotosForOcr([
      photo('unknown', null),
      photo('measured', 40),
    ], maximum: 1);

    expect(selected.single.id, 'measured');
  });

  test('does not select any photo when assistance is off for the profile', () {
    expect(
      prioritizeReceiptPhotosForOcr([photo('photo', 90)], maximum: 0),
      isEmpty,
    );
  });

  test('keeps ordered receipt segments in capture order', () {
    final selected = prioritizeReceiptPhotosForOcr([
      photo('first', 12, documentSignals: const ['receipt_section_1']),
      photo('second', 95, documentSignals: const ['receipt_section_2']),
      photo('third', 90, documentSignals: const ['receipt_section_3']),
    ], maximum: 2);

    expect(selected.map((item) => item.id), ['first', 'second']);
  });
}
