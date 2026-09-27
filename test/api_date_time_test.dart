import 'package:flutter_test/flutter_test.dart';
import 'package:guangheng/core/utils/api_date_time.dart';

void main() {
  group('parseApiDateTime', () {
    test('treats legacy timezone-less backend timestamps as UTC', () {
      final value = parseApiDateTime('2026-09-26T18:26:21.702843');

      expect(value, isNotNull);
      expect(value!.toUtc(), DateTime.utc(2026, 9, 26, 18, 26, 21, 702, 843));
    });

    test('respects explicit UTC and offset timestamps', () {
      final utc = parseApiDateTime('2026-09-26T18:26:21Z');
      final offset = parseApiDateTime('2026-09-27T02:26:21+08:00');

      expect(utc!.toUtc(), DateTime.utc(2026, 9, 26, 18, 26, 21));
      expect(offset!.toUtc(), utc.toUtc());
    });

    test('returns null for absent or invalid timestamps', () {
      expect(parseApiDateTime(null), isNull);
      expect(parseApiDateTime(''), isNull);
      expect(parseApiDateTime('invalid'), isNull);
    });
  });

  test('calendar dates keep their original day', () {
    final value = parseApiDateRequired('2026-09-27');

    expect((value.year, value.month, value.day), (2026, 9, 27));
  });
}
