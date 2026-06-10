import '../utils.dart';

class AttendanceCorrectionRequest {
  final String correctionId;
  final String companyId;
  final String uid;
  final String userName;
  final String nip;
  final String date;
  final String correctionType;
  final String requestedCheckInTime;
  final String requestedCheckOutTime;
  final String reason;
  final String attachmentUrl;
  final String attachmentPath;
  final String attachmentName;
  final Map<String, dynamic> oldAttendance;
  final String status;
  final String adminUid;
  final String adminName;
  final String adminNote;
  final int validatedAt;
  final String approvedBy;
  final String approvedByName;
  final int approvedAt;
  final String rejectedBy;
  final String rejectedByName;
  final int rejectedAt;
  final String officeId;
  final String officeName;
  final String departmentId;
  final String departmentName;
  final String subDepartmentId;
  final String subDepartmentName;
  final String groupId;
  final String groupName;
  final String source;
  final int createdAt;
  final int updatedAt;

  const AttendanceCorrectionRequest({
    required this.correctionId,
    required this.companyId,
    required this.uid,
    required this.userName,
    required this.nip,
    required this.date,
    required this.correctionType,
    required this.requestedCheckInTime,
    required this.requestedCheckOutTime,
    required this.reason,
    required this.attachmentUrl,
    required this.attachmentPath,
    required this.attachmentName,
    required this.oldAttendance,
    required this.status,
    required this.adminUid,
    required this.adminName,
    required this.adminNote,
    required this.validatedAt,
    required this.approvedBy,
    required this.approvedByName,
    required this.approvedAt,
    required this.rejectedBy,
    required this.rejectedByName,
    required this.rejectedAt,
    required this.officeId,
    required this.officeName,
    required this.departmentId,
    required this.departmentName,
    required this.subDepartmentId,
    required this.subDepartmentName,
    required this.groupId,
    required this.groupName,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasAttachment =>
      attachmentUrl.isNotEmpty || attachmentPath.isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'correction_id': correctionId,
      'company_id': companyId,
      'uid': uid,
      'user_name': userName,
      'nip': nip,
      'date': date,
      'correction_type': correctionType,
      'requested_check_in_time': requestedCheckInTime,
      'requested_check_out_time': requestedCheckOutTime,
      'reason': reason,
      'attachment_url': attachmentUrl,
      'attachment_path': attachmentPath,
      'attachment_name': attachmentName,
      'attachment_type': attachmentPath.isEmpty ? '' : 'image',
      'old_attendance_snapshot': oldAttendance,
      'old_attendance': oldAttendance,
      'status': status,
      'admin_uid': adminUid,
      'admin_name': adminName,
      'admin_note': adminNote,
      'validated_at': validatedAt,
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'approved_at': approvedAt,
      'rejected_by': rejectedBy,
      'rejected_by_name': rejectedByName,
      'rejected_at': rejectedAt,
      'office_id': officeId,
      'office_name': officeName,
      'department_id': departmentId,
      'department_name': departmentName,
      'sub_department_id': subDepartmentId,
      'sub_department_name': subDepartmentName,
      'group_id': groupId,
      'group_name': groupName,
      'source': source,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AttendanceCorrectionRequest.fromMap(
    String correctionId,
    Map<String, dynamic> map,
  ) {
    final snapshot = map['old_attendance_snapshot'];
    final attendanceValue = snapshot is Map && snapshot.isNotEmpty
        ? snapshot
        : map['old_attendance'];
    return AttendanceCorrectionRequest(
      correctionId: correctionId,
      companyId: asString(map['company_id']),
      uid: asString(map['uid']),
      userName: asString(map['user_name']),
      nip: asString(map['nip']),
      date: asString(map['date']),
      correctionType: asString(map['correction_type']),
      requestedCheckInTime: asString(map['requested_check_in_time']),
      requestedCheckOutTime: asString(map['requested_check_out_time']),
      reason: asString(map['reason']),
      attachmentUrl: asString(map['attachment_url']),
      attachmentPath: asString(map['attachment_path']),
      attachmentName: asString(map['attachment_name']),
      oldAttendance: asMap(attendanceValue),
      status: asString(map['status'], 'pending'),
      adminUid: asString(map['admin_uid']),
      adminName: asString(map['admin_name']),
      adminNote: asString(map['admin_note']),
      validatedAt: asInt(map['validated_at']),
      approvedBy: asString(map['approved_by']),
      approvedByName: asString(map['approved_by_name']),
      approvedAt: asInt(map['approved_at']),
      rejectedBy: asString(map['rejected_by']),
      rejectedByName: asString(map['rejected_by_name']),
      rejectedAt: asInt(map['rejected_at']),
      officeId: asString(map['office_id']),
      officeName: asString(map['office_name']),
      departmentId: asString(map['department_id']),
      departmentName: asString(map['department_name']),
      subDepartmentId: asString(map['sub_department_id']),
      subDepartmentName: asString(map['sub_department_name']),
      groupId: asString(map['group_id']),
      groupName: asString(map['group_name']),
      source: asString(map['source'], 'mobile_app'),
      createdAt: asInt(map['created_at']),
      updatedAt: asInt(map['updated_at']),
    );
  }
}
