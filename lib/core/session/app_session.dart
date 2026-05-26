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

  final String areaId;
  final String officeId;
  final String departmentId;
  final String subDepartmentId;
  final String groupId;

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
    required this.areaId,
    required this.officeId,
    required this.departmentId,
    required this.subDepartmentId,
    required this.groupId,
    required this.officeName,
    required this.officeAddress,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.officeRadiusMeter,
  });

  bool get isActive => statusAkun == 'active';
}
