import 'package:flutter_test/flutter_test.dart';

import 'package:fixly/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('PAN accepts valid individual format', () {
      expect(Validators.pan('ABCPX1234F'), isNull);
    });

    test('PAN rejects invalid 4th letter', () {
      expect(Validators.pan('ABCDX1234F'), isNotNull);
    });

    test('phone requires 10 digits', () {
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('123'), isNotNull);
    });
  });
}
