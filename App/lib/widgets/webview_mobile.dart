import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import 'webview_stub.dart';
export 'webview_stub.dart' show PlatformWebViewController;

class PlatformWebViewMobileController implements PlatformWebViewController {
  final WebViewController controller;
  PlatformWebViewMobileController(this.controller);

  @override
  void reload() {
    controller.reload();
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
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppTheme.primaryDark)
        ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              widget.onPageStarted(url);
            },
            onProgress: (progress) {
              widget.onProgress(progress);
            },
            onPageFinished: (url) {
              // Inject CSS to hide web navigation and make it feel native
              _controller?.runJavaScript('''
                (function() {
                  var style = document.createElement('style');
                  style.textContent = ''
                    + 'nav, header, .navbar, .header, .nav-bar,'
                    + '[class*="navbar"], [class*="header-nav"],'
                    + '[class*="HeaderMenu"], [class*="bottom-nav"],'
                    + 'footer, .footer { display: none !important; }'
                    + 'body { padding-bottom: 100px !important; -webkit-overflow-scrolling: touch !important; }'
                    + 'html { scroll-behavior: smooth; }'
                    + '* { -webkit-tap-highlight-color: transparent; -webkit-touch-callout: none; }';
                  document.head.appendChild(style);
                  document.body.style.backgroundColor = '#0A0E21';
                })();
              ''');
              widget.onPageFinished(url);
            },
            onWebResourceError: (error) {
              widget.onWebResourceError();
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));

      widget.onControllerCreated(PlatformWebViewMobileController(_controller!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _buildWindowsFallback();
    }
    return WebViewWidget(controller: _controller!);
  }

  Widget _buildWindowsFallback() {
    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.cardBorder.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.desktop_windows_rounded,
                  color: AppTheme.accentGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MedNotes Study Panel',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You are currently viewing the desktop app. For a seamless full-screen study experience on Windows, click the button below to open the official study portal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.url,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Process.run('cmd', ['/c', 'start', widget.url]);
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open in Browser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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
