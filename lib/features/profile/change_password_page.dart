import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/error_mapper.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  bool hidePassword = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();
    if (password.text.length < 6) {
      AppToast.error(context, 'Password minimal 6 karakter.');
      return;
    }
    if (password.text != confirm.text) {
      AppToast.error(context, 'Konfirmasi password tidak sama.');
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.currentUser?.updatePassword(password.text);
      if (!mounted) return;
      AppToast.success(context, 'Password berhasil diubah.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.error(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      visible: loading,
      message: 'Menyimpan password...',
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const _ChangePasswordHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: password,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Password baru',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(onPressed: () => setState(() => hidePassword = !hidePassword), icon: Icon(hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirm,
                        obscureText: hideConfirm,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi password baru',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(onPressed: () => setState(() => hideConfirm = !hideConfirm), icon: Icon(hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : save,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Simpan Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header teal (pola _LeaveFormHeader): SoftHeaderBackground krem tidak
/// dipakai di sini agar halaman ini mengikuti bahasa myadmin.
class _ChangePasswordHeader extends StatelessWidget {
  const _ChangePasswordHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .35),
                  ),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubah Kata Sandi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gunakan password baru minimal 6 karakter',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .35),
                    ),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
