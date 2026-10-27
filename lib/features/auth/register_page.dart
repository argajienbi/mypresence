import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
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
    final media = MediaQuery.of(context);
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: AppLoadingOverlay(
        visible: _loading,
        message: 'Mendaftarkan akun...',
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // Header gradient teal + tombol kembali + logo (mockup 06)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24, topInset + 44, 24, 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: _loading
                                ? null
                                : () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                AuthUi.appLogoAsset,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'MyPresence',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Absensi cerdas untuk tim Anda',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // White card overlapping (mockup 06)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, -34, 20, 0),
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Akun',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masukkan kode perusahaan dan data karyawan',
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel('Kode Perusahaan / Undangan'),
                      AuthTextField(
                        controller: _invite,
                        hint: 'cth: FMI-2026',
                        icon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel('Nama Lengkap'),
                      AuthTextField(
                        controller: _name,
                        hint: 'Nama sesuai KTP',
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel('NIP / ID Karyawan'),
                      AuthTextField(
                        controller: _nip,
                        hint: 'Nomor induk karyawan',
                        icon: Icons.credit_card_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel('Email'),
                      AuthTextField(
                        controller: _email,
                        hint: 'nama@perusahaan.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel('Nomor HP'),
                      AuthTextField(
                        controller: _phone,
                        hint: '08xxxxxxxxxx',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel('Kata Sandi'),
                      AuthTextField(
                        controller: _password,
                        hint: 'Minimal 6 karakter',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          splashRadius: 20,
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel('Konfirmasi Kata Sandi'),
                      AuthTextField(
                        controller: _confirm,
                        hint: 'Ulangi kata sandi',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _hideConfirm,
                        textInputAction: TextInputAction.done,
                        suffixIcon: IconButton(
                          splashRadius: 20,
                          onPressed: () =>
                              setState(() => _hideConfirm = !_hideConfirm),
                          icon: Icon(
                            _hideConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.muted,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _loading
                            ? null
                            : () => setState(() => _agree = !_agree),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _agree,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)),
                                  onChanged: _loading
                                      ? null
                                      : (v) =>
                                          setState(() => _agree = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Wrap(
                                  children: [
                                    Text(
                                      'Saya setuju dengan ',
                                      style: TextStyle(
                                          color: AppColors.text,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'syarat & ketentuan',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AuthErrorBanner(message: _error),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer (mockup 06)
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottomInset),
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Sudah punya akun? ',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500),
                        ),
                        GestureDetector(
                          onTap: _loading
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
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

/// Label field kecil di atas input, sesuai mockup 06.
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
