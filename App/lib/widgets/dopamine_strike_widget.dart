import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── Confetti Particle Model ──
class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  double size;
  Color color;
  double alpha = 1.0;
  final double drag = 0.98;
  final double gravity = 0.2;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });

  void update() {
    x += vx;
    y += vy;
    vy += gravity;
    vx *= drag;
    vy *= drag;
    rotation += rotationSpeed;
    alpha = max(0.0, alpha - 0.012);
  }
}

// ── Particle Confetti Painter ──
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final Random _rand = Random();

  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (particle.alpha <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);

      // Render rectangular confetti
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRect(rect, paint);
      
      // Draw tiny sparkles
      if (_rand.nextBool()) {
        final sparklePaint = Paint()
          ..color = Colors.white.withOpacity(particle.alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(particle.size, particle.size), 1.5, sparklePaint);
      }
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Confetti Widget ──
class ConfettiOverlayWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const ConfettiOverlayWidget({super.key, required this.onComplete});

  @override
  State<ConfettiOverlayWidget> createState() => _ConfettiOverlayWidgetState();
}

class _ConfettiOverlayWidgetState extends State<ConfettiOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();
  final List<Color> _colors = [
    AppTheme.accentGreen,
    AppTheme.accentTeal,
    AppTheme.accentBlue,
    AppTheme.accentPurple,
    Colors.yellowAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {
          for (final particle in _particles) {
            particle.update();
          }
        });
      });

    _controller.forward().then((_) => widget.onComplete());
    _spawnParticles();
  }

  void _spawnParticles() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      // Burst from left and right sides
      for (int i = 0; i < 60; i++) {
        // Left side launcher
        _particles.add(_createLauncherParticle(0, size.height * 0.65, 45));
        // Right side launcher
        _particles.add(_createLauncherParticle(size.width, size.height * 0.65, 135));
      }
    });
  }

  ConfettiParticle _createLauncherParticle(double x, double y, double baseAngleDegrees) {
    // Angle variance of 30 degrees
    final angle = (baseAngleDegrees + (_random.nextDouble() * 40 - 20)) * pi / 180;
    final speed = 8.0 + _random.nextDouble() * 14.0;
    
    return ConfettiParticle(
      x: x,
      y: y,
      vx: cos(angle) * speed * (x == 0 ? 1 : -1),
      vy: -sin(angle) * speed - 2.0, // upwards bias
      rotation: _random.nextDouble() * pi * 2,
      rotationSpeed: (_random.nextDouble() * 0.2 - 0.1),
      size: 8.0 + _random.nextDouble() * 8.0,
      color: _colors[_random.nextInt(_colors.length)],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: ConfettiPainter(particles: _particles),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ── Daily Streak Dopamine Dialog ──
class DopamineStreakDialog extends StatefulWidget {
  final int streakCount;
  const DopamineStreakDialog({super.key, this.streakCount = 5});

  @override
  State<DopamineStreakDialog> createState() => _DopamineStreakDialogState();
}

class _DopamineStreakDialogState extends State<DopamineStreakDialog>
    with SingleTickerProviderStateMixin {
  bool _showConfetti = true;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start progress bar animation after popup shows
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Background Glow ──
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            height: 480,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withOpacity(0.12),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),

          // ── Main Card Container ──
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.cardBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                // ── Glowing Flame Ring ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.2, 1.2),
                          duration: 1200.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(duration: 1200.ms),

                    // Fire icon base
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFF8C00), Color(0xFFFF3D00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.3, 0.3),
                          end: const Offset(1.0, 1.0),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        )
                        .shake(duration: 800.ms, hz: 4),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Streak text ──
                Text(
                  '${widget.streakCount} DAY STREAK!',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Your daily NEET prep is on fire! 🔥',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 28),

                // ── XP & Level Progression ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level 4 Aspirant',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    Text(
                      '+50 XP Claimed! 🎉',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentTeal,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),

                // Progress Bar
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    // Start progress is 0.70, ends at 0.85 (+15%)
                    final progress = 0.70 + (_progressController.value * 0.15);
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 14,
                            width: double.infinity,
                            color: AppTheme.primaryDark,
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.accentGreen, AppTheme.accentTeal],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${(progress * 500).toInt()} / 500 XP',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── Motivation Quote ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.cardBorder.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Colors.yellowAccent, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '"Success is the sum of small efforts, repeated day in and day out."',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 24),

                // ── CTA button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'LET\'S CRUSH IT!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.03, 1.03),
                      duration: 1000.ms,
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
          ),

          // ── Particle Confetti ──
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiOverlayWidget(
                onComplete: () {
                  setState(() {
                    _showConfetti = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
