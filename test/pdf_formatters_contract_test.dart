import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_pdf_formatters.dart';

void main() {
  test('PDF money formatting is cent safe and deterministic', () {
    expect(AppPdfFormatters.money(0), r'$0.00');
    expect(AppPdfFormatters.money(0.1 + 0.2), r'$0.30');
    expect(AppPdfFormatters.money(1.005), r'$1.01');
    expect(AppPdfFormatters.money(2.675), r'$2.68');
    expect(AppPdfFormatters.money(19.995), r'$20.00');
    expect(AppPdfFormatters.money(-1.005), r'-$1.01');
    expect(AppPdfFormatters.money(-5.555), r'-$5.56');
    expect(AppPdfFormatters.moneyCents(123456), r'$1234.56');
    expect(AppPdfFormatters.moneyCents(-42), r'-$0.42');
  });

  test('PDF date and quantity formatting stay compact and stable', () {
    expect(AppPdfFormatters.date(DateTime(2026, 7, 4)), '7/4/2026');
    expect(AppPdfFormatters.quantity(3), '3');
    expect(AppPdfFormatters.quantity(3.5), '3.50');
    expect(AppPdfFormatters.quantity(-1.25), '-1.25');
  });

  test('PDF file size formatting is deterministic and readable', () {
    expect(AppPdfFormatters.fileSize(-1), '0 bytes');
    expect(AppPdfFormatters.fileSize(0), '0 bytes');
    expect(AppPdfFormatters.fileSize(1), '1 byte');
    expect(AppPdfFormatters.fileSize(1023), '1023 bytes');
    expect(AppPdfFormatters.fileSize(1024), '1 KB');
    expect(AppPdfFormatters.fileSize(1025), '2 KB');
    expect(AppPdfFormatters.fileSize(1536), '2 KB');
    expect(AppPdfFormatters.fileSize(1024 * 1024), '1.0 MB');
    expect(AppPdfFormatters.fileSize(12 * 1024 * 1024), '12 MB');
  });
}
