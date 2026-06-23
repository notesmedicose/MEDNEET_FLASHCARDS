import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NeetQuestion {
  final String subject;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const NeetQuestion({
    required this.subject,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class DailyQuizCard extends StatefulWidget {
  final Function(int xpGained) onAnswerCorrect;

  const DailyQuizCard({super.key, required this.onAnswerCorrect});

  @override
  State<DailyQuizCard> createState() => _DailyQuizCardState();
}

class _DailyQuizCardState extends State<DailyQuizCard>
    with SingleTickerProviderStateMixin {
  late final NeetQuestion _question;
  int? _selectedIndex;
  bool _isAnswered = false;
  late AnimationController _shakeController;

  static const List<NeetQuestion> _pool = [
    NeetQuestion(
      subject: 'BIOLOGY',
      questionText: 'Which organelle is referred to as the "suicidal bag" of the cell?',
      options: [
        'Ribosomes',
        'Lysosomes',
        'Mitochondria',
        'Golgi Apparatus'
      ],
      correctIndex: 1,
      explanation: 'Lysosomes contain digestive/hydrolytic enzymes. If the cell is damaged, lysosomes burst and digest the cell, hence they are called suicidal bags.',
    ),
    NeetQuestion(
      subject: 'PHYSICS',
      questionText: 'What is the dimensional formula of universal gravitational constant (G)?',
      options: [
        '[M⁻¹ L³ T⁻²]',
        '[M¹ L³ T⁻²]',
        '[M⁻¹ L² T⁻²]',
        '[M⁻² L³ T⁻¹]'
      ],
      correctIndex: 0,
      explanation: 'From F = G * m₁m₂ / r², we get G = F * r² / (m₁m₂). F = [M L T⁻²], r² = [L²], m₁m₂ = [M²]. Thus, G = [M⁻¹ L³ T⁻²].',
    ),
    NeetQuestion(
      subject: 'CHEMISTRY',
      questionText: 'Which of the following compounds has the highest boiling point?',
      options: [
        'n-Pentane',
        'Isopentane',
        'Neopentane',
        'n-Butane'
      ],
      correctIndex: 0,
      explanation: 'Boiling point increases with molecular mass (so pentane > butane) and decreases with branching because branching decreases surface area (so n-Pentane > Isopentane > Neopentane).',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Select random question from pool
    _question = _pool[Random().nextInt(_pool.length)];
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onOptionTap(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
    });

    if (index == _question.correctIndex) {
      widget.onAnswerCorrect(20); // Reward +20 XP
    } else {
      _shakeController.forward(from: 0); // Shake card on wrong answer
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        // Shake logic: oscillate offset left and right
        double offsetVal = 0.0;
        if (_shakeController.isAnimating) {
          final time = _shakeController.value;
          offsetVal = sin(time * pi * 5) * 8.0 * (1.0 - time);
        }

        return Transform.translate(
          offset: Offset(offsetVal, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isAnswered
                ? (_selectedIndex == _question.correctIndex
                    ? AppTheme.accentGreen.withOpacity(0.5)
                    : AppTheme.errorRed.withOpacity(0.5))
                : AppTheme.cardBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Subject Badge & Title ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSubjectColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getSubjectColor().withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _question.subject,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _getSubjectColor(),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+20 XP',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // ── Question Text ──
            Text(
              _question.questionText,
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 20),

            // ── Options List ──
            Column(
              children: List.generate(_question.options.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildOptionButton(index),
                );
              }),
            ),

            // ── Explanation Section ──
            if (_isAnswered)
              _buildExplanationView().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor() {
    switch (_question.subject) {
      case 'BIOLOGY':
        return AppTheme.accentGreen;
      case 'PHYSICS':
        return AppTheme.accentBlue;
      case 'CHEMISTRY':
        return AppTheme.accentPurple;
      default:
        return AppTheme.accentTeal;
    }
  }

  Widget _buildOptionButton(int index) {
    final optionText = _question.options[index];
    final isSelected = _selectedIndex == index;
    final isCorrect = _question.correctIndex == index;

    Color borderCol = AppTheme.cardBorder;
    Color bgCol = Colors.transparent;
    Color textCol = AppTheme.textSecondary;
    Widget? trailingWidget;

    if (_isAnswered) {
      if (isCorrect) {
        borderCol = AppTheme.accentGreen;
        bgCol = AppTheme.accentGreen.withOpacity(0.08);
        textCol = AppTheme.accentGreen;
        trailingWidget = const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 20)
            .animate()
            .scale(duration: 300.ms, curve: Curves.easeOutBack);
      } else if (isSelected) {
        borderCol = AppTheme.errorRed;
        bgCol = AppTheme.errorRed.withOpacity(0.08);
        textCol = AppTheme.errorRed;
        trailingWidget = const Icon(Icons.cancel_rounded, color: AppTheme.errorRed, size: 20)
            .animate()
            .shake(duration: 400.ms);
      } else {
        textCol = AppTheme.textMuted;
      }
    } else {
      if (isSelected) {
        borderCol = AppTheme.accentTeal;
        bgCol = AppTheme.accentTeal.withOpacity(0.05);
        textCol = Colors.white;
      }
    }

    return GestureDetector(
      onTap: () => _onOptionTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol, width: 1.5),
        ),
        child: Row(
          children: [
            // Letter circle
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isAnswered && isCorrect
                    ? AppTheme.accentGreen.withOpacity(0.2)
                    : (_isAnswered && isSelected
                        ? AppTheme.errorRed.withOpacity(0.2)
                        : AppTheme.primaryDark),
                border: Border.all(
                  color: borderCol,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                String.fromCharCode(65 + index), // A, B, C, D
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                optionText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected || (_isAnswered && isCorrect)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: textCol,
                ),
              ),
            ),
            if (trailingWidget != null) trailingWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationView() {
    final isCorrectTap = _selectedIndex == _question.correctIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Divider(color: AppTheme.cardBorder, height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              isCorrectTap ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
              color: isCorrectTap ? Colors.amber : AppTheme.accentBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isCorrectTap ? 'Excellent Work!' : 'Quick Explanation',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCorrectTap ? Colors.amber : Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _question.explanation,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
