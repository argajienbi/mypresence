class DateHelper {
  static const List<String> _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String dateKey([DateTime? value]) {
    final d = value ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String time([DateTime? value]) {
    final d = value ?? DateTime.now();
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  static String timeWithSecond([DateTime? value]) {
    final d = value ?? DateTime.now();
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}:'
        '${d.second.toString().padLeft(2, '0')}';
  }

  static String fullDate([DateTime? value]) {
    final d = value ?? DateTime.now();
    final day = _days[d.weekday - 1];
    final month = _months[d.month - 1];
    return '$day, ${d.day} $month ${d.year}';
  }

  static String monthYear([DateTime? value]) {
    final d = value ?? DateTime.now();
    final month = _months[d.month - 1];
    return '$month ${d.year}';
  }

  static String shortDate(DateTime d) {
    final day = _days[d.weekday - 1];
    final month = _months[d.month - 1].substring(0, 3);
    return '$day,\n${d.day} $month';
  }

  static DateTime parseDateKey(String value) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  static bool isSameMonth(String dateKeyValue, DateTime month) {
    final d = DateTime.tryParse(dateKeyValue);
    if (d == null) return false;
    return d.year == month.year && d.month == month.month;
  }
}
