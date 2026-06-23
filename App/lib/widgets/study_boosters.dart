import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── Study Mnemonics Model ──
class Mnemonic {
  final String title;
  final String phrase;
  final String standsFor;
  final String subject;

  const Mnemonic({
    required this.title,
    required this.phrase,
    required this.standsFor,
    required this.subject,
  });
}

class StudyBoostersWidget extends StatefulWidget {
  final Function(int xpGained) onXpGained;

  const StudyBoostersWidget({super.key, required this.onXpGained});

  @override
  State<StudyBoostersWidget> createState() => _StudyBoostersWidgetState();
}

class _StudyBoostersWidgetState extends State<StudyBoostersWidget> {
  // Timer State
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isDemoMode = false;
  Timer? _timer;

  // Mnemonics Data
  static const List<Mnemonic> _mnemonics = [
    Mnemonic(
      title: 'Essential Amino Acids',
      phrase: 'PVT TIM HALL',
      standsFor: 'Phenylalanine, Valine, Threonine, Tryptophan, Isoleucine, Methionine, Histidine, Arginine, Leucine, Lysine.',
      subject: 'BIOLOGY',
    ),
    Mnemonic(
      title: 'Taxonomic Hierarchy',
      phrase: 'Keep Ponds Clean Or Frogs Get Sick',
      standsFor: 'Kingdom, Phylum, Class, Order, Family, Genus, Species.',
      subject: 'BIOLOGY',
    ),
    Mnemonic(
      title: 'Electrochemical Series (Decreasing Reactivity)',
      phrase: 'Please Stop Calling Me A Cute Zebra',
      standsFor: 'Potassium, Sodium, Calcium, Magnesium, Aluminium, Carbon, Zinc.',
      subject: 'CHEMISTRY',
    ),
  ];

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _secondsRemaining = _isDemoMode ? 10 : 25 * 60;
          });
          _completeSession();
        }
      });
    }
  }

  void _toggleDemoMode() {
    _timer?.cancel();
    setState(() {
      _isDemoMode = !_isDemoMode;
      _isRunning = false;
      _secondsRemaining = _isDemoMode ? 10 : 25 * 60;
    });
  }

  void _completeSession() {
    // Session complete! Reward XP
    final xp = _isDemoMode ? 15 : 100;
    widget.onXpGained(xp);
    
    // Show a snackbar visual reinforcement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentGreen, AppTheme.accentTeal],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Focus Session Complete!',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Outstanding job! You earned +$xp XP 🔥',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryDark.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime() {
    final minutes = (_secondsRemaining / 60).floor();
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    final total = _isDemoMode ? 10 : 25 * 60;
    return (total - _secondsRemaining) / total;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Title ──
        Text(
          'Dopamine Study Boosters',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),

        // ── Row with Timer and Mnemonics ──
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildTimerCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: _buildMnemonicsList()),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildTimerCard(),
                  const SizedBox(height: 20),
                  _buildMnemonicsList(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_10_rounded, color: AppTheme.accentTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Focus Pomodoro',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _toggleDemoMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isDemoMode ? AppTheme.accentPurple.withOpacity(0.15) : AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDemoMode ? AppTheme.accentPurple : AppTheme.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Demo Mode',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isDemoMode ? AppTheme.accentPurple : AppTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Timer Circle ──
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: _getProgress(),
                  strokeWidth: 8,
                  backgroundColor: AppTheme.primaryDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(),
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isRunning ? 'FOCUSING' : 'PAUSED',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _isRunning ? AppTheme.accentGreen : AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Action Buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  _timer?.cancel();
                  setState(() {
                    _isRunning = false;
                    _secondsRemaining = _isDemoMode ? 10 : 25 * 60;
                  });
                },
                icon: const Icon(Icons.replay_rounded),
                color: AppTheme.textSecondary,
                iconSize: 22,
              ),
              const SizedBox(width: 16),
              FloatingActionButton.small(
                onPressed: _toggleTimer,
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: AppTheme.primaryDark,
                shape: const CircleBorder(),
                elevation: 4,
                child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
              )
                  .animate(target: _isRunning ? 1 : 0)
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.08, 1.08),
                    duration: 300.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_stories_rounded, color: AppTheme.accentPurple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Interactive Mnemonics',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mnemonics.length,
            itemBuilder: (context, index) {
              final mn = _mnemonics[index];
              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 12, bottom: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: mn.subject == 'BIOLOGY'
                            ? AppTheme.accentGreen.withOpacity(0.12)
                            : AppTheme.accentPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        mn.subject,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: mn.subject == 'BIOLOGY' ? AppTheme.accentGreen : AppTheme.accentPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mn.title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${mn.phrase}"',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentTeal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      mn.standsFor,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
