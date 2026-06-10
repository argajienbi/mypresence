import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/error_mapper.dart';
import '../../core/models/app_session.dart';
import '../../core/utils.dart';
import '../../services/attendance_service.dart';
import '../../services/photo_quality_service.dart';
import '../../widgets/app_feedback.dart';

class CameraPresencePage extends StatefulWidget {
  final AppSession session;
  final String actionType;

  const CameraPresencePage(
      {super.key, required this.session, required this.actionType});

  @override
  State<CameraPresencePage> createState() => _CameraPresencePageState();
}

class _CameraPresencePageState extends State<CameraPresencePage>
    with WidgetsBindingObserver {
  final AttendanceService _attendance = AttendanceService();
  final PhotoQualityService _photoQualityService = PhotoQualityService();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  CameraLensDirection _lens = CameraLensDirection.front;
  File? _photo;
  PhotoQualityCheckResult? _photoQuality;
  bool _initializing = true;
  bool _submitting = false;
  bool _capturing = false;
  bool _captureLocked = false;
  bool _cameraTransitioning = false;
  DateTime? _lastCameraActionAt;
  String _status = 'Membuka kamera...';

  bool get _controllerReady => _controller?.value.isInitialized == true;

  bool get _isBusy =>
      _initializing ||
      _submitting ||
      _capturing ||
      _captureLocked ||
      _cameraTransitioning;

  bool _isCameraThrottled() {
    final last = _lastCameraActionAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < const Duration(milliseconds: 900);
  }

  Future<void> _disposeCameraController() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      await controller.dispose();
    } catch (_) {
      // Ignore dispose race during lifecycle changes.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCameraController());
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_disposeCameraController());
    } else if (state == AppLifecycleState.resumed && _photo == null) {
      _initCamera(lens: _lens);
    }
  }

  Future<void> _initCamera(
      {CameraLensDirection lens = CameraLensDirection.front}) async {
    if (_cameraTransitioning || _submitting) return;
    _cameraTransitioning = true;
    if (mounted) {
      setState(() {
        _initializing = true;
        _status = 'Membuka kamera...';
        _lens = lens;
      });
    }

    CameraController? newController;
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw Exception('Kamera tidak ditemukan.');

      final selected = _cameras.firstWhere(
        (camera) => camera.lensDirection == lens,
        orElse: () => _cameras.first,
      );

      await _disposeCameraController();
      newController = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await newController.initialize();
      await newController.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (!mounted) {
        await newController.dispose();
        return;
      }
      setState(() {
        _controller = newController;
        _initializing = false;
        _status = 'Posisikan wajah di dalam oval';
      });
    } catch (e) {
      if (newController != null) {
        try {
          await newController.dispose();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _status = friendlyError(e);
      });
      AppToast.error(context, friendlyError(e));
    } finally {
      _cameraTransitioning = false;
    }
  }

  Future<void> _switchCamera() async {
    if (_isBusy || _isCameraThrottled()) return;
    if (_photo != null) {
      await _retake();
      return;
    }

    _lastCameraActionAt = DateTime.now();
    final next = _lens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    await _initCamera(lens: next);
  }

  Future<void> _capture() async {
    if (_capturing ||
        _submitting ||
        _captureLocked ||
        _initializing ||
        _cameraTransitioning ||
        _isCameraThrottled()) {
      return;
    }

    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      AppToast.error(
          context, 'Kamera belum siap. Jangan tekan tombol berulang.');
      return;
    }

    _lastCameraActionAt = DateTime.now();
    setState(() {
      _captureLocked = true;
      _capturing = true;
      _status = 'Mengambil foto...';
    });

    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      final captured = File(file.path);
      final quality = await _photoQualityService.validate(captured);
      if (!mounted) return;
      if (!quality.isValid) {
        AppToast.error(context, quality.message);
        setState(() {
          _photo = null;
          _photoQuality = null;
          _status = quality.message;
        });
        return;
      }
      setState(() {
        _photo = captured;
        _photoQuality = quality;
        _status = quality.hasWarning
            ? quality.message
            : 'Foto berhasil diambil. Periksa hasilnya.';
      });
    } catch (e) {
      if (!mounted) return;
      final message = friendlyError(e);
      AppToast.error(context, message);
      setState(() => _status = message);
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
          _captureLocked = false;
        });
      } else {
        _capturing = false;
        _captureLocked = false;
      }
    }
  }

  Future<void> _retake() async {
    if (_capturing ||
        _submitting ||
        _captureLocked ||
        _initializing ||
        _cameraTransitioning ||
        _isCameraThrottled()) {
      return;
    }
    _lastCameraActionAt = DateTime.now();
    setState(() {
      _photo = null;
      _photoQuality = null;
      _status = 'Posisikan wajah di dalam oval';
    });

    if (_controller == null || !_controller!.value.isInitialized) {
      await _initCamera(lens: _lens);
    }
  }

  Future<void> _submit() async {
    if (_photo == null) {
      AppToast.error(context, 'Ambil foto terlebih dahulu.');
      return;
    }

    if (_submitting || _cameraTransitioning) return;

    setState(() {
      _submitting = true;
      _status = 'Mengunggah presensi...';
    });

    try {
      final result = await _attendance.submitSelfieAttendance(
        session: widget.session,
        actionType: widget.actionType,
        photoFile: _photo!,
        photoQuality: _photoQuality,
      );
      if (!mounted) return;
      if (result.hasWarnings) {
        AppToast.info(
          context,
          'Presensi berhasil dikirim dengan catatan validasi. ${result.warnings.join(' ')}',
        );
      } else {
        AppToast.success(context, 'Presensi berhasil dikirim.');
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, friendlyError(e));
      setState(() => _status = friendlyError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _cameraPreview() {
    if (_photo != null) {
      return Image.file(_photo!,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }

    final controller = _controller;
    if (_initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF1E293B),
        child:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) {
          return const ColoredBox(color: Color(0xFF1E293B));
        }

        final previewRatio = previewSize.height / previewSize.width;
        final screenRatio = constraints.maxWidth / constraints.maxHeight;
        final scale = previewRatio / screenRatio;

        return ClipRect(
          child: Transform.scale(
            scale: scale < 1 ? 1 / scale : scale,
            child: Center(child: CameraPreview(controller)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.actionType == 'pulang' ? 'Absen Pulang' : 'Absen Masuk';
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const bottomSheetHeight = 176.0;
    final topInset = MediaQuery.of(context).padding.top;
    final guideTop = topInset + 96.0;

    return AppLoadingOverlay(
      visible: _submitting,
      message: 'Mengunggah foto dan data presensi...',
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _cameraPreview(),
            Container(color: Colors.black.withValues(alpha: .14)),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _TopCameraHeader(
                title: title,
                onBack: _isBusy ? null : () => Navigator.of(context).pop(),
                onSwitch: _isBusy ? null : _switchCamera,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: guideTop,
              bottom: bottomSheetHeight + bottomPadding + 72,
              child: Center(
                child: IgnorePointer(
                  child: Container(
                    width: 196,
                    height: 258,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF8ED5F6), width: 3),
                      borderRadius: BorderRadius.circular(150),
                      boxShadow: [
                        BoxShadow(
                            color:
                                const Color(0xFF8ED5F6).withValues(alpha: .30),
                            blurRadius: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: bottomSheetHeight + bottomPadding + 16,
              child: _StatusPill(status: _status),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CameraBottomSheet(
                officeName: widget.session.officeName,
                photoTaken: _photo != null,
                photoQuality: _photoQuality,
                canInteract: !_isBusy,
                canSubmit: _photo == null ? _controllerReady : true,
                capturing: _capturing,
                onSwitchOrRetake: _photo == null ? _switchCamera : _retake,
                onCaptureOrSubmit: _photo == null ? _capture : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCameraHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onSwitch;

  const _TopCameraHeader(
      {required this.title, required this.onBack, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          child: Row(
            children: [
              _GlassIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                  ),
                ),
              ),
              _GlassIconButton(
                  icon: Icons.cameraswitch_rounded, onTap: onSwitch),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .52),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.face_retouching_natural_rounded,
              color: AppColors.green, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraBottomSheet extends StatelessWidget {
  final String officeName;
  final bool photoTaken;
  final PhotoQualityCheckResult? photoQuality;
  final bool canInteract;
  final bool canSubmit;
  final bool capturing;
  final VoidCallback onSwitchOrRetake;
  final VoidCallback onCaptureOrSubmit;

  const _CameraBottomSheet({
    required this.officeName,
    required this.photoTaken,
    required this.photoQuality,
    required this.canInteract,
    required this.canSubmit,
    required this.capturing,
    required this.onSwitchOrRetake,
    required this.onCaptureOrSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final hasWarning = photoQuality?.hasWarning == true;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          officeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.text),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(AppDate.time(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text)),
              ],
            ),
            if (hasWarning) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.orange.withValues(alpha: .18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.orange, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        photoQuality?.message ?? '',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: canInteract ? onSwitchOrRetake : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: hasWarning
                            ? AppColors.orange.withValues(alpha: .10)
                            : Colors.white,
                        foregroundColor:
                            hasWarning ? AppColors.orange : AppColors.text,
                        side: BorderSide(
                            color:
                                hasWarning ? AppColors.orange : AppColors.line),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: Icon(
                        photoTaken
                            ? Icons.refresh_rounded
                            : Icons.cameraswitch_rounded,
                        color: hasWarning ? AppColors.orange : AppColors.text,
                        size: 18,
                      ),
                      label: Text(
                        photoTaken ? 'Ulangi Foto' : 'Ganti Kamera',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasWarning ? AppColors.orange : AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(42),
                  onTap: canInteract && canSubmit ? onCaptureOrSubmit : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: photoTaken
                          ? (canInteract
                              ? AppColors.green
                              : AppColors.green.withValues(alpha: .35))
                          : (canInteract
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: .35)),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (photoTaken ? AppColors.green : AppColors.primary)
                                  .withValues(alpha: .32),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: capturing
                        ? const Padding(
                            padding: EdgeInsets.all(21),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3))
                        : Icon(
                            photoTaken
                                ? Icons.cloud_upload_rounded
                                : Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 33),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              photoTaken
                  ? 'Periksa hasil foto, lalu kirim presensi.'
                  : 'Pastikan wajah berada di tengah oval.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white.withValues(alpha: .10)
              : Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
        ),
        child: Icon(icon,
            color: onTap == null ? Colors.white54 : Colors.white, size: 22),
      ),
    );
  }
}
