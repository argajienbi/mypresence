import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../core/error_mapper.dart';
import '../../core/models/app_session.dart';
import '../../core/utils.dart';
import '../../services/attendance_correction_service.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/soft_header.dart';

class AttendanceCorrectionFormPage extends StatefulWidget {
  final AppSession session;
  final DateTime initialDate;
  final Map<String, dynamic>? oldAttendance;

  const AttendanceCorrectionFormPage({
    super.key,
    required this.session,
    required this.initialDate,
    required this.oldAttendance,
  });

  @override
  State<AttendanceCorrectionFormPage> createState() =>
      _AttendanceCorrectionFormPageState();
}

class _AttendanceCorrectionFormPageState
    extends State<AttendanceCorrectionFormPage> {
  final AttendanceCorrectionService _service = AttendanceCorrectionService();
  final ImagePicker _picker = ImagePicker();
  final _reasonController = TextEditingController();
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  final _dateController = TextEditingController();

  late DateTime _selectedDate;
  Map<String, dynamic>? _attendanceSnapshot;
  String _correctionType = 'masuk';
  bool _loading = false;
  File? _attachmentFile;
  String _attachmentName = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _attendanceSnapshot = widget.oldAttendance;
    _dateController.text = _dateLabel;
    _prefillFromAttendance();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _prefillFromAttendance() {
    final oldAttendance = _attendanceSnapshot;
    final masuk = _nestedMap(oldAttendance?['masuk']);
    final pulang = _nestedMap(oldAttendance?['pulang']);
    final checkIn = _timeValue(masuk);
    final checkOut = _timeValue(pulang);

    _checkInController.text = checkIn;
    _checkOutController.text = checkOut;

    if (checkIn.isNotEmpty && checkOut.isNotEmpty) {
      _correctionType = 'masuk_pulang';
    } else if (checkOut.isNotEmpty) {
      _correctionType = 'pulang';
    } else {
      _correctionType = 'masuk';
    }
  }

  Map<String, dynamic>? _nestedMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  String _timeValue(Map<String, dynamic>? row) {
    if (row == null) return '';
    return asString(row['time'], asString(row['waktu']));
  }

  String get _dateLabel => AppDate.dayDate(_selectedDate);

  String get _dateKey => AppDate.dateKey(_selectedDate);

  bool get _needsCheckIn =>
      _correctionType == 'masuk' || _correctionType == 'masuk_pulang';

  bool get _needsCheckOut =>
      _correctionType == 'pulang' || _correctionType == 'masuk_pulang';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (selected == null) return;
    setState(() {
      _selectedDate = selected;
      _dateController.text = _dateLabel;
    });
    await _refreshAttendanceSnapshot();
  }

  Future<void> _refreshAttendanceSnapshot() async {
    try {
      final snapshot = await _service.getAttendanceMap(
        session: widget.session,
        dateKey: _dateKey,
      );
      if (!mounted) return;
      setState(() {
        _attendanceSnapshot = snapshot;
        _prefillFromAttendance();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attendanceSnapshot = null;
        _prefillFromAttendance();
      });
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final current = _parseTimeOfDay(controller.text) ?? TimeOfDay.now();
    final selected = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (selected == null) return;
    setState(() {
      controller.text =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    });
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickAttachment(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      _attachmentFile = File(picked.path);
      _attachmentName = picked.name.isEmpty
          ? 'correction_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : picked.name;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await _service.submitCorrectionRequest(
        session: widget.session,
        dateKey: _dateKey,
        correctionType: _correctionType,
        reason: _reasonController.text,
        requestedCheckInTime: _checkInController.text,
        requestedCheckOutTime: _checkOutController.text,
        attachmentFile: _attachmentFile,
        attachmentName: _attachmentName,
        oldAttendance: _attendanceSnapshot,
      );
      if (!mounted) return;
      AppToast.success(
        context,
        _hasOldAttendance
            ? 'Pengajuan koreksi berhasil dikirim.'
            : 'Pengajuan koreksi berhasil dikirim. Pantau di Status Pengajuan.',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _hasOldAttendance =>
      _attendanceSnapshot != null && _attendanceSnapshot!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      visible: _loading,
      message: 'Mengirim pengajuan koreksi...',
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
                      title: 'Ajukan Koreksi Presensi',
                      subtitle:
                          'Perbaiki data Clock In atau Clock Out dan kirim ke admin untuk review',
                      icon: Icons.edit_note_rounded,
                      trailing: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .96),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .78),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .09),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FormField(
                            controller: _dateController,
                            label: 'Tanggal',
                            icon: Icons.calendar_month_rounded,
                            onTap: _pickDate,
                            readOnly: true,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Tipe Koreksi',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _TypeChip(
                                label: 'Clock In',
                                selected: _correctionType == 'masuk',
                                onTap: () =>
                                    setState(() => _correctionType = 'masuk'),
                              ),
                              _TypeChip(
                                label: 'Clock Out',
                                selected: _correctionType == 'pulang',
                                onTap: () =>
                                    setState(() => _correctionType = 'pulang'),
                              ),
                              _TypeChip(
                                label: 'Clock In & Clock Out',
                                selected: _correctionType == 'masuk_pulang',
                                onTap: () => setState(
                                    () => _correctionType = 'masuk_pulang'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_needsCheckIn) ...[
                            _FormField(
                              controller: _checkInController,
                              label: 'Jam Clock In yang diajukan',
                              icon: Icons.login_rounded,
                              onTap: () => _pickTime(_checkInController),
                              readOnly: true,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_needsCheckOut) ...[
                            _FormField(
                              controller: _checkOutController,
                              label: 'Jam Clock Out yang diajukan',
                              icon: Icons.logout_rounded,
                              onTap: () => _pickTime(_checkOutController),
                              readOnly: true,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _reasonController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Alasan koreksi',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AttachmentBox(
                            file: _attachmentFile,
                            fileName: _attachmentName,
                            onCamera: () => _pickAttachment(ImageSource.camera),
                            onGallery: () =>
                                _pickAttachment(ImageSource.gallery),
                            onRemove: () => setState(() {
                              _attachmentFile = null;
                              _attachmentName = '';
                            }),
                          ),
                          if (!_hasOldAttendance) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: .14),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Belum ada data presensi pada tanggal ini. Ajukan koreksi jika Anda lupa absen atau data belum tercatat.',
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontSize: 12.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            _OldAttendancePreview(
                                attendance: _attendanceSnapshot!),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Kirim Pengajuan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool readOnly;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w900,
        color: selected ? Colors.white : AppColors.text,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.line,
      ),
    );
  }
}

class _AttachmentBox extends StatelessWidget {
  final File? file;
  final String fileName;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _AttachmentBox({
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
              const Icon(
                Icons.attach_file_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lampiran tambahan',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Opsional. Tambahkan bukti jika diperlukan untuk memudahkan review admin.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (file != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                file!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRemove,
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
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
                  icon: const Icon(Icons.photo_library_rounded),
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

class _OldAttendancePreview extends StatelessWidget {
  final Map<String, dynamic> attendance;

  const _OldAttendancePreview({required this.attendance});

  Map<String, dynamic>? _nestedMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  String _timeOf(Map<String, dynamic>? row) {
    if (row == null) return '--:--';
    return asString(row['time'], asString(row['waktu'], '--:--'));
  }

  String _methodValue(
      Map<String, dynamic>? masuk, Map<String, dynamic>? pulang) {
    final method =
        asString(masuk?['method'], asString(pulang?['method'])).toLowerCase();
    if (method == 'qr') return 'QR';
    if (method == 'selfie') return 'Selfie';
    return '-';
  }

  String _statusValue(
      Map<String, dynamic>? masuk, Map<String, dynamic>? pulang) {
    return asString(
      masuk?['attendance_status'],
      asString(
        masuk?['status'],
        asString(
          pulang?['attendance_status'],
          asString(pulang?['status'], '-'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masuk = _nestedMap(attendance['masuk']);
    final pulang = _nestedMap(attendance['pulang']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presensi Lama',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _PreviewRow(label: 'Clock In', value: _timeOf(masuk)),
          const SizedBox(height: 6),
          _PreviewRow(label: 'Clock Out', value: _timeOf(pulang)),
          const SizedBox(height: 6),
          _PreviewRow(label: 'Metode', value: _methodValue(masuk, pulang)),
          const SizedBox(height: 6),
          _PreviewRow(label: 'Status', value: _statusValue(masuk, pulang)),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
