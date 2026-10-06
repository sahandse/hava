import 'package:flutter_test/flutter_test.dart';
import 'package:hava/core/format/persian_digits.dart';

void main() {
  test('converts Latin digits to Persian digits', () {
    expect(toPersianDigits('2026'), '۲۰۲۶');
  });
}
