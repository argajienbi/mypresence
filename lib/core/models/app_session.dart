import '../utils.dart';

class AppSession {
  final String uid;
  final String companyId;
  final String role;
  final String position;
  final String statusAkun;
  final String namaLengkap;
  final String email;
  final String nip;
  final String noHp;
  final String photoUrl;
  final String photoPath;
  final String areaId;
  final String officeId;
  final String departmentId;
  final String departmentName;
  final String subDepartmentId;
  final String subDepartmentName;
  final String groupId;
  final String groupName;
  final String officeName;
  final String officeAddress;
  final double officeLatitude;
  final double officeLongitude;
  final double officeRadiusMeter;

  const AppSession({
    required this.uid,
    required this.companyId,
    required this.role,
    required this.position,
    required this.statusAkun,
    required this.namaLengkap,
    required this.email,
    required this.nip,
    required this.noHp,
    required this.photoUrl,
    required this.photoPath,
    required this.areaId,
    required this.officeId,
    required this.departmentId,
    required this.departmentName,
    required this.subDepartmentId,
    required this.subDepartmentName,
    required this.groupId,
    required this.groupName,
    required this.officeName,
    required this.officeAddress,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.officeRadiusMeter,
  });

  bool get isActive => statusAkun == 'active';
  String get displayName => namaLengkap.isEmpty ? email : namaLengkap;

  factory AppSession.fromMaps({
    required String uid,
    required Map<String, dynamic> user,
    required Map<String, dynamic> companyUser,
    required Map<String, dynamic> office,
    Map<String, dynamic>? department,
    Map<String, dynamic>? subDepartment,
    Map<String, dynamic>? group,
  }) {
    return AppSession(
      uid: uid,
      companyId: asString(companyUser['company_id'], asString(user['company_id'])),
      role: asString(companyUser['role'], asString(user['role'], 'user')),
      position: asString(companyUser['position'], asString(user['position'], 'USER')),
      statusAkun: asString(companyUser['status_akun'], asString(user['status_akun'], 'pending')),
      namaLengkap: asString(companyUser['nama_lengkap'], asString(user['nama_lengkap'])),
      email: asString(companyUser['email'], asString(user['email'])),
      nip: asString(companyUser['nip']),
      noHp: asString(companyUser['no_hp']),
      photoUrl: asString(companyUser['photo_url'], asString(user['photo_url'])),
      photoPath: asString(companyUser['photo_path'], asString(user['photo_path'])),
      areaId: asString(companyUser['area_id']),
      officeId: asString(companyUser['office_id']),
      departmentId: asString(companyUser['department_id']),
      departmentName: asString(department?['name'], asString(companyUser['department_name'])),
      subDepartmentId: asString(companyUser['sub_department_id']),
      subDepartmentName: asString(subDepartment?['name'], asString(companyUser['sub_department_name'])),
      groupId: asString(companyUser['group_id']),
      groupName: asString(group?['name'], asString(companyUser['group_name'])),
      officeName: asString(office['name'], asString(office['office_name'], 'Kantor')),
      officeAddress: asString(office['address'], 'Alamat kantor belum tersedia'),
      officeLatitude: asDouble(office['latitude']),
      officeLongitude: asDouble(office['longitude']),
      officeRadiusMeter: asDouble(office['radius_meter'], 100),
    );
  }
}
