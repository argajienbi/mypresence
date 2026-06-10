import '../../services/schedule_service.dart';

class DailyHistoryStatus {
  final DateTime date;
  final String dateKey;
  final String status;
  final Map<String, dynamic>? attendanceRow;
  final Map<String, dynamic>? leaveRow;
  final DailySchedule? schedule;
  final Map<String, dynamic>? overtimeRow;

  const DailyHistoryStatus({
    required this.date,
    required this.dateKey,
    required this.status,
    required this.attendanceRow,
    required this.leaveRow,
    required this.schedule,
    required this.overtimeRow,
  });
}
