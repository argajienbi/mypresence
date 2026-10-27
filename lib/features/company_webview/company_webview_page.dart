import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../services/company_service.dart';
import '../../widgets/app_card.dart';

class CompanyWebViewPage extends StatefulWidget {
  final AppSession session;

  const CompanyWebViewPage({super.key, required this.session});

  @override
  State<CompanyWebViewPage> createState() => _CompanyWebViewPageState();
}

class _CompanyWebViewPageState extends State<CompanyWebViewPage> {
  final CompanyService _service = CompanyService();
  WebViewController? _controller;
  CompanyWebsiteConfig? _config;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final config = await _service.loadWebsiteConfig(widget.session);
      if (!mounted) return;
      if (!config.available) {
        setState(() {
          _config = config;
          _loading = false;
          _error = 'Website perusahaan belum tersedia.';
        });
        return;
      }
      final uri = config.uri;
      if (uri == null || !config.isAllowed(uri)) {
        setState(() {
          _config = config;
          _loading = false;
          _error = 'Website perusahaan tidak valid. Hubungi admin.';
        });
        return;
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final next = Uri.tryParse(request.url);
              if (next == null || !config.isAllowed(next)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tautan di luar domain perusahaan diblokir.')),
                );
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(uri);

      setState(() {
        _config = config;
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Website perusahaan belum bisa dimuat. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _config?.title.trim().isNotEmpty == true ? _config!.title : 'Website Perusahaan';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _CompanyWebHeader(
            title: title,
            onRefresh: () => _controller?.reload() ?? _load(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: AppCard(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.public_off_rounded, color: AppColors.orange, size: 44),
                                const SizedBox(height: 12),
                                Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 14),
                                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Coba Lagi')),
                              ],
                            ),
                          ),
                        )
                      : WebViewWidget(controller: _controller!),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header teal datar (pola _LeaveFormHeader): AppBar standar tidak dipakai
/// di sini agar halaman ini mengikuti bahasa myadmin.
class _CompanyWebHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const _CompanyWebHeader({required this.title, required this.onRefresh});

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
                child: const Icon(Icons.public_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Refresh',
                child: InkWell(
                  onTap: onRefresh,
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
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
