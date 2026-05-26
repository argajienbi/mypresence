Map<String, dynamic> asMap(dynamic value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

String readString(Map<String, dynamic> map, String key, [String fallback = '']) {
  final value = map[key];
  if (value == null) return fallback;
  return value.toString();
}

int readInt(Map<String, dynamic> map, String key, [int fallback = 0]) {
  final value = map[key];
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double readDouble(Map<String, dynamic> map, String key, [double fallback = 0]) {
  final value = map[key];
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool readBool(Map<String, dynamic> map, String key, [bool fallback = false]) {
  final value = map[key];
  if (value is bool) return value;
  if (value is String) return value == 'true' || value == '1';
  return fallback;
}
