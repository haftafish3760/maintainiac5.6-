import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_form_sections.dart';

void main() {
  test('formats a five-digit ZIP and optional ZIP+4', () {
    final formatter = UsZipCodeFormatter();

    expect(
      formatter
          .formatEditUpdate(const TextEditingValue(), _value('12345'))
          .text,
      '12345',
    );
    expect(
      formatter
          .formatEditUpdate(const TextEditingValue(), _value('123456789'))
          .text,
      '12345-6789',
    );
    expect(
      formatter
          .formatEditUpdate(const TextEditingValue(), _value('1234567890'))
          .text,
      '12345-6789',
    );
  });
}

TextEditingValue _value(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);
