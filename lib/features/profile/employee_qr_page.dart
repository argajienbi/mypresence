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
import '../../widgets/app_feedback.dart';
import '../../widgets/sticky_curve_layout.dart';

const Color kCardDarkTeal = Color(0xFF053B40);
const Color kCardDeepTeal = Color(0xFF075E66);
const Color kCardTeal = Color(0xFF0797A5);
const Color kCardCyan = Color(0xFF12C7C9);
const Color kCardGreen = Color(0xFF56C943);
const Color kCardSoftGray = Color(0xFFF4F7F8);
const Color kCardWhite = Color(0xFFFFFFFF);

const String _kDefaultCompanyName = 'MYPRESENCE';
const String _kBackSlogan = 'TOGETHER. INNOVATE. GROW.';
const String _kFrontFooterLabel = 'PROFESSIONAL IDENTITY';
const String _kBackFooterLabel = 'SECURE & VERIFIABLE';

const double _kCardRadius = 32;

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
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
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

  String get _resolvedPhotoUrl {
    final candidate = widget.photoUrl?.trim();
    if (candidate != null && candidate.isNotEmpty) return candidate;
    return widget.session.photoUrl.trim();
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = math.min(MediaQuery.of(context).size.width - 72, 310.0);
    final cardHeight = cardWidth * 1.67;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppLoadingOverlay(
        visible: _saving,
        message: 'Menyimpan kartu...',
        child: StickyCurvePage(
          title: 'ID Karyawan',
          subtitle: 'Kartu identitas digital karyawan',
          icon: Icons.badge_rounded,
          overlapTop: 134,
          trailing: _CloseButton(onTap: () => Navigator.pop(context)),
          overlapChild: Center(
            child: _loading
                ? SizedBox(
                    width: cardWidth,
                    height: 540,
                    child: const Center(
                      child: CircularProgressIndicator(color: kCardTeal),
                    ),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
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
                                      payload: _payload,
                                      width: cardWidth,
                                      height: cardHeight,
                                    ),
                                  )
                                : _FrontCard(
                                    session: widget.session,
                                    photoUrl: _resolvedPhotoUrl,
                                    width: cardWidth,
                                    height: cardHeight,
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
          children: [
            const Center(
              child: Text(
                'Tap kartu untuk melihat sisi depan/belakang.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _saveCard(share: false),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCardTeal,
                      foregroundColor: Colors.white,
                      shadowColor: kCardTeal.withValues(alpha: .24),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size.fromHeight(56),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _saveCard(share: true),
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    label: const Text('Bagikan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kCardTeal,
                      side: const BorderSide(color: kCardTeal, width: 1.4),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size.fromHeight(56),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
  final double width;
  final double height;

  const _FrontCard({
    required this.session,
    required this.photoUrl,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = _displayNameForCard(session).toUpperCase();
    final nip = _nipForCard(session);
    final initial = _initialForAvatar(_displayNameForCard(session));
    final headerHeight = math.max(160.0, math.min(height * .40, 214.0));
    final footerHeight = math.max(54.0, math.min(height * .14, 74.0));
    final photoDiameter = math.max(116.0, math.min(width * .48, 150.0));
    final photoTop = headerHeight - photoDiameter * .55;
    final bodyTopPadding = photoDiameter * .5;
    final logoSize = math.max(54.0, math.min(width * .22, 68.0));
    final companyFontSize = math.max(12.0, math.min(width * .043, 15.0));
    final nameFontSize = math.max(22.0, math.min(width * .09, 28.0));
    final nipFontSize = math.max(14.0, math.min(width * .058, 18.0));
    final badgeHeight = math.max(36.0, math.min(width * .14, 44.0));
    final badgeFontSize = math.max(11.5, math.min(width * .045, 14.0));
    final footerFontSize = math.max(10.5, math.min(width * .034, 12.0));

    return _EmployeeCardShell(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _FrontGeometricBackground(headerHeight: headerHeight),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MpLogo(size: logoSize),
                SizedBox(height: math.max(8.0, logoSize * .12)),
                Text(
                  _kDefaultCompanyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: companyFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                    color: Colors.white.withValues(alpha: .97),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: .18),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: photoTop,
            left: (width - photoDiameter) / 2,
            child: _EmployeeCirclePhoto(
              photoUrl: photoUrl,
              initial: initial,
              diameter: photoDiameter,
            ),
          ),
          Positioned.fill(
            top: headerHeight,
            bottom: footerHeight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, bodyTopPadding, 22, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: nameFontSize,
                      height: 1.0,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w900,
                      color: kCardDarkTeal,
                    ),
                  ),
                  SizedBox(height: math.max(8.0, width * .03)),
                  const _TechDivider(),
                  SizedBox(height: math.max(8.0, width * .03)),
                  Text(
                    'NIP $nip',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: nipFontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: kCardDarkTeal.withValues(alpha: .95),
                    ),
                  ),
                  SizedBox(height: math.max(10.0, width * .04)),
                  _ActiveBadge(height: badgeHeight, fontSize: badgeFontSize),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FrontFooterMark(
              height: footerHeight,
              fontSize: footerFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackCard extends StatelessWidget {
  final String payload;
  final double width;
  final double height;

  const _BackCard({
    required this.payload,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final headerHeight = math.max(92.0, math.min(height * .21, 110.0));
    final footerHeight = math.max(54.0, math.min(height * .14, 74.0));
    final qrBoxSize = math.max(180.0, math.min(width * .72, 220.0));
    final qrImageSize = qrBoxSize - 30;
    final companyFontSize = math.max(13.0, math.min(width * .048, 16.0));
    final sloganFontSize = math.max(10.5, math.min(width * .034, 12.0));
    final scanFontSize = math.max(13.0, math.min(width * .042, 16.0));
    final propertyFontSize = math.max(11.5, math.min(width * .038, 13.0));
    final footerFontSize = math.max(10.5, math.min(width * .034, 12.0));

    return _EmployeeCardShell(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _BackGeometricBackground(headerHeight: headerHeight),
          Positioned(
            top: 16,
            left: 18,
            right: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _kDefaultCompanyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: companyFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white.withValues(alpha: .98),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: .18),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: math.max(4.0, width * .015)),
                Text(
                  _kBackSlogan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: sloganFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: Colors.white.withValues(alpha: .90),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            top: headerHeight,
            bottom: footerHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: qrBoxSize,
                      height: qrBoxSize,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kCardWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFDDE7EA),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .12),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: payload.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                color: kCardTeal,
                                size: 76,
                              ),
                            )
                          : QrImageView(
                              data: payload,
                              size: qrImageSize,
                              backgroundColor: Colors.white,
                            ),
                    ),
                    SizedBox(height: math.max(12.0, width * .04)),
                    Text(
                      'SCAN TO VERIFY',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: scanFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: kCardTeal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This ID is the property of\n$_kDefaultCompanyName.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: propertyFontSize,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BackFooterMark(
              height: footerHeight,
              fontSize: footerFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCardShell extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _EmployeeCardShell({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: const Color(0xFFD9E5E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .20),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: child,
      ),
    );
  }
}

class _FrontGeometricBackground extends StatelessWidget {
  final double headerHeight;

  const _FrontGeometricBackground({required this.headerHeight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: kCardWhite,
          ),
        ),
        Positioned.fill(
          top: headerHeight,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kCardWhite, kCardSoftGray],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kCardDarkTeal, kCardDeepTeal],
              ),
            ),
          ),
        ),
        Positioned(
          top: 22,
          right: -26,
          child: SizedBox(
            width: 118,
            height: 118,
            child: CustomPaint(
              painter: _TrianglePatternPainter(
                color: Colors.white.withValues(alpha: .18),
              ),
            ),
          ),
        ),
        Positioned(
          top: 28,
          right: -48,
          child: _DiagonalBar(
            width: 182,
            height: 24,
            angle: -0.60,
            gradient: const LinearGradient(
              colors: [kCardTeal, kCardCyan],
            ),
          ),
        ),
        Positioned(
          top: 70,
          right: -28,
          child: _DiagonalBar(
            width: 160,
            height: 16,
            angle: -0.60,
            gradient: const LinearGradient(
              colors: [kCardCyan, kCardGreen],
            ),
          ),
        ),
        Positioned(
          top: 110,
          left: -28,
          child: _DiagonalBar(
            width: 138,
            height: 14,
            angle: -0.56,
            gradient: const LinearGradient(
              colors: [kCardGreen, kCardTeal],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackGeometricBackground extends StatelessWidget {
  final double headerHeight;

  const _BackGeometricBackground({required this.headerHeight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: kCardSoftGray,
          ),
        ),
        Positioned.fill(
          top: headerHeight,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kCardWhite, kCardSoftGray],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kCardDarkTeal, kCardDeepTeal],
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: -18,
          child: SizedBox(
            width: 106,
            height: 106,
            child: CustomPaint(
              painter: _TrianglePatternPainter(
                color: Colors.white.withValues(alpha: .18),
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: -34,
          child: _DiagonalBar(
            width: 126,
            height: 14,
            angle: -0.58,
            gradient: const LinearGradient(
              colors: [kCardTeal, kCardCyan],
            ),
          ),
        ),
        Positioned(
          top: 54,
          right: -40,
          child: _DiagonalBar(
            width: 176,
            height: 22,
            angle: -0.58,
            gradient: const LinearGradient(
              colors: [kCardCyan, kCardGreen],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiagonalBar extends StatelessWidget {
  final double width;
  final double height;
  final double angle;
  final Gradient gradient;

  const _DiagonalBar({
    required this.width,
    required this.height,
    required this.angle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePatternPainter extends CustomPainter {
  final Color color;

  const _TrianglePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..color = color.withValues(alpha: .44);

    final triangles = <Path>[
      Path()
        ..moveTo(size.width * .58, size.height * .16)
        ..lineTo(size.width * .82, size.height * .26)
        ..lineTo(size.width * .70, size.height * .42)
        ..close(),
      Path()
        ..moveTo(size.width * .34, size.height * .48)
        ..lineTo(size.width * .57, size.height * .58)
        ..lineTo(size.width * .46, size.height * .78)
        ..close(),
      Path()
        ..moveTo(size.width * .66, size.height * .58)
        ..lineTo(size.width * .90, size.height * .70)
        ..lineTo(size.width * .78, size.height * .90)
        ..close(),
    ];

    for (final triangle in triangles) {
      canvas.drawPath(triangle, fill);
      canvas.drawPath(triangle, outline);
    }
  }

  @override
  bool shouldRepaint(covariant _TrianglePatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _MpLogo extends StatelessWidget {
  final double size;

  const _MpLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .72), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: size * .14,
            bottom: size * .16,
            child: Container(
              width: size * .18,
              height: size * .18,
              decoration: const BoxDecoration(
                color: kCardGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Text(
            'MP',
            style: TextStyle(
              fontSize: size * .34,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              color: kCardDarkTeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCirclePhoto extends StatelessWidget {
  final String photoUrl;
  final String initial;
  final double diameter;

  const _EmployeeCirclePhoto({
    required this.photoUrl,
    required this.initial,
    required this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    final value = photoUrl.trim();
    return Container(
      width: diameter,
      height: diameter,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipOval(
        child: value.isNotEmpty
            ? Image.network(
                value,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _InitialAvatar(initial: initial, size: diameter - 10),
              )
            : _InitialAvatar(initial: initial, size: diameter - 10),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  final double size;

  const _InitialAvatar({required this.initial, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kCardTeal, kCardDarkTeal],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * .34,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class _TechDivider extends StatelessWidget {
  const _TechDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kCardTeal.withValues(alpha: .10),
                  kCardTeal.withValues(alpha: .55),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: kCardTeal,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kCardCyan.withValues(alpha: .42),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kCardTeal.withValues(alpha: .55),
                  kCardTeal.withValues(alpha: .10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final double height;
  final double fontSize;

  const _ActiveBadge({
    required this.height,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: kCardGreen.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kCardGreen.withValues(alpha: .28), width: 1),
        boxShadow: [
          BoxShadow(
            color: kCardGreen.withValues(alpha: .10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: fontSize + 5,
            color: kCardGreen,
          ),
          const SizedBox(width: 8),
          Text(
            'ACTIVE',
            style: TextStyle(
              fontSize: fontSize,
              color: kCardGreen,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrontFooterMark extends StatelessWidget {
  final double height;
  final double fontSize;

  const _FrontFooterMark({
    required this.height,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CornerSlashClipper(),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [kCardDarkTeal, kCardDeepTeal, kCardTeal],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -22,
              top: 8,
              child: _DiagonalBar(
                width: 92,
                height: 12,
                angle: -0.58,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: .16),
                    Colors.white.withValues(alpha: .08),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -18,
              bottom: 6,
              child: _DiagonalBar(
                width: 112,
                height: 14,
                angle: -0.58,
                gradient: LinearGradient(
                  colors: [
                    kCardGreen.withValues(alpha: .40),
                    kCardCyan.withValues(alpha: .16),
                  ],
                ),
              ),
            ),
            Center(
              child: Text(
                _kFrontFooterLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackFooterMark extends StatelessWidget {
  final double height;
  final double fontSize;

  const _BackFooterMark({
    required this.height,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CornerSlashClipper(),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [kCardDarkTeal, kCardDeepTeal, kCardGreen],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              top: 5,
              child: _DiagonalBar(
                width: 96,
                height: 12,
                angle: -0.58,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: .16),
                    Colors.white.withValues(alpha: .08),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -18,
              bottom: 8,
              child: _DiagonalBar(
                width: 118,
                height: 14,
                angle: -0.58,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: .12),
                    Colors.white.withValues(alpha: .06),
                  ],
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: fontSize + 5,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _kBackFooterLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.9,
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

class _CornerSlashClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * .22)
      ..lineTo(size.width * .16, 0)
      ..lineTo(size.width * .86, 0)
      ..lineTo(size.width, size.height * .18)
      ..lineTo(size.width, size.height * .82)
      ..lineTo(size.width * .84, size.height)
      ..lineTo(size.width * .10, size.height)
      ..lineTo(0, size.height * .78)
      ..close();
  }

  @override
  bool shouldReclip(covariant _CornerSlashClipper oldClipper) => false;
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .78)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.close_rounded,
            color: kCardDarkTeal,
            size: 20,
          ),
        ),
      ),
    );
  }
}

String _displayNameForCard(AppSession session) {
  final value = session.displayName.trim();
  return value.isEmpty ? '-' : value;
}

String _nipForCard(AppSession session) {
  final value = session.nip.trim();
  return value.isEmpty ? '-' : value;
}

String _initialForAvatar(String source) {
  final value = source.trim();
  if (value.isEmpty || value == '-') return 'MP';
  final parts = value.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'MP';
  if (parts.length == 1) {
    final first = parts.first;
    return first.isEmpty ? 'MP' : first.substring(0, 1).toUpperCase();
  }
  return parts.take(2).map((e) => e.substring(0, 1)).join().toUpperCase();
}
