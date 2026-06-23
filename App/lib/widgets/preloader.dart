import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── ECG Heartbeat Sweep Painter ──
class EkgPainter extends CustomPainter {
  final double sweepValue;
  final Color color;

  EkgPainter({required this.sweepValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final List<Offset> points = [];
    const int numPoints = 150;

    for (int i = 0; i <= numPoints; i++) {
      final x = (i / numPoints) * width;
      double y = centerY;
      final pct = x / width;

      // Heartbeat wave formula based on horizontal position
      if (pct >= 0.30 && pct < 0.33) {
        // P-wave (atrial depolarization - small bump)
        final factor = (pct - 0.30) / 0.03;
        y = centerY - (sin(factor * pi) * (height * 0.08));
      } else if (pct >= 0.36 && pct < 0.39) {
        // Q-wave (ventricular depolarization - small dip)
        final factor = (pct - 0.36) / 0.03;
        y = centerY + (sin(factor * pi) * (height * 0.08));
      } else if (pct >= 0.39 && pct < 0.44) {
        // R-wave (ventricular depolarization - sharp peak)
        final factor = (pct - 0.39) / 0.05;
        y = centerY - (sin(factor * pi) * (height * 0.45));
      } else if (pct >= 0.44 && pct < 0.48) {
        // S-wave (ventricular depolarization - sharp dip)
        final factor = (pct - 0.44) / 0.04;
        y = centerY + (sin(factor * pi) * (height * 0.25));
      } else if (pct >= 0.48 && pct < 0.58) {
        // T-wave (ventricular repolarization - medium bump)
        final factor = (pct - 0.48) / 0.10;
        y = centerY - (sin(factor * pi) * (height * 0.15));
      } else if (pct >= 0.70 && pct < 0.73) {
        // Second heartbeat (P-wave)
        final factor = (pct - 0.70) / 0.03;
        y = centerY - (sin(factor * pi) * (height * 0.08));
      } else if (pct >= 0.76 && pct < 0.79) {
        // Second Q-wave
        final factor = (pct - 0.76) / 0.03;
        y = centerY + (sin(factor * pi) * (height * 0.08));
      } else if (pct >= 0.79 && pct < 0.84) {
        // Second R-wave
        final factor = (pct - 0.79) / 0.05;
        y = centerY - (sin(factor * pi) * (height * 0.45));
      } else if (pct >= 0.84 && pct < 0.88) {
        // Second S-wave
        final factor = (pct - 0.84) / 0.04;
        y = centerY + (sin(factor * pi) * (height * 0.25));
      } else if (pct >= 0.88 && pct < 0.98) {
        // Second T-wave
        final factor = (pct - 0.88) / 0.10;
        y = centerY - (sin(factor * pi) * (height * 0.15));
      }

      points.add(Offset(x, y));
    }

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Draw scanning laser dot at the current sweep value
    final activeX = sweepValue * width;
    double activeY = centerY;
    final pct = activeX / width;

    if (pct >= 0.30 && pct < 0.33) {
      final factor = (pct - 0.30) / 0.03;
      activeY = centerY - (sin(factor * pi) * (height * 0.08));
    } else if (pct >= 0.36 && pct < 0.39) {
      final factor = (pct - 0.36) / 0.03;
      activeY = centerY + (sin(factor * pi) * (height * 0.08));
    } else if (pct >= 0.39 && pct < 0.44) {
      final factor = (pct - 0.39) / 0.05;
      activeY = centerY - (sin(factor * pi) * (height * 0.45));
    } else if (pct >= 0.44 && pct < 0.48) {
      final factor = (pct - 0.44) / 0.04;
      activeY = centerY + (sin(factor * pi) * (height * 0.25));
    } else if (pct >= 0.48 && pct < 0.58) {
      final factor = (pct - 0.48) / 0.10;
      activeY = centerY - (sin(factor * pi) * (height * 0.15));
    } else if (pct >= 0.70 && pct < 0.73) {
      final factor = (pct - 0.70) / 0.03;
      activeY = centerY - (sin(factor * pi) * (height * 0.08));
    } else if (pct >= 0.76 && pct < 0.79) {
      final factor = (pct - 0.76) / 0.03;
      activeY = centerY + (sin(factor * pi) * (height * 0.08));
    } else if (pct >= 0.79 && pct < 0.84) {
      final factor = (pct - 0.79) / 0.05;
      activeY = centerY - (sin(factor * pi) * (height * 0.45));
    } else if (pct >= 0.84 && pct < 0.88) {
      final factor = (pct - 0.84) / 0.04;
      activeY = centerY + (sin(factor * pi) * (height * 0.25));
    } else if (pct >= 0.88 && pct < 0.98) {
      final factor = (pct - 0.88) / 0.10;
      activeY = centerY - (sin(factor * pi) * (height * 0.15));
    }

    final activeDotGlow = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final activeDotInside = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(activeX, activeY), 7.0, activeDotGlow);
    canvas.drawCircle(Offset(activeX, activeY), 3.0, activeDotInside);
  }

  @override
  bool shouldRepaint(covariant EkgPainter oldDelegate) =>
      oldDelegate.sweepValue != sweepValue;
}

// ── Medical Heartbeat Preloader ──
class MedNotesPreloader extends StatefulWidget {
  final String tabLabel;

  const MedNotesPreloader({
    super.key,
    required this.tabLabel,
  });

  @override
  State<MedNotesPreloader> createState() => _MedNotesPreloaderState();
}

class _MedNotesPreloaderState extends State<MedNotesPreloader>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  Timer? _tipsTimer;
  int _currentTipIndex = 0;

  static const List<String> _studyTips = [
    "Tip: Spaced repetition helps move study topics from short-term to long-term memory.",
    "Tip: Practice active recall by asking questions to yourself instead of just reading notes.",
    "Fact: The human body contains 206 bones, but at birth it has around 270!",
    "Fact: Mitochondria are inherited maternally through mitochondria in the egg cell.",
    "Tip: Solve at least 50 MCQs daily to build speed and accuracy for NEET 2026.",
    "Fact: Double-stranded DNA is held together by hydrogen bonds between base pairs."
  ];

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Rotate tips every 3.5 seconds
    _tipsTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _studyTips.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _tipsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryDark,
      child: Column(
        children: [
          const SizedBox(height: 60),

          // ── Beautiful Pulse EKG Animation ──
          Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _sweepController,
              builder: (context, child) {
                return CustomPaint(
                  painter: EkgPainter(
                    sweepValue: _sweepController.value,
                    color: AppTheme.accentGreen,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),

          // ── Pulsing Medical Symbol ──
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentTeal.withOpacity(0.05),
                  border: Border.all(
                    color: AppTheme.accentTeal.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.3, 1.3),
                    duration: 1200.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeOut(duration: 1200.ms),

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardDark,
                  border: Border.all(
                    color: AppTheme.accentTeal.withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentTeal.withOpacity(0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: AppTheme.accentTeal,
                  size: 24,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 1000.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Rotating High-Yield Tips ──
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            alignment: Alignment.center,
            child: KeyedSubtree(
              key: ValueKey<int>(_currentTipIndex),
              child: Text(
                _studyTips[_currentTipIndex],
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1, end: 0, duration: 500.ms)
                .then(delay: 2500.ms)
                .fadeOut(duration: 500.ms),
          ),

          const SizedBox(height: 24),
          const Divider(color: AppTheme.cardBorder, height: 1, indent: 40, endIndent: 40),
          const SizedBox(height: 32),

          // ── Bottom Skeleton Shimmers ──
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildShimmerItem(),
                  const SizedBox(height: 12),
                  _buildShimmerItem(),
                  const SizedBox(height: 12),
                  _buildShimmerItem(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardDark,
      highlightColor: AppTheme.cardBorder,
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 140,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBorder,
                      borderRadius: BorderRadius.circular(4),
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
