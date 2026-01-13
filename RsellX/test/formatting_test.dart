import 'package:flutter_test/flutter_test.dart';
import 'package:RsellX/utils/formatting.dart';

void main() {
  group('Formatter Tests', () {
    test('parseDouble parses simple number', () {
      expect(Formatter.parseDouble('123'), 123.0);
    });

    test('parseDouble parses comma separated number', () {
      expect(Formatter.parseDouble('1,234'), 1234.0);
    });

    test('parseDouble parses currency string', () {
      expect(Formatter.parseDouble('Rs 1,234.50'), 1234.50);
    });

    test('parseInt parses simple integer', () {
      expect(Formatter.parseInt('123'), 123);
    });

    test('parseInt handles non-numeric characters', () {
      expect(Formatter.parseInt('12abc3'), 123);
    });
  });
}
