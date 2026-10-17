/// Безопасное чтение значений из JSON.
///
/// Backend может прислать число строкой или пропустить необязательное поле,
/// поэтому модели не падают на неожиданных типах.
library;

int readInt(Object? value, {int fallback = 0}) {
  return switch (value) {
    final num number => number.toInt(),
    final String text => int.tryParse(text) ?? fallback,
    _ => fallback,
  };
}

double readDouble(Object? value, {double fallback = 0}) {
  return switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? fallback,
    _ => fallback,
  };
}

String readString(Object? value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

List<String> readStringList(Object? value) {
  if (value is! List<Object?>) {
    return const <String>[];
  }
  return value
      .whereType<String>()
      .map((String item) => item.trim().toUpperCase())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, int> readIntMap(Object? value) {
  if (value is! Map<Object?, Object?>) {
    return const <String, int>{};
  }
  final Map<String, int> result = <String, int>{};
  for (final MapEntry<Object?, Object?> entry in value.entries) {
    final Object? rawKey = entry.key;
    if (rawKey is! String) {
      continue;
    }
    final String key = rawKey.trim().toUpperCase();
    if (key.isEmpty) {
      continue;
    }
    result[key] = readInt(entry.value);
  }
  return result;
}
