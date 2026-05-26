import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/error_mapper.dart';
import '../../core/models/app_session.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_feedback.dart';
import '../home/main_shell.dart';
import 'auth_visuals.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan kata sandi wajib diisi.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await _auth.login(_email.text.trim(), _password.text);
      final AppSession session = await _auth.loadSession();
      if (!mounted) return;
      AppToast.success(context, 'Berhasil masuk.');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainShell(session: session)));
    } catch (e) {
      final message = friendlyError(e);
      if (!mounted) return;
      setState(() => _error = message);
      AppToast.error(context, message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showResetPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan email akun kamu. Link reset password akan dikirim melalui Firebase Auth.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Kirim')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordResetEmail(result);
      if (!mounted) return;
      AppToast.success(context, 'Link reset password dikirim ke $result.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, friendlyError(e));
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
        systemNavigationBarColor: AuthUi.bgBottom,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: AppLoadingOverlay(
        visible: _loading,
        message: 'Memproses akun...',
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: AuthUi.screenGradient(),
            child: Stack(
              children: [
                AuthHeaderBackground(
                  height: 212 + topInset,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, topInset + 26, 24, 0),
                    child: const Align(
                      alignment: Alignment.topLeft,
                      child: AuthBrandTitle(),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(24, topInset + 122, 24, 24 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: media.size.height - topInset - bottomInset - 146,
                    ),
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
                                'Masuk ke Akun',
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
                                'Gunakan email dan kata sandi yang terdaftar.',
                                style: TextStyle(color: AuthUi.muted, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 18),
                              AuthTextField(
                                controller: _email,
                                hint: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              AuthTextField(
                                controller: _password,
                                hint: 'Kata Sandi',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _hidePassword,
                                textInputAction: TextInputAction.done,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(
                                    _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AuthUi.muted,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showResetPassword,
                                  child: const Text(
                                    'Lupa Password?',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: AuthUi.deepTeal),
                                  ),
                                ),
                              ),
                              AuthErrorBanner(message: _error),
                              const SizedBox(height: 14),
                              GreenPrimaryButton(label: 'Masuk', onPressed: _login, loading: _loading),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Belum punya akun? ',
                                style: TextStyle(color: AuthUi.muted, fontWeight: FontWeight.w700),
                              ),
                              GestureDetector(
                                onTap: _loading
                                    ? null
                                    : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(color: AuthUi.deepTeal, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _LoginInfoBox(),
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

class _LoginInfoBox extends StatelessWidget {
  const _LoginInfoBox();

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AuthUi.softGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.verified_user_outlined, color: AuthUi.deepTeal, size: 21),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presensi aman untuk karyawan',
                      style: TextStyle(color: AuthUi.text, fontSize: 13.5, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Akun hanya dapat digunakan oleh karyawan yang terdaftar pada perusahaan.',
                      style: TextStyle(color: AuthUi.muted, fontSize: 12, height: 1.35, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(icon: Icons.location_on_outlined, label: 'Lokasi tervalidasi'),
              _InfoPill(icon: Icons.photo_camera_outlined, label: 'Selfie presensi'),
              _InfoPill(icon: Icons.history_rounded, label: 'Riwayat tersimpan'),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AuthUi.line),
          const SizedBox(height: 10),
          const Text(
            'Butuh bantuan masuk? Hubungi admin perusahaan Anda untuk aktivasi akun atau reset akses.',
            style: TextStyle(color: AuthUi.muted, fontSize: 11.8, height: 1.35, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AuthUi.paleGreen,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AuthUi.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AuthUi.deepTeal, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: AuthUi.deepTeal, fontSize: 11.5, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
