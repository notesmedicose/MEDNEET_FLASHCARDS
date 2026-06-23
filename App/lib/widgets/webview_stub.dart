import 'package:flutter/material.dart';

abstract class PlatformWebViewController {
  void reload();
}

class PlatformWebView extends StatefulWidget {
  final String url;
  final String tabLabel;
  final Function(String) onPageStarted;
  final Function(int) onProgress;
  final Function(String) onPageFinished;
  final Function() onWebResourceError;
  final Function(PlatformWebViewController) onControllerCreated;

  const PlatformWebView({
    super.key,
    required this.url,
    required this.tabLabel,
    required this.onPageStarted,
    required this.onProgress,
    required this.onPageFinished,
    required this.onWebResourceError,
    required this.onControllerCreated,
  });

  @override
  State<PlatformWebView> createState() => _PlatformWebViewState();
}

class _PlatformWebViewState extends State<PlatformWebView> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('Unsupported platform');
  }
}
