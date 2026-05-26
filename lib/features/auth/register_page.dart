import 'package:flutter/material.dart';

import '../../core/error_mapper.dart';
import '../../core/firebase_paths.dart';
import '../../services/auth_service.dart';
import '../../services/rtdb_service.dart';
import '../../widgets/app_feedback.dart';
import 'auth_visuals.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _auth = AuthService();
  final RtdbService _rtdb = RtdbService();
  final TextEditingController _invite = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _nip = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _agree = false;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String _error = '';

  @override
  void dispose() {
    _invite.dispose();
    _name.dispose();
    _nip.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      if (_invite.text.trim().isEmpty) throw Exception('Kode perusahaan / undangan wajib diisi.');
      if (_name.text.trim().isEmpty) throw Exception('Nama lengkap wajib diisi.');
      if (_nip.text.trim().isEmpty) throw Exception('NIP / ID karyawan wajib diisi.');
      if (_email.text.trim().isEmpty) throw Exception('Email wajib diisi.');
      if (_password.text.length < 6) throw Exception('Kata sandi minimal 6 karakter.');
      if (_password.text != _confirm.text) throw Exception('Konfirmasi kata sandi tidak sama.');
      if (!_agree) throw Exception('Setujui syarat & ketentuan.');

      final inviteMap = await _rtdb.getMap(FirebasePaths.companyInvite(_invite.text.trim()));
      if (inviteMap == null) throw Exception('Kode undangan tidak ditemukan.');
      if ((inviteMap['active'] ?? true) == false) throw Exception('Kode undangan tidak aktif.');
      final companyId = (inviteMap['company_id'] ?? '').toString();
      if (companyId.isEmpty) throw Exception('company_id pada invite kosong.');

      final cred = await _auth.register(_email.text.trim(), _password.text);
      final uid = cred.user?.uid;
      if (uid == null) throw Exception('Gagal membuat UID.');

      final now = DateTime.now().millisecondsSinceEpoch;
      final status = (inviteMap['auto_approve'] == true) ? 'active' : 'pending';
      final position = (inviteMap['position'] ?? 'EMPLOYEE').toString();

      await _rtdb.set(FirebasePaths.user(uid), {
        'uid': uid,
        'company_id': companyId,
        'role': 'user',
        'position': position,
        'status_akun': status,
        'email': _email.text.trim(),
        'nama_lengkap': _name.text.trim(),
        'created_at': now,
        'updated_at': now,
      });

      await _rtdb.set(FirebasePaths.companyUser(companyId, uid), {
        'uid': uid,
        'company_id': companyId,
        'nama_lengkap': _name.text.trim(),
        'email': _email.text.trim(),
        'nip': _nip.text.trim(),
        'no_hp': _phone.text.trim(),
        'role': 'user',
        'position': position,
        'status_akun': status,
        'area_id': (inviteMap['area_id'] ?? '').toString(),
        'office_id': (inviteMap['office_id'] ?? '').toString(),
        'department_id': (inviteMap['department_id'] ?? '').toString(),
        'sub_department_id': (inviteMap['sub_department_id'] ?? '').toString(),
        'group_id': (inviteMap['group_id'] ?? '').toString(),
        'photo_url': '',
        'photo_path': '',
        'qr_token': '',
        'qr_active': false,
        'qr_updated_at': 0,
        'created_at': now,
        'updated_at': now,
      });

      if (!mounted) return;
      AppToast.success(context, status == 'active' ? 'Daftar berhasil.' : 'Daftar berhasil. Menunggu aktivasi admin.');
      Navigator.of(context).pop();
    } catch (e) {
      final msg = friendlyError(e);
      if (!mounted) return;
      setState(() => _error = msg);
      AppToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      visible: _loading,
      message: 'Mendaftarkan akun...',
      child: Scaffold(
        body: Container(
          decoration: AuthUi.screenGradient(),
          child: SafeArea(
            child: Stack(
              children: [
                const AuthHeaderBackground(
                  height: 212,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(56, 26, 24, 0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: AuthBrandTitle(),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: IconButton(
                    onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 122, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthCard(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        radius: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daftar Akun',
                              style: TextStyle(
                                color: AuthUi.text,
                                fontSize: 25,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.7,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Masukkan kode perusahaan dan data karyawan.',
                              style: TextStyle(color: AuthUi.muted, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 18),
                            AuthTextField(
                              controller: _invite,
                              hint: 'Kode Perusahaan / Undangan',
                              icon: Icons.badge_outlined,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 10),
                            AuthTextField(
                              controller: _name,
                              hint: 'Nama Lengkap',
                              icon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 10),
                            AuthTextField(
                              controller: _nip,
                              hint: 'NIP / ID Karyawan',
                              icon: Icons.credit_card_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 10),
                            AuthTextField(
                              controller: _email,
                              hint: 'Email',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 10),
                            AuthTextField(
                              controller: _phone,
                              hint: 'Nomor HP',
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 10),
                            AuthTextField(
                              controller: _password,
                              hint: 'Kata Sandi',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _hidePassword,
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                splashRadius: 20,
                                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                icon: Icon(
                                  _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AuthUi.muted,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            AuthTextField(
                              controller: _confirm,
                              hint: 'Konfirmasi Kata Sandi',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _hideConfirm,
                              textInputAction: TextInputAction.done,
                              suffixIcon: IconButton(
                                splashRadius: 20,
                                onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                                icon: Icon(
                                  _hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AuthUi.muted,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _loading ? null : () => setState(() => _agree = !_agree),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _agree,
                                        activeColor: AuthUi.green,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                        onChanged: _loading ? null : (v) => setState(() => _agree = v ?? false),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Saya setuju dengan syarat & ketentuan',
                                        style: TextStyle(color: AuthUi.text, fontSize: 12.5, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AuthErrorBanner(message: _error),
                            const SizedBox(height: 14),
                            GreenPrimaryButton(label: 'Daftar', onPressed: _register, loading: _loading),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Sudah punya akun? ',
                              style: TextStyle(color: AuthUi.text, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            GestureDetector(
                              onTap: _loading ? null : () => Navigator.of(context).maybePop(),
                              child: const Text(
                                'Masuk',
                                style: TextStyle(color: AuthUi.deepTeal, fontSize: 13, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
