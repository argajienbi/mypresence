import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LeafletMapView extends StatefulWidget {
  final double officeLat;
  final double officeLng;
  final double radiusMeter;
  final double? userLat;
  final double? userLng;
  final double? distanceMeter;
  final bool inside;

  const LeafletMapView({super.key, required this.officeLat, required this.officeLng, required this.radiusMeter, required this.userLat, required this.userLng, required this.distanceMeter, required this.inside});

  @override
  State<LeafletMapView> createState() => _LeafletMapViewState();
}

class _LeafletMapViewState extends State<LeafletMapView> {
  late final WebViewController _controller;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) { _loaded = true; _update(); }))
      ..loadFlutterAsset('assets/maps.html');
  }

  @override
  void didUpdateWidget(covariant LeafletMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    if (!_loaded) return;
    final args = [widget.officeLat, widget.officeLng, widget.radiusMeter, widget.userLat, widget.userLng, widget.distanceMeter ?? 0, widget.inside].map(jsonEncode).join(',');
    _controller.runJavaScript('updateMap($args);');
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
