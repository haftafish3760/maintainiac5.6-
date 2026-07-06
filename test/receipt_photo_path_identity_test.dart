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

  test('receipt photo path membership uses normalized identity', () {
    expect(
      receiptPhotoPathSetContains(const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/bottom.jpg',
      ], '/tmp/receipt/top.jpg'),
      isTrue,
    );
    expect(
      receiptPhotoPathSetContains(const [
        '/tmp/receipt/top.jpg',
      ], '/tmp/receipt/../receipt/top.jpg'),
      isFalse,
    );
    expect(
      receiptPhotoPathSetContains(const [
        '/tmp/receipt/../receipt/top.jpg',
      ], '/tmp/receipt/top.jpg'),
      isFalse,
    );
  });

  test('receipt photo order matching uses normalized identity and order', () {
    expect(
      receiptPhotoPathOrderMatches(
        const ['/tmp/receipt/top.jpg', '/tmp/receipt/middle.jpg'],
        const ['/tmp/receipt/top.jpg', '/tmp/receipt/middle.jpg'],
      ),
      isTrue,
    );
    expect(
      receiptPhotoPathOrderMatches(
        const ['/tmp/receipt/top.jpg', '/tmp/receipt/middle.jpg'],
        const ['/tmp/receipt/middle.jpg', '/tmp/receipt/top.jpg'],
      ),
      isFalse,
    );
    expect(
      receiptPhotoPathOrderMatches(
        const ['/tmp/receipt/top.jpg', '/tmp/receipt/middle.jpg'],
        const ['/tmp/receipt/top.jpg', '/tmp/receipt/../receipt/middle.jpg'],
      ),
      isFalse,
    );
    expect(
      receiptPhotoPathOrderMatches(
        const ['/tmp/receipt/top.jpg'],
        const [' /tmp/receipt/top.jpg'],
      ),
      isFalse,
    );
  });
}
