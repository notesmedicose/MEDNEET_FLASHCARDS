import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'webview_stub.dart';
export 'webview_stub.dart' show PlatformWebViewController;

class PlatformWebViewWebController implements PlatformWebViewController {
  final html.IFrameElement iframe;
  PlatformWebViewWebController(this.iframe);

  @override
  void reload() {
    // Reload iframe by resetting its src
    final src = iframe.src;
    iframe.src = src;
  }
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
  late final html.IFrameElement _iframe;
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    // Unique ID for each web view instance
    _viewId = 'iframe-${widget.tabLabel.replaceAll(' ', '-').toLowerCase()}';
    
    _iframe = html.IFrameElement()
      ..src = widget.url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // Trigger onPageStarted
    widget.onPageStarted(widget.url);
    
    // Listen to iframe load event to fire onPageFinished
    _iframe.onLoad.listen((event) {
      widget.onProgress(100);
      widget.onPageFinished(widget.url);
    });

    // Register platform view factory
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframe,
    );

    widget.onControllerCreated(PlatformWebViewWebController(_iframe));
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
