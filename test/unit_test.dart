import 'package:flutter_test/flutter_test.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:calculator/main.dart';

String calculateExpression(String rawInput) {
  if (rawInput.trim().isEmpty) return '';

  String input = rawInput;

  while (input.isNotEmpty &&
      (input.endsWith('÷') ||
          input.endsWith('×') ||
          input.endsWith('–') ||
          input.endsWith('-') ||
          input.endsWith('+') ||
          input.endsWith('*') ||
          input.endsWith('/') ||
          input.endsWith('√') ||
          input.endsWith('^'))) {
    input = input.substring(0, input.length - 1);
  }

  if (input.isEmpty) return '';

  final int openBracket = input.split('(').length - 1;
  final int closeBracket = input.split(')').length - 1;
  if (openBracket > closeBracket && input != '(') {
    input = input + (')' * (openBracket - closeBracket));
  }

  input = input.replaceAll('×', '*');
  input = input.replaceAll('÷', '/');
  input = input.replaceAll('–', '-');
  input = input.replaceAll(')(', ')*(');

  input = input.replaceAllMapped(
      RegExp(r'㏒₂\(([^)]+)\)'), (m) => 'log(2, ${m.group(1)})');
  input = input.replaceAllMapped(
      RegExp(r'㏒\(([^)]+)\)'), (m) => 'log(10, ${m.group(1)})');
  input = input.replaceAll('㏑', 'ln');

  input = input.replaceAllMapped(
      RegExp(r'(\d+|\))\s*√'), (m) => '${m.group(1)}*√');
  input = input.replaceAllMapped(
      RegExp(r'√\(([^)]+)\)'), (m) => 'sqrt(${m.group(1)})');
  input = input.replaceAllMapped(
      RegExp(r'√(\d+(\.\d+)?)'), (m) => 'sqrt(${m.group(1)})');
  input = input.replaceAllMapped(
      RegExp(r'√([a-zA-Z]+)'), (m) => 'sqrt(${m.group(1)})');
  input = input.replaceAll('√', 'sqrt');

  input = input.replaceAllMapped(
      RegExp(r'(\d+(\.\d+)?)\('), (m) => '${m.group(1)}*(');
  input = input.replaceAllMapped(
      RegExp(r'\)(\d+(\.\d+)?)'), (m) => ')*${m.group(1)}');
  input = input.replaceAllMapped(
      RegExp(r'(\d+(\.\d+)?)(log|ln|sqrt)'),
      (m) => '${m.group(1)}*${m.group(3)}');
  input = input.replaceAllMapped(
      RegExp(r'!(\d+|\(|log|ln|sqrt)'), (m) => '!*${m.group(1)}');

  input = input.replaceAllMapped(
      RegExp(r'(\d+(\.\d+)?|\))e'), (m) => '${m.group(1)}*e');
  input = input.replaceAllMapped(
      RegExp(r'e(\d+|\(|log|ln|sqrt)'), (m) => 'e^1*${m.group(1)}');
  input = input.replaceAllMapped(
      RegExp(r'e(?!\^)'), (m) => 'e^1');

  input = input.replaceAll('(*', '(');
  if (input.startsWith('*')) {
    input = input.substring(1);
  }

  try {
    final Parser p = Parser();
    final Expression exp = p.parse(input);
    final ContextModel cm = ContextModel();
    final double eval = exp.evaluate(EvaluationType.REAL, cm);

    return Home.formatResult(eval);
  } catch (_) {
    return 'Error';
  }
}

String removeTrailingZeros(String value) {
  if (!value.contains('.')) return value;
  int i = value.length - 1;
  while (i >= 0 && value[i] == '0') {
    i--;
  }
  if (i >= 0 && value[i] == '.') {
    i--;
  }
  return value.substring(0, i + 1);
}

void main() {
  group('Calculator Math and Parsing Tests', () {
    test('Standard operations', () {
      expect(calculateExpression('2+3'), '5');
      expect(calculateExpression('7–4'), '3');
      expect(calculateExpression('6×7'), '42');
      expect(calculateExpression('8÷2'), '4');
      expect(calculateExpression('0.1+0.2'), '0.3');
    });

    test('Division by zero', () {
      expect(calculateExpression('5÷0'), 'Infinity');
      expect(calculateExpression('–5÷0'), '-Infinity');
      expect(calculateExpression('0÷0'), 'Keep it real');
    });

    test('Roots and powers', () {
      expect(calculateExpression('√(9)'), '3');
      expect(calculateExpression('√9'), '3');
      expect(calculateExpression('√16+5'), '9');
      expect(calculateExpression('5√4'), '10');
      expect(calculateExpression('2^(3)'), '8');
      expect(calculateExpression('√(-4)'), 'Keep it real');
    });

    test('Factorials', () {
      expect(calculateExpression('5!'), '120');
      expect(calculateExpression('(3+2)!'), '120');
    });

    test('Euler number e and logs', () {
      expect(calculateExpression('e+5'), startsWith('7.71828'));
      expect(calculateExpression('2e'), startsWith('5.43656'));
      expect(calculateExpression('123e'), startsWith('334.348'));
      expect(calculateExpression('㏑(e)'), '1');
      expect(calculateExpression('㏒(100)'), '2');
      expect(calculateExpression('㏒₂(8)'), '3');
      expect(calculateExpression('㏒(100)+㏒(10)'), '3');
      expect(calculateExpression('25㏒(10)'), '25');
    });

    test('Implicit multiplication & brackets', () {
      expect(calculateExpression('5(2+3)'), '25');
      expect(calculateExpression('(2+3)5'), '25');
      expect(calculateExpression('(2+3'), '5');
    });
  });

  group('Base Converter BigInt Tests', () {
    test('Binary conversion', () {
      final val = BigInt.tryParse('1101', radix: 2);
      expect(val, isNotNull);
      expect(val!.toRadixString(10), '13');
      expect(val.toRadixString(16).toUpperCase(), 'D');
      expect(val.toRadixString(8), '15');
    });

    test('Large Hex conversion beyond 64-bit int', () {
      const bigHex = '123456789ABCDEF0123456789';
      final bigVal = BigInt.tryParse(bigHex, radix: 16);
      expect(bigVal, isNotNull);
      expect(bigVal!.toRadixString(16).toUpperCase(), bigHex);
    });

    test('Large Hex with sanitation (spaces, commas, prefixes)', () {
      String cleanHex(String input) {
        String s = input.trim().replaceAll(',', '').replaceAll(' ', '').replaceAll('_', '');
        if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
        return s;
      }

      const raw = '0x1234, 5678 9ABC DEF0 1234 5678 9';
      final cleaned = cleanHex(raw);
      final val = BigInt.tryParse(cleaned, radix: 16);
      expect(val, isNotNull);
      expect(val!.toRadixString(16).toUpperCase(), '123456789ABCDEF0123456789');
      expect(val.toRadixString(10), isNotEmpty);
      expect(val.toRadixString(2), isNotEmpty);
    });
  });

  group('Result formatting and scientific notation e+ tests', () {
    test('Numbers up to 12 digits stay formatted as Indian integers without e', () {
      expect(Home.formatResult(0.0), '0');
      expect(Home.formatResult(100.0), '100');
      expect(Home.formatResult(1000.0), '1,000');
      expect(Home.formatResult(10000.0), '10,000');
      expect(Home.formatResult(100000000.0), '10,00,00,000');
      expect(Home.formatResult(999999999.0), '99,99,99,999');
      expect(Home.formatResult(1000000000.0), '1,00,00,00,000');
      expect(Home.formatResult(10000000000.0), '10,00,00,00,000');
      expect(Home.formatResult(100000000000.0), '1,00,00,00,00,000');
    });

    test('Threshold switches >= 1e12 to e+ notation with reduced decimal precision', () {
      expect(Home.formatResult(1000000000000.0), '1e+12');
      // Screenshot 1 case: 9,999 * 9,999 * 999 * 999 = 99,780,140,978,001 (14 digits)
      final res1 = Home.formatResult(9999.0 * 9999 * 999 * 999);
      expect(res1, '9.97801e+13');
      expect(res1.length, lessThanOrEqualTo(12));

      // Screenshot 2 case: 9,999 * 9,999 * 999 * 999 * 99 = 9,878,233,956,822,099 (16 digits)
      final res2 = Home.formatResult(9999.0 * 9999 * 999 * 999 * 99);
      expect(res2, '9.87823e+15');
      expect(res2.length, lessThanOrEqualTo(12));
    });

    test('Scientific decimal precision reduces for large exponents and negative values', () {
      // 2-digit exponent: reduced to 5 decimals
      expect(Home.formatResult(1.23456789e13), '1.23457e+13');
      expect(Home.formatResult(1.23456789e25), '1.23457e+25');

      // 3-digit exponent: reduced to 4 decimals
      expect(Home.formatResult(1.23456789e120), '1.2346e+120');

      // Negative sign: reduced precision by 1 to maintain max width <= 12 chars
      final negRes = Home.formatResult(-(9999.0 * 9999 * 999 * 999 * 99));
      expect(negRes, '-9.8782e+15');
      expect(negRes.length, lessThanOrEqualTo(12));
    });

    test('Small numbers < 1e-6 use e- notation with reduced precision', () {
      expect(Home.formatResult(1e-7), '1e-7');
      expect(Home.formatResult(1.2345678e-7), '1.234568e-7');
      expect(Home.formatResult(0.00001), '0.00001');
    });

    test('Decimals cap length within 15 characters', () {
      expect(Home.formatResult(1.0 / 3.0), '0.33333333');
      expect(Home.formatResult(12345.6789), '12,345.6789');
      expect(Home.formatResult(123456.78912345), '1,23,456.789123');
      expect(Home.formatResult(12345678.9), '1,23,45,678.9');
    });
  });
}
