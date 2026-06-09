import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_theme.dart';
import '../../core/error_mapper.dart';
import '../../core/models/app_session.dart';
import '../../core/utils.dart';
import '../../services/qr_service.dart';
import '../../widgets/app_feedback.dart';
import 'proxy_qr_camera_page.dart';

class ProxyAttendancePage extends StatefulWidget {
  final AppSession session;
  const ProxyAttendancePage({super.key, required this.session});

  @override
  State<ProxyAttendancePage> createState() => _ProxyAttendancePageState();
}

class _ProxyAttendancePageState extends State<ProxyAttendancePage> {
  final QrService _qr = QrService();
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  Map<String, dynamic>? target;
  bool loading = false;
  bool pausedAfterScan = false;
  String actionType = 'masuk';
  String error = '';

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty || loading || pausedAfterScan) return;
    final raw = capture.barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;

    setState(() {
      loading = true;
      error = '';
      pausedAfterScan = true;
    });

    try {
      await _scanner.stop();
      final targetMap = await _qr.validateTargetQr(widget.session, raw);
      setState(() => target = targetMap);
      if (!mounted) return;
      AppToast.success(context, 'QR karyawan valid.');
    } catch (e) {
      final msg = friendlyError(e);
      setState(() {
        error = msg;
        target = null;
      });
      if (mounted) AppToast.error(context, msg);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() => pausedAfterScan = false);
        await _scanner.start();
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resetScan() async {
    setState(() {
      target = null;
      error = '';
      pausedAfterScan = false;
      loading = false;
    });
    await _scanner.start();
  }

  Future<void> _continueToPhoto() async {
    if (target == null || loading) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      await _scanner.stop();
      if (!mounted) return;

      final submitted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ProxyQrCameraPage(
            session: widget.session,
            target: target!,
            actionType: actionType,
          ),
        ),
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (submitted == true) {
        Navigator.pop(context);
      }
    } catch (e) {
      final msg = friendlyError(e);
      if (mounted) {
        setState(() {
          loading = false;
          error = msg;
        });
        AppToast.error(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      visible: loading,
      message: target == null ? 'Memvalidasi QR...' : 'Menyiapkan kamera...',
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: const Text('Titip Absen QR',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(controller: _scanner, onDetect: _onDetect),
                  Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: target == null
                                ? const Color(0xFF78BFF2)
                                : AppColors.green,
                            width: 3),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 36,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .58),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          target == null
                              ? 'Arahkan kamera ke QR karyawan'
                              : 'QR valid: ${asString(target?['nama_lengkap'])}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 14),
                  if (target == null)
                    const Text(
                        'Scan QR karyawan yang dibantu. Request akan masuk ke admin untuk validasi.',
                        textAlign: TextAlign.center,
                        style: AppText.subtitle)
                  else
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: .12),
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(asString(target?['nama_lengkap'], '-'),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text,
                                      fontSize: 16)),
                              Text('NIP: ${asString(target?['nip'], '-')}',
                                  style: const TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        TextButton(
                            onPressed: _resetScan, child: const Text('Ulangi')),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Masuk'),
                          selected: actionType == 'masuk',
                          selectedColor:
                              AppColors.primary.withValues(alpha: .18),
                          onSelected: loading
                              ? null
                              : (_) => setState(() => actionType = 'masuk'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pulang'),
                          selected: actionType == 'pulang',
                          selectedColor:
                              AppColors.primary.withValues(alpha: .18),
                          onSelected: loading
                              ? null
                              : (_) => setState(() => actionType = 'pulang'),
                        ),
                      ),
                    ],
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.red, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          target == null || loading ? null : _continueToPhoto,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      child: const Text('Lanjut Ambil Foto',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900)),
                    ),
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
