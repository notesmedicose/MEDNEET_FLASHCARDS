import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'preloader.dart';

import 'webview_stub.dart'
    if (dart.library.io) 'webview_mobile.dart'
    if (dart.library.html) 'webview_web.dart';

class WebViewFrame extends StatefulWidget {
  final String url;
  final String tabLabel;

  const WebViewFrame({
    super.key,
    required this.url,
    required this.tabLabel,
  });

  @override
  State<WebViewFrame> createState() => WebViewFrameState();
}

class WebViewFrameState extends State<WebViewFrame>
    with AutomaticKeepAliveClientMixin {
  PlatformWebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  double _loadingProgress = 0.0;

  @override
  bool get wantKeepAlive => true;

  void reload() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    _controller?.reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(
            color: AppTheme.cardBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // ── Progress Bar ──
            if (_isLoading)
              _buildProgressBar(),

            // ── Content ──
            Expanded(
              child: Stack(
                children: [
                  // Platform Web View
                  PlatformWebView(
                    url: widget.url,
                    tabLabel: widget.tabLabel,
                    onPageStarted: (url) {
                      if (mounted) {
                        setState(() {
                          _isLoading = true;
                          _hasError = false;
                          _loadingProgress = 0.0;
                        });
                      }
                    },
                    onProgress: (progress) {
                      if (mounted) {
                        setState(() {
                          _loadingProgress = progress / 100.0;
                        });
                      }
                    },
                    onPageFinished: (url) {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    onWebResourceError: () {
                      if (mounted) {
                        setState(() {
                          _hasError = true;
                          _isLoading = false;
                        });
                      }
                    },
                    onControllerCreated: (controller) {
                      _controller = controller;
                    },
                  ),

                  // Preloader overlay
                  if (_isLoading)
                    Positioned.fill(
                      child: MedNotesPreloader(
                        tabLabel: widget.tabLabel,
                      ),
                    ),

                  // Error overlay
                  if (_hasError)
                    Positioned.fill(
                      child: _buildErrorView(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: LinearProgressIndicator(
        value: _loadingProgress > 0 ? _loadingProgress : null,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.accentGreen.withOpacity(0.8),
        ),
        minHeight: 3,
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: AppTheme.primaryDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorRed.withOpacity(0.1),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppTheme.errorRed.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection\nand try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: reload,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: AppTheme.primaryDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
