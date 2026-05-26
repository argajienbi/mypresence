import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/sticky_curve_layout.dart';

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
        body: StickyCurvePage(
          title: 'Data Pribadi',
          subtitle: 'Mengacu ke /users dan /company_users RTDB',
          icon: Icons.badge_rounded,
          overlapTop: 132,
          trailing: SourceRoundButton(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
          overlapChild: AppCard(
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                    child: const Text('Simpan Data Pribadi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
          children: [
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
                    decoration: BoxDecoration(color: AppColors.header.withValues(alpha: .70), borderRadius: BorderRadius.circular(16)),
                    child: const Text('Company, jabatan, office, department, group, dan NIP hanya dapat diubah admin.', style: AppText.subtitle),
                  ),
                ],
              ),
            ),
          ],
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
