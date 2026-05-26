import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _picker = ImagePicker();
  final start = TextEditingController();
  final end = TextEditingController();
  final reason = TextEditingController();
  final overtimeStart = TextEditingController();
  final overtimeEnd = TextEditingController();
  bool loading = false;
  File? attachmentFile;
  String attachmentName = '';

  bool get isSakit => widget.type == 'sakit';
  bool get isLembur => widget.type == 'lembur';

  @override
  void dispose() {
    start.dispose();
    end.dispose();
    reason.dispose();
    overtimeStart.dispose();
    overtimeEnd.dispose();
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

  String get reasonLabel => isLembur ? 'Alasan / pekerjaan lembur' : 'Alasan';

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    setState(() => loading = true);
    try {
      final duration = isLembur ? _overtimeDurationMinute() : 0;
      await _service.submitLeave(
        session: widget.session,
        type: widget.type,
        dateStart: start.text,
        dateEnd: end.text,
        reason: reason.text,
        attachmentFile: attachmentFile,
        attachmentName: attachmentName,
        overtimeDate: isLembur ? start.text : '',
        overtimeStartTime: isLembur ? overtimeStart.text : '',
        overtimeEndTime: isLembur ? overtimeEnd.text : '',
        overtimeDurationMinute: duration,
      );
      if (!mounted) return;
      AppToast.success(context, 'Pengajuan berhasil dikirim.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppToast.error(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickAttachment(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 72, maxWidth: 1600);
    if (picked == null) return;
    setState(() {
      attachmentFile = File(picked.path);
      attachmentName = picked.name.isEmpty ? 'attachment_${DateTime.now().millisecondsSinceEpoch}.jpg' : picked.name;
    });
  }

  Future<void> pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (selected == null) return;
    final value = '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    setState(() {
      controller.text = value;
      if (isLembur && identical(controller, start)) {
        end.text = value;
      }
    });
  }

  Future<void> pickTime(TextEditingController controller) async {
    final current = _parseTimeOfDay(controller.text) ?? TimeOfDay.now();
    final selected = await showTimePicker(context: context, initialTime: current);
    if (selected == null) return;
    setState(() => controller.text = '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}');
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _overtimeDurationMinute() {
    final startMinute = _minuteOfDay(overtimeStart.text);
    final endMinute = _minuteOfDay(overtimeEnd.text);
    if (startMinute == null || endMinute == null) return 0;
    return endMinute - startMinute;
  }

  int? _minuteOfDay(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour * 60) + minute;
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
                          _DateField(
                            controller: start,
                            label: isLembur ? 'Tanggal lembur yyyy-mm-dd' : 'Tanggal mulai yyyy-mm-dd',
                            icon: Icons.calendar_today_rounded,
                            onTap: () => pickDate(start),
                          ),
                          const SizedBox(height: 12),
                          if (isLembur) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _DateField(
                                    controller: overtimeStart,
                                    label: 'Jam mulai',
                                    icon: Icons.access_time_rounded,
                                    onTap: () => pickTime(overtimeStart),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DateField(
                                    controller: overtimeEnd,
                                    label: 'Jam selesai',
                                    icon: Icons.schedule_rounded,
                                    onTap: () => pickTime(overtimeEnd),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            _DateField(
                              controller: end,
                              label: 'Tanggal selesai yyyy-mm-dd',
                              icon: Icons.event_available_rounded,
                              onTap: () => pickDate(end),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: reason,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: reasonLabel,
                              alignLabelWithHint: true,
                              prefixIcon: const Icon(Icons.notes_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AttachmentBox(
                            requiredAttachment: isSakit,
                            file: attachmentFile,
                            fileName: attachmentName,
                            onCamera: () => pickAttachment(ImageSource.camera),
                            onGallery: () => pickAttachment(ImageSource.gallery),
                            onRemove: () => setState(() {
                              attachmentFile = null;
                              attachmentName = '';
                            }),
                          ),
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

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DateField({required this.controller, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _AttachmentBox extends StatelessWidget {
  final bool requiredAttachment;
  final File? file;
  final String fileName;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _AttachmentBox({
    required this.requiredAttachment,
    required this.file,
    required this.fileName,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(requiredAttachment ? Icons.warning_amber_rounded : Icons.attach_file_rounded, color: requiredAttachment ? AppColors.orange : AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requiredAttachment ? 'Bukti Pendukung *' : 'Bukti Pendukung',
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            requiredAttachment
                ? 'Wajib untuk pengajuan sakit. Unggah foto surat dokter atau bukti pendukung.'
                : 'Opsional. Unggah foto dokumen pendukung jika tersedia.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          if (file != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(file!, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
