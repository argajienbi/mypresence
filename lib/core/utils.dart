import 'package:intl/intl.dart';

class AppDate {
  static String dateKey([DateTime? value]) => DateFormat('yyyy-MM-dd').format(value ?? DateTime.now());
  static String time([DateTime? value]) => DateFormat('HH:mm').format(value ?? DateTime.now());
  static String monthLabel(DateTime value) => DateFormat('MMMM yyyy', 'id_ID').format(value);
  static String dayDate(DateTime value) => DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(value);
  static String shortDate(DateTime value) => DateFormat('d MMM', 'id_ID').format(value);
  static String weekday(DateTime value) => DateFormat('EEEE', 'id_ID').format(value);
}

String asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
  return <String, dynamic>{};
}
