import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/flashcard_model.dart';

class CardReviewScreen extends StatefulWidget {
  const CardReviewScreen({super.key});

  @override
  State<CardReviewScreen> createState() => _CardReviewScreenState();
}

class _CardReviewScreenState extends State<CardReviewScreen> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        final card = provider.currentCard;
        final total = provider.currentCards.length;
        final current = provider.currentIndex + 1;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.lightBg,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              children: [
                Text('${card?.subjectEmoji ?? ""} ${card?.subject ?? ""}',
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)),
                if (total > 0)
                  Text('$current of $total', style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted)),
              ],
            ),
            actions: [
              if (card != null)
                IconButton(
                  icon: Icon(
                    provider.isCurrentCardBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: AppTheme.accentGreen,
                  ),
                  onPressed: () => provider.toggleBookmark(),
                ),
            ],
          ),
          body: card == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.celebration, size: 64, color: AppTheme.accentGreen),
                      const SizedBox(height: 16),
                      Text('All caught up! 🎉', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary)),
                      const SizedBox(height: 8),
                      Text('No cards due for review.', style: GoogleFonts.inter(fontSize: 14,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: AppTheme.primaryDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Back to Decks', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(child: _buildCard(card, isDark)),
                    _buildRatingButtons(provider, isDark),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCard(Flashcard card, bool isDark) {
    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: () {
        context.read<FlashcardProvider>().flipCard();
        if (_flipController.isCompleted) {
          _flipController.reverse();
        } else {
          _flipController.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * 3.14159;
          final isFront = angle < 1.57;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isFront ? _buildFront(card, isDark, colors, subColors) : _buildBack(card, isDark, colors, subColors),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(Flashcard card, bool isDark, Color colors, Color subColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.cardDark, AppTheme.cardDark.withAlpha(240)]
              : [AppTheme.lightCard, AppTheme.lightBg],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey.shade300).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTag(card.typeLabel, _getTypeColor(card.type)),
              const SizedBox(width: 8),
              _buildTag(card.difficulty, _getDifficultyColor(card.difficulty)),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            child: Text(
              card.front,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: colors, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 14, color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted),
              const SizedBox(width: 6),
              Text('Tap to reveal answer', style: GoogleFonts.inter(fontSize: 12,
                  color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(Flashcard card, bool isDark, Color colors, Color subColors) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.cardDark, AppTheme.surfaceDark]
                : [AppTheme.lightCard, AppTheme.lightBg],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.accentGreen.withAlpha(100),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGreen.withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book, size: 12, color: AppTheme.accentGreen),
                  const SizedBox(width: 4),
                  Text(card.ncertRef, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.accentGreen)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  card.back,
                  style: GoogleFonts.inter(fontSize: 15, color: colors, height: 1.7),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (card.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: card.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder).withAlpha(77),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('#$tag', style: GoogleFonts.inter(fontSize: 10, color: subColors)),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(39),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Concept': return AppTheme.accentBlue;
      case 'Formula': return AppTheme.accentOrange;
      default: return AppTheme.accentPurple;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff) {
      case 'easy': return AppTheme.successGreen;
      case 'medium': return AppTheme.warningAmber;
      case 'hard': return AppTheme.errorRed;
      default: return AppTheme.textSecondary;
    }
  }

  Widget _buildRatingButtons(FlashcardProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: [
          Text('How well did you know this?', style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _rateButton('Again', Icons.refresh, AppTheme.errorRed, 0, provider)),
              const SizedBox(width: 8),
              Expanded(child: _rateButton('Hard', Icons.sentiment_dissatisfied, AppTheme.warningAmber, 1, provider)),
              const SizedBox(width: 8),
              Expanded(child: _rateButton('Good', Icons.sentiment_satisfied, AppTheme.successGreen, 2, provider)),
              const SizedBox(width: 8),
              Expanded(child: _rateButton('Easy', Icons.sentiment_very_satisfied, AppTheme.accentBlue, 3, provider)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateButton(String label, IconData icon, Color color, int quality, FlashcardProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (_flipController.isCompleted || _flipController.value > 0.5) {
            _flipController.reverse();
          }
          provider.reviewCard(quality);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(77)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}