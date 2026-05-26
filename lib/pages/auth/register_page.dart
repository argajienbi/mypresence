import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  static const routeName = '/register';

  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _inviteController = TextEditingController();
  final _nameController = TextEditingController();
  final _nipController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _agree = false;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _inviteController.dispose();
    _nameController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final invite = _inviteController.text.trim();
    final name = _nameController.text.trim();
    final nip = _nipController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (invite.isEmpty ||
        name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      setState(() => _error = 'Semua field wajib diisi.');
      return;
    }

    if (password.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter.');
      return;
    }

    if (password != confirm) {
      setState(() => _error = 'Konfirmasi password tidak sama.');
      return;
    }

    if (!_agree) {
      setState(() => _error = 'Anda harus menyetujui syarat dan ketentuan.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      await AuthService().registerWithInvite(
        inviteCode: invite,
        namaLengkap: name,
        nip: nip,
        email: email,
        noHp: phone,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil. Tunggu aktivasi admin jika akun belum aktif.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginPage.routeName,
        (_) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Akun',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masukkan kode undangan dari perusahaan.',
                    style: TextStyle(color: AppColors.muted, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _field(_inviteController, 'Kode perusahaan / undangan'),
                        const SizedBox(height: 12),
                        _field(_nameController, 'Nama lengkap'),
                        const SizedBox(height: 12),
                        _field(_nipController, 'NIP / ID karyawan'),
                        const SizedBox(height: 12),
                        _field(
                          _emailController,
                          'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _phoneController,
                          'Nomor HP',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _passwordController,
                          'Password',
                          obscure: true,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          _confirmController,
                          'Konfirmasi password',
                          obscure: true,
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _agree,
                          onChanged: (value) {
                            setState(() => _agree = value ?? false);
                          },
                          title: const Text(
                            'Saya setuju dengan syarat & ketentuan',
                            style: TextStyle(fontSize: 13),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _error,
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Daftar'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Sudah punya akun? Masuk',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hint),
    );
  }
}
