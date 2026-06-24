import 'dart:math' as math;
import 'dart:ui';
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
import '../../widgets/report_dialog.dart';

class CardCarouselScreen extends StatefulWidget {
  final String title;
  const CardCarouselScreen({super.key, this.title = 'Card Carousel'});

  @override
  State<CardCarouselScreen> createState() => _CardCarouselScreenState();
}

class _CardCarouselScreenState extends State<CardCarouselScreen> {
  late PageController _pageController;
  List<Flashcard> _cards = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Copy provider's current cards to local state to allow shuffling
    final provider = context.read<FlashcardProvider>();
    _cards = List<Flashcard>.from(provider.currentCards);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shuffleCards() {
    if (_cards.isEmpty) return;
    setState(() {
      _cards.shuffle();
      _currentIndex = 0;
    });
    _pageController.jumpToPage(0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shuffle_rounded, color: AppTheme.primaryDark),
            const SizedBox(width: 8),
            Text(
              'Cards shuffled!',
              style: GoogleFonts.inter(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleBookmark(Flashcard card) async {
    final provider = context.read<FlashcardProvider>();
    await provider.toggleBookmark(card.id);
    // Sync local card state
    setState(() {
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(bookmarked: !_cards[index].bookmarked);
      }
    });
  }

  void _showReportDialog(Flashcard card) {
    showDialog(
      context: context,
      builder: (_) => ReportCardDialog(
        cardId: card.id,
        cardFront: card.front,
      ),
    );
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
    final provider = context.watch<FlashcardProvider>();

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.lightBg,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📭', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'No cards to display',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeCard = _cards[_currentIndex];
    final subjectColor = _getSubjectColor(activeCard.subject);

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
              activeCard.chapter,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Carousel Explorer',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Shuffle
          IconButton(
            icon: Icon(Icons.shuffle_rounded, color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
            tooltip: 'Shuffle Cards',
            onPressed: _shuffleCards,
          ),
          // Bookmark
          IconButton(
            icon: Icon(
              activeCard.bookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: subjectColor,
            ),
            onPressed: () => _toggleBookmark(activeCard),
          ),
          // Report
          IconButton(
            icon: const Icon(Icons.report_gmailerrorred_rounded, color: AppTheme.errorRed),
            tooltip: 'Report card error',
            onPressed: () => _showReportDialog(activeCard),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _cards.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    // Keep provider active index synced if needed
                    provider.searchQuery.isEmpty; // dummy access
                  });
                },
                itemBuilder: (context, index) {
                  return CarouselCardItem(
                    card: _cards[index],
                    subjectColor: _getSubjectColor(_cards[index].subject),
                    pageController: _pageController,
                    index: index,
                  );
                },
              ),
            ),

            // Bottom Navigation & Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Prev Button
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 32),
                    color: _currentIndex > 0
                        ? (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary)
                        : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted).withOpacity(0.3),
                    onPressed: _currentIndex > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),

                  // Progress Indicator
                  Text(
                    '${_currentIndex + 1} of ${_cards.length}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),

                  // Next Button
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 32),
                    color: _currentIndex < _cards.length - 1
                        ? (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary)
                        : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted).withOpacity(0.3),
                    onPressed: _currentIndex < _cards.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
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

class CarouselCardItem extends StatefulWidget {
  final Flashcard card;
  final Color subjectColor;
  final PageController pageController;
  final int index;

  const CarouselCardItem({
    super.key,
    required this.card,
    required this.subjectColor,
    required this.pageController,
    required this.index,
  });

  @override
  State<CarouselCardItem> createState() => _CarouselCardItemState();
}

class _CarouselCardItemState extends State<CarouselCardItem> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

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
  void didUpdateWidget(covariant CarouselCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset flip when card changes
    if (oldWidget.card.id != widget.card.id) {
      _flipController.reset();
      _isFlipped = false;
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  String formatCardText(String text) {
    if (text.isEmpty) return text;
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
        .replaceAll('&micro;', 'µ')
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n');
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipAnimation, widget.pageController]),
        builder: (context, child) {
          double value = 0.0;
          if (widget.pageController.position.haveDimensions) {
            value = (widget.pageController.page ?? 0.0) - widget.index;
          } else {
            value = (widget.pageController.initialPage.toDouble()) - widget.index;
          }

          final double scale = (1 - (value.abs() * 0.12)).clamp(0.82, 1.0);
          final double rotationY = (value * 0.2).clamp(-0.35, 0.35);
          final double translationX = value * -24.0;

          final flipAngle = _flipAnimation.value * math.pi;
          final isFront = flipAngle < math.pi / 2;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..translate(translationX)
                ..scale(scale)
                ..rotateY(rotationY + flipAngle),
              child: isFront
                  ? _buildFront(isDark, colors, subColors)
                  : _buildBack(isDark, colors, subColors),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(bool isDark, Color colors, Color subColors) {
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
        color: widget.subjectColor,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04).withBlue(10)
                : Colors.white.withOpacity(0.45),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.07),
                      widget.subjectColor.withOpacity(0.04),
                    ]
                  : [
                      Colors.white.withOpacity(0.55),
                      widget.subjectColor.withOpacity(0.12),
                    ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: (isDark 
                  ? Colors.white.withOpacity(0.12) 
                  : Colors.white.withOpacity(0.35)).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.subjectColor.withOpacity(isDark ? 0.15 : 0.08),
                blurRadius: 28,
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
              _buildTag(widget.card.typeLabel, _getTypeColor(widget.card.type)),
              const SizedBox(width: 8),
              _buildTag(widget.card.difficulty.toUpperCase(), _getDifficultyColor(widget.card.difficulty)),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: MarkdownBody(
                  data: formatCardText(widget.card.front),
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
              Icon(Icons.touch_app_rounded, size: 16, color: widget.subjectColor.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                'Tap to reveal answer',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildBack(bool isDark, Color colors, Color subColors) {
    final structureKey = detectChemicalStructure('${widget.card.front} ${widget.card.back}');
    
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
        color: widget.subjectColor,
        height: 1.4,
      ),
      strong: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        color: widget.subjectColor,
      ),
      em: const TextStyle(fontStyle: FontStyle.italic),
      listBullet: GoogleFonts.inter(color: colors),
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04).withBlue(10)
                  : Colors.white.withOpacity(0.45),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.07),
                        widget.subjectColor.withOpacity(0.04),
                      ]
                    : [
                        Colors.white.withOpacity(0.55),
                        widget.subjectColor.withOpacity(0.12),
                      ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (isDark 
                    ? Colors.white.withOpacity(0.12) 
                    : Colors.white.withOpacity(0.35)).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.subjectColor.withOpacity(isDark ? 0.15 : 0.08),
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
                color: widget.subjectColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.subjectColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 14, color: widget.subjectColor),
                  const SizedBox(width: 6),
                  Text(
                    widget.card.ncertRef,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.subjectColor,
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
                      data: formatCardText(widget.card.back),
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
                                color: widget.subjectColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🧪 Molecular Structure',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.subjectColor,
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
            if (widget.card.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.card.tags.map((tag) => Container(
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
        ),
      ),
    );
  }
}
