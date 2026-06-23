import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/spaced_repetition_model.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        final xpSystem = provider.xpSystem;
        final totalCards = provider.getTotalCards();
        final masteredCards = provider.getMasteredCards();
        final overallProgress = provider.overallProgress;

        // Group decks by subject to show breakdown
        final decks = provider.decks;
        final physicsDecks = decks.where((d) => d.subject == 'Physics').toList();
        final chemistryDecks = decks.where((d) => d.subject == 'Chemistry').toList();
        final biologyDecks = decks.where((d) => d.subject == 'Biology').toList();

        final totalPhysics = physicsDecks.fold(0, (sum, d) => sum + d.totalCards);
        final masteredPhysics = physicsDecks.fold(0, (sum, d) => sum + d.masteredCards);
        final duePhysics = physicsDecks.fold(0, (sum, d) => sum + d.dueCards + d.newCards);

        final totalChemistry = chemistryDecks.fold(0, (sum, d) => sum + d.totalCards);
        final masteredChemistry = chemistryDecks.fold(0, (sum, d) => sum + d.masteredCards);
        final dueChemistry = chemistryDecks.fold(0, (sum, d) => sum + d.dueCards + d.newCards);

        final totalBiology = biologyDecks.fold(0, (sum, d) => sum + d.totalCards);
        final masteredBiology = biologyDecks.fold(0, (sum, d) => sum + d.masteredCards);
        final dueBiology = biologyDecks.fold(0, (sum, d) => sum + d.dueCards + d.newCards);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Text(
                  'My Progress',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colors,
                  ),
                ),
                Text(
                  'Your NEET prep overview',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: subColors,
                  ),
                ),
                const SizedBox(height: 24),

                // ── XP & Level Progression Card ──
                _buildLevelCard(xpSystem, isDark),
                const SizedBox(height: 24),

                // ── Key Metrics Grid ──
                _buildMetricsGrid(xpSystem, masteredCards, totalCards, overallProgress, isDark),
                const SizedBox(height: 28),

                // ── Subject Breakdown Header ──
                Text(
                  'Subject Breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors,
                  ),
                ),
                const SizedBox(height: 12),

                // Physics Stats
                _buildSubjectStatsCard(
                  subject: 'Physics',
                  emoji: '⚡',
                  totalCards: totalPhysics,
                  mastered: masteredPhysics,
                  due: duePhysics,
                  accentColor: AppTheme.accentBlue,
                  isDark: isDark,
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 12),

                // Chemistry Stats
                _buildSubjectStatsCard(
                  subject: 'Chemistry',
                  emoji: '🧪',
                  totalCards: totalChemistry,
                  mastered: masteredChemistry,
                  due: dueChemistry,
                  accentColor: AppTheme.accentPurple,
                  isDark: isDark,
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05, end: 0),
                const SizedBox(height: 12),

                // Biology Stats
                _buildSubjectStatsCard(
                  subject: 'Biology',
                  emoji: '🧬',
                  totalCards: totalBiology,
                  mastered: masteredBiology,
                  due: dueBiology,
                  accentColor: AppTheme.accentGreen,
                  isDark: isDark,
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelCard(XPSystem xpSystem, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        children: [
          // Circular progress for Level
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: xpSystem.levelProgress,
                  strokeWidth: 8,
                  backgroundColor: (isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder).withOpacity(0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lvl',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                    ),
                  ),
                  Text(
                    '${xpSystem.level}',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),

          // XP numbers and text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rank: Aspirant',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep reviewing flashcards regularly. Level up to maintain your edge for NEET 2026.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'XP Progress',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                    Text(
                      '${xpSystem.totalXP} / ${xpSystem.nextLevelXP} XP',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildMetricsGrid(XPSystem xpSystem, int masteredCards, int totalCards, double overallProgress, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          title: 'Study Streak',
          value: '${xpSystem.streakCount} days',
          subtitle: 'Current: ${xpSystem.currentStreak}d',
          emoji: '🔥',
          emojiColor: Colors.orange,
          isDark: isDark,
        ),
        _buildMetricCard(
          title: 'Mastered',
          value: '$masteredCards',
          subtitle: 'of $totalCards total',
          emoji: '🏆',
          emojiColor: Colors.amber,
          isDark: isDark,
        ),
        _buildMetricCard(
          title: 'Reviewed Today',
          value: '${xpSystem.cardsReviewedToday}',
          subtitle: 'cards studied',
          emoji: '📚',
          emojiColor: AppTheme.accentTeal,
          isDark: isDark,
        ),
        _buildMetricCard(
          title: 'Completion',
          value: '${(overallProgress * 100).toStringAsFixed(1)}%',
          subtitle: 'mastery rate',
          emoji: '📈',
          emojiColor: AppTheme.accentGreen,
          isDark: isDark,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 50.ms);
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required String emoji,
    required Color emojiColor,
    required bool isDark,
  }) {
    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subColors,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: emojiColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectStatsCard({
    required String subject,
    required String emoji,
    required int totalCards,
    required int mastered,
    required int due,
    required Color accentColor,
    required bool isDark,
  }) {
    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    final double completionRate = totalCards > 0 ? mastered / totalCards : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subject,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$mastered / $totalCards Mastered',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: subColors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: (isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder).withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: ${(completionRate * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                      ),
                    ),
                    if (due > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$due due cards',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      )
                    else
                      Text(
                        'All clear! 🎉',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
