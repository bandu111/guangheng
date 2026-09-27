/// Parses an API timestamp into the phone's local timezone.
///
/// GuangHeng historically stored UTC in SQLite without a timezone suffix.
/// Treating those values as local time caused an eight-hour offset in China.
/// Explicit offsets are still respected, so this remains compatible with the
/// corrected backend contract (`Z` or `+00:00`).
DateTime? parseApiDateTime(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty || raw == 'null') return null;

  final hasTime = raw.contains('T') || raw.contains(' ');
  final hasTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
  final normalized = hasTime && !hasTimezone ? '${raw}Z' : raw;
  return DateTime.tryParse(normalized)?.toLocal();
}

DateTime parseApiDateTimeRequired(Object? value) {
  final parsed = parseApiDateTime(value);
  if (parsed == null) {
    throw FormatException('Invalid API timestamp', value);
  }
  return parsed;
}

/// Parses a calendar date without applying a timezone conversion.
DateTime parseApiDateRequired(Object? value) {
  final raw = value?.toString().trim() ?? '';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) throw FormatException('Invalid API date', value);
  return DateTime(parsed.year, parsed.month, parsed.day);
}
