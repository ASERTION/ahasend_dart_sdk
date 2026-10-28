// Internal helpers for decoding and encoding JSON payloads.
//
// Every model in `lib/src/models` uses these helpers so that decoding
// behaves the same everywhere: missing optional fields become `null`,
// timestamps are parsed as RFC 3339, and lists are unmodifiable.
//
// Models encode with null-aware map entries (`'name': ?name`), so `null`
// fields are left out of the JSON.

/// A decoded JSON object.
typedef JsonMap = Map<String, Object?>;

/// Casts [value] to a [JsonMap]. Throws a [FormatException] for other types.
JsonMap asJsonMap(Object? value) => switch (value) {
  final Map<String, Object?> map => map,
  final Map<Object?, Object?> map => map.cast<String, Object?>(),
  _ => throw FormatException(
    'Expected a JSON object, got ${value.runtimeType}',
  ),
};

/// Returns `null` for `null`, otherwise casts with [asJsonMap].
JsonMap? asJsonMapOrNull(Object? value) =>
    value == null ? null : asJsonMap(value);

/// Decodes a list of objects with [fromJson]. `null` becomes an empty list.
List<T> decodeList<T>(Object? value, T Function(JsonMap json) fromJson) {
  if (value == null) return const [];
  return List.unmodifiableOf([
    for (final item in value as List<Object?>) fromJson(asJsonMap(item)),
  ]);
}

/// Decodes a list of objects, keeping `null` when the field is absent.
List<T>? decodeListOrNull<T>(
  Object? value,
  T Function(JsonMap json) fromJson,
) => value == null ? null : decodeList(value, fromJson);

/// Decodes a list of scalars (strings, numbers, booleans).
List<T> decodeScalarList<T>(Object? value) {
  if (value == null) return const [];
  return List.unmodifiableOf([
    for (final item in value as List<Object?>) item as T,
  ]);
}

/// Decodes a list of scalars, keeping `null` when the field is absent.
List<T>? decodeScalarListOrNull<T>(Object? value) =>
    value == null ? null : decodeScalarList<T>(value);

/// Decodes a map of strings.
Map<String, String>? decodeStringMapOrNull(Object? value) {
  if (value == null) return null;
  return Map.unmodifiableOf({
    for (final MapEntry(:key, :value) in asJsonMap(value).entries)
      key: value as String,
  });
}

/// Parses an RFC 3339 timestamp.
DateTime decodeDateTime(Object? value) {
  final text = value as String;
  return parseRfc3339(text) ?? DateTime.parse(text);
}

/// Parses an RFC 3339 timestamp, or returns `null` for `null` or `''`.
DateTime? decodeDateTimeOrNull(Object? value) =>
    value == null || value == '' ? null : decodeDateTime(value);

/// Reads an integer that may have been encoded as a JSON float.
int decodeInt(Object? value) => (value as num).toInt();

/// Reads an integer that may have been encoded as a JSON float, or `null`.
int? decodeIntOrNull(Object? value) => (value as num?)?.toInt();

/// Reads a number as a [double].
double decodeDouble(Object? value) => (value as num).toDouble();

/// Reads a number as a [double], or `null`.
double? decodeDoubleOrNull(Object? value) => (value as num?)?.toDouble();

/// Encodes a timestamp as RFC 3339 in UTC.
String encodeDateTime(DateTime value) => value.toUtc().toIso8601String();

/// Encodes a timestamp as RFC 3339 in UTC, or returns `null`.
String? encodeDateTimeOrNull(DateTime? value) =>
    value == null ? null : encodeDateTime(value);

/// Parses the RFC 3339 profile the API uses, much faster than
/// [DateTime.parse]: `YYYY-MM-DDTHH:MM:SS[.fraction](Z|±HH:MM)`.
///
/// Returns `null` for any other format; callers then fall back to
/// [DateTime.parse]. Out-of-range fields are normalized the same way
/// [DateTime.parse] does it. Fractions beyond microseconds are truncated.
DateTime? parseRfc3339(String s) {
  final length = s.length;
  if (length < 20) return null;
  final year = _digits(s, 0, 4);
  final month = _digits(s, 5, 2);
  final day = _digits(s, 8, 2);
  final hour = _digits(s, 11, 2);
  final minute = _digits(s, 14, 2);
  final second = _digits(s, 17, 2);
  // No bitwise OR here: on the web it yields unsigned 32-bit results.
  if (year < 0 ||
      month < 0 ||
      day < 0 ||
      hour < 0 ||
      minute < 0 ||
      second < 0) {
    return null;
  }
  final t = s.codeUnitAt(10);
  if (s.codeUnitAt(4) != _dash ||
      s.codeUnitAt(7) != _dash ||
      (t != _upperT && t != _lowerT && t != _space) ||
      s.codeUnitAt(13) != _colon ||
      s.codeUnitAt(16) != _colon) {
    return null;
  }

  var i = 19;
  var microseconds = 0;
  if (s.codeUnitAt(i) == _dot) {
    i++;
    final start = i;
    while (i < length) {
      final digit = s.codeUnitAt(i) ^ _zero;
      if (digit > 9) break;
      if (i - start < 6) microseconds = microseconds * 10 + digit;
      i++;
    }
    final count = i - start;
    if (count == 0) return null;
    for (var n = count; n < 6; n++) {
      microseconds *= 10;
    }
  }
  if (i >= length) return null;

  var offsetMinutes = 0;
  final zone = s.codeUnitAt(i);
  if (zone == _upperZ || zone == _lowerZ) {
    i++;
  } else if (zone == _plus || zone == _dash) {
    if (i + 6 != length || s.codeUnitAt(i + 3) != _colon) return null;
    final offsetHours = _digits(s, i + 1, 2);
    final offsetMins = _digits(s, i + 4, 2);
    if (offsetHours < 0 || offsetMins < 0) return null;
    offsetMinutes = offsetHours * 60 + offsetMins;
    if (zone == _dash) offsetMinutes = -offsetMinutes;
    i += 6;
  } else {
    return null;
  }
  if (i != length) return null;

  return DateTime.utc(
    year,
    month,
    day,
    hour,
    minute - offsetMinutes,
    second,
    0,
    microseconds,
  );
}

/// Reads [count] decimal digits at [start], or returns -1.
int _digits(String s, int start, int count) {
  var result = 0;
  for (var i = start; i < start + count; i++) {
    final digit = s.codeUnitAt(i) ^ _zero;
    if (digit > 9) return -1;
    result = result * 10 + digit;
  }
  return result;
}

const int _zero = 0x30;
const int _dash = 0x2d;
const int _colon = 0x3a;
const int _dot = 0x2e;
const int _plus = 0x2b;
const int _space = 0x20;
const int _upperT = 0x54;
const int _lowerT = 0x74;
const int _upperZ = 0x5a;
const int _lowerZ = 0x7a;

/// A value for a field in an update request that distinguishes between
/// leaving the field unchanged, clearing it, and setting it.
///
/// Leave the field `null` (the default) to keep the current value. Pass
/// `Patch.clear()` to send JSON `null`, which clears the value on the
/// server. Pass `Patch.set(value)` to change it.
///
/// ```dart
/// UpdateCampaignRequest(
///   subject: .set('Our October news'),
///   replyTo: const .clear(),
/// );
/// ```
///
/// Models encode a patch with `if (field case final p?) 'key': p.value`,
/// which sends the value, or JSON `null` for a cleared field.
final class const Patch<T>._(
  /// The new value, or `null` when [isClear] is `true`.
  final T? value,

  /// Whether this patch clears the field.
  final bool isClear,
) {
  /// Sets the field to [value].
  const new set(T value) : this._(value, false);

  /// Clears the field by sending JSON `null`.
  const new clear() : this._(null, true);

  @override
  bool operator ==(Object other) =>
      other is Patch<T> && other.value == value && other.isClear == isClear;

  @override
  int get hashCode => Object.hash(value, isClear);

  @override
  String toString() => isClear ? 'Patch.clear()' : 'Patch.set($value)';
}

/// Decodes an API enum value with [create]. A missing value becomes `''`,
/// which is not a known value of any enum.
///
/// The enums of this package are extension types on [String], so values
/// the package does not know yet are kept as they are.
T decodeEnum<T>(Object? value, T Function(String value) create) =>
    create(value as String? ?? '');

/// Decodes an API enum value with [create], or returns `null` when [value]
/// is `null`.
T? decodeEnumOrNull<T>(Object? value, T Function(String value) create) =>
    value == null ? null : create(value as String);
