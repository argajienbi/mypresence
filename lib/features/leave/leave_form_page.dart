import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/error_mapper.dart';
import '../../core/models/app_session.dart';
import '../../services/leave_service.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/soft_header.dart';

class LeaveFormPage extends StatefulWidget {
  final AppSession session;
  final String type;
  const LeaveFormPage({super.key, required this.session, required this.type});

  @override
  State<LeaveFormPage> createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends State<LeaveFormPage> {
  final LeaveService _service = LeaveService();
  final start = TextEditingController();
  final end = TextEditingController();
  final reason = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    start.dispose();
    end.dispose();
    reason.dispose();
    super.dispose();
  }

  String get title {
    switch (widget.type) {
      case 'sakit':
        return 'Lapor Sakit';
      case 'cuti':
        return 'Lapor Cuti';
      case 'lembur':
        return 'Pengajuan Lembur';
      default:
        return 'Lapor Izin';
    }
  }

  IconData get icon {
    switch (widget.type) {
      case 'sakit':
        return Icons.favorite_rounded;
      case 'cuti':
        return Icons.work_history_rounded;
      case 'lembur':
        return Icons.timelapse_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    setState(() => loading = true);
    try {
      await _service.submitLeave(session: widget.session, type: widget.type, dateStart: start.text, dateEnd: end.text, reason: reason.text);
      if (!mounted) return;
      AppToast.success(context, 'Pengajuan berhasil dikirim.');
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
      message: 'Mengirim pengajuan...',
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            const SoftHeaderBackground(height: 210),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SourcePageTitle(
                      title: title,
                      subtitle: 'Lengkapi formulir dan kirim ke admin untuk approval',
                      icon: icon,
                      trailing: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.text),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white.withValues(alpha: .78)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .09), blurRadius: 18, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          TextField(controller: start, decoration: const InputDecoration(labelText: 'Tanggal mulai yyyy-mm-dd', prefixIcon: Icon(Icons.calendar_today_rounded))),
                          const SizedBox(height: 12),
                          TextField(controller: end, decoration: const InputDecoration(labelText: 'Tanggal selesai yyyy-mm-dd', prefixIcon: Icon(Icons.event_available_rounded))),
                          const SizedBox(height: 12),
                          TextField(controller: reason, maxLines: 5, decoration: const InputDecoration(labelText: 'Alasan', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes_rounded))),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: loading ? null : submit,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                              child: const Text('Kirim Pengajuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
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
