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
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _controller?.reload() ?? _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
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
    );
  }
}
