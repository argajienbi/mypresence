import 'package:firebase_auth/firebase_auth.dart';

import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import 'rtdb_service.dart';
import 'push_notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RtdbService _rtdb = RtdbService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) => _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  Future<UserCredential> register(String email, String password) => _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  Future<void> logout() => _auth.signOut();

  Future<void> logoutWithSession(AppSession session) async {
    try {
      await PushNotificationService.deactivateCurrentToken(session);
    } catch (_) {}
    await _auth.signOut();
  }
  Future<void> sendPasswordResetEmail(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<AppSession> loadSession() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Belum login.');

    final userMap = await _rtdb.getMap(FirebasePaths.user(user.uid));
    if (userMap == null) throw Exception('Data user belum ada di /users/${user.uid}.');

    final companyId = (userMap['company_id'] ?? '').toString();
    if (companyId.isEmpty) throw Exception('Akun belum memiliki company_id.');

    final companyUser = await _rtdb.getMap(FirebasePaths.companyUser(companyId, user.uid));
    if (companyUser == null) throw Exception('Data company user tidak ditemukan.');

    final status = (companyUser['status_akun'] ?? userMap['status_akun'] ?? '').toString();
    if (status != 'active') throw Exception('Akun belum aktif. Status: $status');

    final officeId = (companyUser['office_id'] ?? '').toString();
    if (officeId.isEmpty) throw Exception('Akun belum memiliki office_id.');

    final office = await _rtdb.getMap(FirebasePaths.office(companyId, officeId));
    if (office == null) throw Exception('Data kantor tidak ditemukan.');

    final departmentId = (companyUser['department_id'] ?? '').toString();
    final subDepartmentId = (companyUser['sub_department_id'] ?? '').toString();
    final groupId = (companyUser['group_id'] ?? '').toString();

    final department = departmentId.isEmpty ? null : await _rtdb.getMap(FirebasePaths.department(companyId, departmentId));
    final subDepartment = subDepartmentId.isEmpty ? null : await _rtdb.getMap(FirebasePaths.subDepartment(companyId, subDepartmentId));
    final group = groupId.isEmpty ? null : await _rtdb.getMap(FirebasePaths.employeeGroup(companyId, groupId));

    return AppSession.fromMaps(
      uid: user.uid,
      user: userMap,
      companyUser: companyUser,
      office: office,
      department: department,
      subDepartment: subDepartment,
      group: group,
    );
  }

  Future<void> registerWithInvite({
    required String inviteCode,
    required String namaLengkap,
    required String nip,
    required String email,
    required String noHp,
    required String password,
  }) async {
    final invite = await _rtdb.getMap(FirebasePaths.companyInvite(inviteCode));
    if (invite == null) throw Exception('Kode undangan tidak ditemukan.');
    if ((invite['active'] ?? true) == false) throw Exception('Kode undangan tidak aktif.');

    final companyId = (invite['company_id'] ?? '').toString();
    if (companyId.isEmpty) throw Exception('company_id pada undangan kosong.');

    final credential = await register(email, password);
    final uid = credential.user?.uid;
    if (uid == null) throw Exception('Gagal membuat akun. UID kosong.');

    final now = DateTime.now().millisecondsSinceEpoch;
    final status = (invite['auto_approve'] == true) ? 'active' : 'pending';
    final position = (invite['position'] ?? 'USER').toString();

    await _rtdb.set(FirebasePaths.user(uid), {
      'uid': uid,
      'company_id': companyId,
      'role': 'user',
      'position': position,
      'status_akun': status,
      'email': email.trim(),
      'nama_lengkap': namaLengkap.trim(),
      'created_at': now,
      'updated_at': now,
    });

    await _rtdb.set(FirebasePaths.companyUser(companyId, uid), {
      'uid': uid,
      'company_id': companyId,
      'role': 'user',
      'position': position,
      'status_akun': status,
      'email': email.trim(),
      'nama_lengkap': namaLengkap.trim(),
      'nip': nip.trim(),
      'no_hp': noHp.trim(),
      'area_id': (invite['area_id'] ?? '').toString(),
      'office_id': (invite['office_id'] ?? '').toString(),
      'department_id': (invite['department_id'] ?? '').toString(),
      'sub_department_id': (invite['sub_department_id'] ?? '').toString(),
      'group_id': (invite['group_id'] ?? '').toString(),
      'profile_completed': false,
      'face_registered': false,
      'device_id': null,
      'device_name': null,
      'photo_url': '',
      'photo_path': '',
      'qr_token': '',
      'qr_active': false,
      'qr_updated_at': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

}
