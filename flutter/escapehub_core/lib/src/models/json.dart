typedef Json = Map<String, dynamic>;

DateTime readDate(Object? value) {
  final parsed = DateTime.parse(value as String);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime readTimestamp(Object? value) => DateTime.parse(value as String).toLocal();

DateTime? readTimestampOrNull(Object? value) => value == null ? null : readTimestamp(value);

double readDecimal(Object? value) => (value as num).toDouble();

double? readDecimalOrNull(Object? value) => (value as num?)?.toDouble();

List<T> readList<T>(Object? value, T Function(Json json) parse) => [
  for (final item in value as List) parse(item as Json),
];

List<String> readStrings(Object? value) => List<String>.from(value as List);

String formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
