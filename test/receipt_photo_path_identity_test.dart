import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_path_identity.dart';

void main() {
  test('receipt photo path identity rejects blanks padding and aliases', () {
    expect(normalizedReceiptPhotoPath(''), isNull);
    expect(normalizedReceiptPhotoPath(' /tmp/receipt/top.jpg'), isNull);
    expect(
      normalizedReceiptPhotoPath('/tmp/receipt/../receipt/top.jpg'),
      isNull,
    );
    expect(
      normalizedReceiptPhotoPath('/tmp/receipt/top.jpg'),
      '/tmp/receipt/top.jpg',
    );
  });

  test('unique receipt photo paths remove duplicate normalized sections', () {
    final paths = uniqueNormalizedReceiptPhotoPaths(const [
      '/tmp/receipt/top.jpg',
      '/tmp/receipt/top.jpg',
      '/tmp/receipt/../receipt/top.jpg',
      '/tmp/receipt/bottom.jpg',
    ]);

    expect(paths, const ['/tmp/receipt/top.jpg', '/tmp/receipt/bottom.jpg']);
    expect(receiptPhotoPathsAreUniqueAndNormalized(paths), isTrue);
    expect(
      receiptPhotoPathsAreUniqueAndNormalized(const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/../receipt/top.jpg',
      ]),
      isFalse,
    );
  });
}
