import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import '../../providers/flashcard_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/flashcard_model.dart';
import '../../widgets/chemistry_structure_widget.dart';

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

  String formatCardText(String text) {
    if (text.isEmpty) return text;
    
    // Clean up HTML entities
    String formatted = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&deg;', '°')
        .replaceAll('&times;', '×')
        .replaceAll('&plusmn;', '±')
        .replaceAll('&micro;', 'µ');
        
    // Replace escaped newlines
    formatted = formatted.replaceAll(r'\r\n', '\n').replaceAll(r'\n', '\n');

    // Convert LaTeX delimiters \( \) and \[ \] to $ and $$
    formatted = formatted.replaceAllMapped(RegExp(r'\\+\['), (match) => r'$$');
    formatted = formatted.replaceAllMapped(RegExp(r'\\+\]'), (match) => r'$$');
    formatted = formatted.replaceAllMapped(RegExp(r'\\+\('), (match) => r'$');
    formatted = formatted.replaceAllMapped(RegExp(r'\\+\)'), (match) => r'$');
    
    return formatted;
  }

  String? detectChemicalStructure(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('salicylic acid')) return 'salicylic_acid';
    if (lower.contains('salicylaldehyde')) return 'salicylaldehyde';
    if (lower.contains('benzoic acid')) return 'benzoic_acid';
    if (lower.contains('benzaldehyde')) return 'benzaldehyde';
    if (lower.contains('nitrobenzene')) return 'nitrobenzene';
    if (lower.contains('chlorobenzene')) return 'chlorobenzene';
    if (lower.contains('benzene diazonium')) return 'benzene_diazonium';
    if (lower.contains('diazo')) return 'benzene_diazonium';
    if (lower.contains('anisole')) return 'anisole';
    if (lower.contains('cumene')) return 'cumene';
    if (lower.contains('toluene')) return 'toluene';
    if (lower.contains('phenol')) return 'phenol';
    if (lower.contains('benzene')) return 'benzene';
    if (lower.contains('cyclohexane')) return 'cyclohexane';
    if (lower.contains('naphthalene')) return 'naphthalene';
    if (lower.contains('pyridine')) return 'pyridine';
    if (lower.contains('furan')) return 'furan';
    if (lower.contains('thiophene')) return 'thiophene';
    if (lower.contains('pyrrole')) return 'pyrrole';
    return null;
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Physics':
        return AppTheme.accentBlue;
      case 'Chemistry':
        return AppTheme.accentPurple;
      case 'Biology':
        return AppTheme.accentGreen;
      default:
        return AppTheme.accentTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        final card = provider.currentCard;
        final total = provider.currentCards.length;
        final current = provider.currentIndex + 1;
        final subjectColor = card != null ? _getSubjectColor(card.subject) : AppTheme.accentGreen;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.lightBg,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              children: [
                Text(
                  '${card?.subjectEmoji ?? ""} ${card?.subject ?? ""}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                if (total > 0)
                  Text(
                    '$current of $total',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                    ),
                  ),
              ],
            ),
            actions: [
              if (card != null)
                IconButton(
                  icon: Icon(
                    provider.isCurrentCardBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: subjectColor,
                    size: 24,
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
                      const Icon(Icons.celebration, size: 72, color: AppTheme.accentGreen),
                      const SizedBox(height: 20),
                      Text(
                        'All caught up! 🎉',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No cards due for review.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: AppTheme.primaryDark,
                          elevation: 4,
                          shadowColor: AppTheme.accentGreen.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Decks',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(child: _buildCard(card, isDark, subjectColor)),
                    _buildRatingButtons(provider, isDark, subjectColor),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCard(Flashcard card, bool isDark, Color subjectColor) {
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
          final angle = _flipAnimation.value * math.pi;
          final isFront = angle < math.pi / 2;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isFront
                  ? _buildFront(card, isDark, subjectColor, colors, subColors)
                  : _buildBack(card, isDark, subjectColor, colors, subColors),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(Flashcard card, bool isDark, Color subjectColor, Color colors, Color subColors) {
    final mdStyle = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      textAlign: WrapAlignment.center,
      p: GoogleFonts.inter(
        fontSize: 18,
        height: 1.6,
        color: colors,
        fontWeight: FontWeight.w600,
      ),
      strong: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        color: subjectColor,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.cardDark.withOpacity(0.85), AppTheme.cardDark.withOpacity(0.65)]
              : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: subjectColor.withOpacity(isDark ? 0.25 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: subjectColor.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
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
              _buildTag(card.difficulty.toUpperCase(), _getDifficultyColor(card.difficulty)),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: MarkdownBody(
                  data: formatCardText(card.front),
                  selectable: true,
                  styleSheet: mdStyle,
                  builders: {
                    'latex': LatexElementBuilder(
                      textStyle: GoogleFonts.inter(fontSize: 18, color: colors, fontWeight: FontWeight.bold),
                    ),
                  },
                  extensionSet: md.ExtensionSet(
                    [LatexBlockSyntax()],
                    [LatexInlineSyntax()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 16, color: subjectColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'Tap to reveal answer',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(Flashcard card, bool isDark, Color subjectColor, Color colors, Color subColors) {
    final structureKey = detectChemicalStructure('${card.front} ${card.back}');
    
    final mdStyle = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: GoogleFonts.inter(
        fontSize: 15,
        height: 1.65,
        color: colors,
        fontWeight: FontWeight.w500,
      ),
      h1: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colors,
        height: 1.4,
      ),
      h2: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors,
        height: 1.4,
      ),
      h3: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: subjectColor,
        height: 1.4,
      ),
      strong: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        color: subjectColor,
      ),
      em: const TextStyle(fontStyle: FontStyle.italic),
      listBullet: GoogleFonts.inter(color: colors),
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.cardDark.withOpacity(0.9), AppTheme.surfaceDark.withOpacity(0.75)]
                : [Colors.white.withOpacity(0.98), Colors.white.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: subjectColor.withOpacity(isDark ? 0.35 : 0.45),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: subjectColor.withOpacity(isDark ? 0.2 : 0.15),
              blurRadius: 28,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: subjectColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: subjectColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 14, color: subjectColor),
                  const SizedBox(width: 6),
                  Text(
                    card.ncertRef,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: subjectColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: formatCardText(card.back),
                      selectable: true,
                      styleSheet: mdStyle,
                      builders: {
                        'latex': LatexElementBuilder(
                          textStyle: GoogleFonts.inter(fontSize: 15, color: colors),
                        ),
                      },
                      extensionSet: md.ExtensionSet(
                        [LatexBlockSyntax()],
                        [LatexInlineSyntax()],
                      ),
                    ),
                    if (structureKey != null) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: subjectColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🧪 Molecular Structure',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: subjectColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            ChemistryStructureWidget(
                              structureKey: structureKey,
                              size: 160.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (card.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: card.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: subColors,
                    ),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'concept':
        return AppTheme.accentBlue;
      case 'formula':
        return AppTheme.accentOrange;
      default:
        return AppTheme.accentPurple;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return AppTheme.successGreen;
      case 'medium':
        return AppTheme.warningAmber;
      case 'hard':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildRatingButtons(FlashcardProvider provider, bool isDark, Color subjectColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.primaryDark.withOpacity(0.4) : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.cardBorder.withOpacity(0.4) : Colors.black.withOpacity(0.03),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'How well did you know this?',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 14),
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
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Reset flip to front position before showing next card
          _flipController.reset();
          provider.reviewCard(quality);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}