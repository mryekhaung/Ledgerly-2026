import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/data_transfer/data/csv/csv_codec.dart';

void main() {
  const codec = CsvCodec();

  group('CsvCodec', () {
    test('encodes and decodes simple flat rows', () {
      final input = [
        ['Date', 'Category', 'Amount', 'Currency', 'Direction', 'Note'],
        ['2026-10-14', 'Food', '5000', 'MMK', 'expense', 'Lunch'],
        ['2026-10-15', 'Salary', '500000', 'MMK', 'income', 'Monthly payout'],
      ];

      final encoded = codec.encode(input);
      final decoded = codec.decode(encoded);

      expect(decoded, equals(input));
    });

    test('properly handles commas inside cells', () {
      final input = [
        ['Item', 'Description'],
        ['Coffee', 'Hot, with sugar, milk'],
      ];

      final encoded = codec.encode(input);
      expect(encoded, contains('"Hot, with sugar, milk"'));

      final decoded = codec.decode(encoded);
      expect(decoded, equals(input));
    });

    test(
      'properly handles quotes inside cells with RFC 4180 escaping ("")',
      () {
        final input = [
          ['Quote', 'Author'],
          ['He said "Hello World"', 'Author'],
        ];

        final encoded = codec.encode(input);
        expect(encoded, contains('"He said ""Hello World"""'));

        final decoded = codec.decode(encoded);
        expect(decoded, equals(input));
      },
    );

    test('properly handles newlines within a quoted cell', () {
      final input = [
        ['Address', 'City'],
        ['123 Main Street\nApt 4B', 'Yangon'],
      ];

      final encoded = codec.encode(input);
      final decoded = codec.decode(encoded);

      expect(decoded, equals(input));
      expect(decoded[1][0], equals('123 Main Street\nApt 4B'));
    });

    test('handles empty input gracefully', () {
      expect(codec.decode(''), isEmpty);
      expect(codec.decode('   \n\r\n  '), isEmpty);
    });
  });
}
