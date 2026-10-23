import 'package:flutter_test/flutter_test.dart';
import 'package:math_expressions/math_expressions.dart';

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

    if (eval.isNaN) return 'Keep it real';
    if (eval == double.infinity) return 'Infinity';
    if (eval == double.negativeInfinity) return '-Infinity';

    if (eval == eval.roundToDouble() && eval.abs() < 1e14) {
      return eval.toInt().toString();
    }

    String str = eval.toStringAsPrecision(12);
    if (str.contains('e') || str.contains('E')) {
      final parts = str.toLowerCase().split('e');
      final mantissa = removeTrailingZeros(parts[0]);
      return '${mantissa}e${parts[1]}';
    }
    str = removeTrailingZeros(str);

    if (eval.abs() >= 1e12 || (eval.abs() > 0 && eval.abs() < 1e-7)) {
      final expStr = eval.toStringAsExponential(6);
      final parts = expStr.toLowerCase().split('e');
      final mantissa = removeTrailingZeros(parts[0]);
      return '${mantissa}e${parts[1]}';
    }

    return str;
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
}
