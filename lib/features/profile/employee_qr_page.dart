import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../services/qr_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/sticky_curve_layout.dart';

class EmployeeQrPage extends StatefulWidget {
  final AppSession session;
  final String? photoUrl;

  const EmployeeQrPage({super.key, required this.session, this.photoUrl});

  @override
  State<EmployeeQrPage> createState() => _EmployeeQrPageState();
}

class _EmployeeQrPageState extends State<EmployeeQrPage>
    with SingleTickerProviderStateMixin {
  final QrService _qr = QrService();
  final GlobalKey _cardKey = GlobalKey();
  late final AnimationController _controller;
  String _payload = '';
  bool _loading = true;
  bool _saving = false;
  bool _back = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 540));
    _loadQr();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadQr() async {
    try {
      final token = await _qr.ensureQrToken(widget.session);
      if (!mounted) return;
      setState(() {
        _payload = _qr.employeeQrPayload(widget.session, token);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _flip() {
    setState(() => _back = !_back);
    if (_back) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Future<File> _captureCard() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Kartu belum siap untuk disimpan.');
    final image = await boundary.toImage(pixelRatio: 4);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Gagal membuat gambar kartu.');
    final bytes = byteData.buffer.asUint8List();
    final dir = await getApplicationDocumentsDirectory();
    final side = _back ? 'belakang_qr' : 'depan';
    final safeNip = widget.session.nip.isEmpty
        ? 'karyawan'
        : widget.session.nip.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/mypresence_id_${safeNip}_$side.png');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _saveCard({required bool share}) async {
    if (_loading || _saving) return;
    setState(() => _saving = true);
    try {
      final file = await _captureCard();
      if (!mounted) return;
      if (share) {
        await Share.shareXFiles([XFile(file.path)],
            text: 'ID Karyawan MYPRESENCE');
      } else {
        AppToast.success(context, 'Kartu tersimpan: ${file.path}');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppLoadingOverlay(
        visible: _saving,
        message: 'Menyimpan kartu...',
        child: StickyCurvePage(
          title: 'ID Karyawan',
          subtitle: 'Tap kartu untuk membalik nametag',
          icon: Icons.badge_rounded,
          overlapTop: 132,
          trailing: SourceRoundButton(
              icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
          overlapChild: Center(
            child: _loading
                ? const SizedBox(
                    height: 430,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)))
                : GestureDetector(
                    onTap: _flip,
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final angle = _controller.value * math.pi;
                          final showBack = angle > math.pi / 2;
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, .0013)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: showBack
                                ? Transform(
                                    transform: Matrix4.identity()
                                      ..rotateY(math.pi),
                                    alignment: Alignment.center,
                                    child: _BackCard(
                                        session: widget.session,
                                        payload: _payload),
                                  )
                                : _FrontCard(
                                    session: widget.session,
                                    photoUrl: widget.photoUrl ??
                                        widget.session.photoUrl),
                          );
                        },
                      ),
                    ),
                  ),
          ),
          children: [
            const Center(
              child: Text('Tap kartu untuk melihat sisi depan/belakang.',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _saveCard(share: false),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        minimumSize: const Size.fromHeight(52)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _saveCard(share: true),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Bagikan'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        minimumSize: const Size.fromHeight(52)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrontCard extends StatelessWidget {
  final AppSession session;
  final String photoUrl;

  const _FrontCard({required this.session, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final initial = session.displayName.isEmpty
        ? 'MP'
        : session.displayName.trim()[0].toUpperCase();
    return _BadgeShell(
      accent: AppColors.primary,
      watermark: 'ID',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on_rounded,
                      color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('MYPRESENCE',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(18)),
                child: const Text('ACTIVE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.green)),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: 136,
            height: 158,
            decoration: BoxDecoration(
                color: AppColors.header,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 18,
                      offset: const Offset(0, 8))
                ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: photoUrl.isNotEmpty
                  ? Image.network(photoUrl, fit: BoxFit.cover)
                  : Center(
                      child: Text(initial,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 44,
                              fontWeight: FontWeight.w900))),
            ),
          ),
          const SizedBox(height: 18),
          Text(session.displayName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 20,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text)),
          const SizedBox(height: 6),
          Text('NIP: ${session.nip.isEmpty ? '-' : session.nip}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.muted)),
          const SizedBox(height: 12),
          _Badge(text: session.position),
          const Spacer(),
          _SmallLine(icon: Icons.business_rounded, text: session.officeName),
          _SmallLine(
              icon: Icons.groups_rounded,
              text: session.groupName.isEmpty ? '-' : session.groupName),
        ],
      ),
    );
  }
}

class _BackCard extends StatelessWidget {
  final AppSession session;
  final String payload;

  const _BackCard({required this.session, required this.payload});

  @override
  Widget build(BuildContext context) {
    return _BadgeShell(
      accent: AppColors.blue,
      watermark: 'QR',
      child: Column(
        children: [
          const Text('QR KARYAWAN',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          const Text('Digunakan untuk titip absen dengan approval admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 14,
                      offset: const Offset(0, 6))
                ]),
            child: QrImageView(
                data: payload, size: 205, backgroundColor: Colors.white),
          ),
          const Spacer(),
          const Text('Jika kartu ini ditemukan,',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 4),
          const Text('mohon dikembalikan kepada HR/Admin perusahaan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _BadgeShell extends StatelessWidget {
  final Widget child;
  final Color accent;
  final String watermark;

  const _BadgeShell(
      {required this.child, required this.accent, required this.watermark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 450,
      child: LayeredCurveCard(
        radius: 36,
        padding: EdgeInsets.zero,
        layerColor: accent.withValues(alpha: .20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        const Color(0xFFF5FDFF),
                        accent.withValues(alpha: .08)
                      ]).asBoxDecoration(),
                ),
              ),
              Positioned(
                  right: -36,
                  top: -24,
                  child:
                      _Circle(size: 128, color: accent.withValues(alpha: .10))),
              Positioned(
                  left: -32,
                  bottom: -28,
                  child:
                      _Circle(size: 112, color: accent.withValues(alpha: .08))),
              Positioned(
                  right: 16,
                  bottom: 16,
                  child: Text(watermark,
                      style: TextStyle(
                          fontSize: 62,
                          fontWeight: FontWeight.w900,
                          color: accent.withValues(alpha: .055)))),
              Padding(padding: const EdgeInsets.all(18), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

extension _GradientDecoration on LinearGradient {
  BoxDecoration asBoxDecoration() => BoxDecoration(gradient: this);
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text.isEmpty ? 'USER' : text,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w900)),
    );
  }
}

class _SmallLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}
