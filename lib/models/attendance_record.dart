import '../core/helpers/map_helper.dart';

class AttendanceRecord {
  final String actionType;
  final String date;
  final String time;
  final String status;
  final String attendanceStatus;
  final String method;
  final double distanceMeter;
  final double radiusMeter;
  final String photoUrl;

  const AttendanceRecord({
    required this.actionType,
    required this.date,
    required this.time,
    required this.status,
    required this.attendanceStatus,
    required this.method,
    required this.distanceMeter,
    required this.radiusMeter,
    required this.photoUrl,
  });

  factory AttendanceRecord.fromMap(String actionType, Map<String, dynamic> map) {
    return AttendanceRecord(
      actionType: actionType,
      date: readString(map, 'date', readString(map, 'tanggal')),
      time: readString(map, 'time', readString(map, 'waktu')),
      status: readString(map, 'status'),
      attendanceStatus: readString(map, 'attendance_status'),
      method: readString(map, 'method'),
      distanceMeter: readDouble(map, 'distance_meter'),
      radiusMeter: readDouble(map, 'radius_meter'),
      photoUrl: readString(map, 'photo_url'),
    );
  }
}

class TodayAttendance {
  final AttendanceRecord? masuk;
  final AttendanceRecord? pulang;

  const TodayAttendance({
    required this.masuk,
    required this.pulang,
  });

  bool get hasMasuk => masuk != null;
  bool get hasPulang => pulang != null;

  String get statusText {
    if (!hasMasuk && !hasPulang) return 'Belum Ada Presensi';
    if (hasMasuk && !hasPulang) return 'Sudah Absen Masuk';
    return 'Presensi Hari Ini Selesai';
  }

  String get description {
    if (!hasMasuk && !hasPulang) {
      return 'Silakan lakukan absen masuk dari area kantor.';
    }
    if (hasMasuk && !hasPulang) {
      return 'Absen masuk tercatat. Jangan lupa absen pulang.';
    }
    return 'Presensi masuk dan pulang sudah lengkap.';
  }

  String get nextAction {
    if (!hasMasuk) return 'masuk';
    if (!hasPulang) return 'pulang';
    return 'completed';
  }
}
