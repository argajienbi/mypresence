import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';

class EditProfilePage extends StatefulWidget {
  final AppSession session;

  const EditProfilePage({super.key, required this.session});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileService _profile = ProfileService();
  late final TextEditingController name;
  late final TextEditingController phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.session.displayName);
    phone = TextEditingController(text: widget.session.noHp);
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      AppToast.error(context, 'Nama lengkap wajib diisi.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _profile.updateBasicProfile(session: widget.session, namaLengkap: name.text, noHp: phone.text);
      if (!mounted) return;
      AppToast.success(context, 'Data pribadi berhasil disimpan.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      visible: _saving,
      message: 'Menyimpan data pribadi...',
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const _EditProfileHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          TextField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline_rounded))),
                          const SizedBox(height: 12),
                          TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor HP', prefixIcon: Icon(Icons.phone_rounded))),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: const Text('Simpan Data Pribadi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Info hanya admin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.text)),
                          const SizedBox(height: 10),
                          _StaticInfo(label: 'Email', value: widget.session.email),
                          _StaticInfo(label: 'NIP', value: widget.session.nip),
                          _StaticInfo(label: 'Role', value: widget.session.role),
                          _StaticInfo(label: 'Position', value: widget.session.position),
                          _StaticInfo(label: 'Office', value: widget.session.officeName),
                          _StaticInfo(label: 'Department', value: widget.session.departmentName),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                            child: const Text('Data perusahaan, jabatan, kantor, departemen, grup, dan NIP hanya dapat diubah admin.', style: AppText.subtitle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header teal (pola _LeaveFormHeader): StickyCurvePage krem tidak dipakai
/// di sini agar halaman ini mengikuti bahasa myadmin.
class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader();

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
                child: const Icon(Icons.badge_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Pribadi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Perubahan data pribadi akan tersimpan di akun perusahaan Anda.',
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

class _StaticInfo extends StatelessWidget {
  final String label;
  final String value;

  const _StaticInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted))),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.text))),
        ],
      ),
    );
  }
}
