import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/error_mapper.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/app_page_header.dart';

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
            const AppPageHeader(
              title: 'Ubah Kata Sandi',
              subtitle: 'Gunakan password baru minimal 6 karakter',
              icon: Icons.lock_reset_rounded,
              showBack: true,
            ),
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

