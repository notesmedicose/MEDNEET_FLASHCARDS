import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/flashcard_model.dart';
import 'card_review_screen.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final subjects = ['All', 'Physics', 'Chemistry', 'Biology'];
        context.read<FlashcardProvider>().setSubject(subjects[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Strip markdown from front text for clean preview
  String _cleanCardText(String text) {
    return text
        .replaceAll(RegExp(r'\*\*Question:\*\*\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'\\[\(\[\]\)]'), '')
        .replaceAll(RegExp(r'#{1,3}\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        final decks = provider.decks;
        final filteredDecks = provider.selectedSubject == 'All'
            ? decks
            : decks.where((d) => d.subject == provider.selectedSubject).toList();
        final isSearching = _searchController.text.isNotEmpty;

        return Column(
          children: [
            // ── Header ──
            _buildHeader(provider, isDark),

            // ── Search Bar ──
            _buildSearchBar(isDark),

            // ── Subject Tabs (hidden during search) ──
            if (!isSearching) ...[
              _buildSubjectTabs(isDark),
              const SizedBox(height: 8),
            ],

            // ── Content ──
            Expanded(
              child: isSearching
                  ? _buildSearchResults(provider, isDark)
                  : _buildDeckList(filteredDecks, provider, isDark),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────── HEADER ───────────────────────────

  Widget _buildHeader(FlashcardProvider provider, bool isDark) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final totalDue = provider.getDueCountForSubject('Physics') +
        provider.getDueCountForSubject('Chemistry') +
        provider.getDueCountForSubject('Biology');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Flashcards',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${provider.getTotalCards()} cards • ${provider.getMasteredCards()} mastered',
                      style: GoogleFonts.inter(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              // Quick Study CTA
              if (totalDue > 0)
                GestureDetector(
                  onTap: () => _startDueReview(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentGreen, AppTheme.accentTeal],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGreen.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppTheme.primaryDark, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Study $totalDue',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
            ],
          ),
          const SizedBox(height: 14),

          // ── Stats Row ──
          Row(
            children: [
              _buildMiniStat('⚡', 'Physics', provider.getDueCountForSubject('Physics'), AppTheme.accentBlue, isDark),
              const SizedBox(width: 8),
              _buildMiniStat('🧪', 'Chemistry', provider.getDueCountForSubject('Chemistry'), AppTheme.accentPurple, isDark),
              const SizedBox(width: 8),
              _buildMiniStat('🧬', 'Biology', provider.getDueCountForSubject('Biology'), AppTheme.accentGreen, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count due',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: count > 0 ? color : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted),
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
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

  // ─────────────────────────── SEARCH BAR ───────────────────────────

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isSearchFocused = focused),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isSearchFocused
                  ? AppTheme.accentGreen.withValues(alpha: 0.5)
                  : (isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
              width: _isSearchFocused ? 1.5 : 1,
            ),
            boxShadow: _isSearchFocused
                ? [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.1),
                      blurRadius: 12,
                      spreadRadius: 0,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (q) {
              context.read<FlashcardProvider>().search(q);
              setState(() {});
            },
            style: GoogleFonts.inter(
              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search cards, topics, formulas...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _isSearchFocused
                    ? AppTheme.accentGreen
                    : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted),
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<FlashcardProvider>().search('');
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── SUBJECT TABS ───────────────────────────

  Widget _buildSubjectTabs(bool isDark) {
    final tabs = [
      {'label': 'All', 'emoji': '📚', 'color': AppTheme.accentTeal},
      {'label': 'Physics', 'emoji': '⚡', 'color': AppTheme.accentBlue},
      {'label': 'Chemistry', 'emoji': '🧪', 'color': AppTheme.accentPurple},
      {'label': 'Biology', 'emoji': '🧬', 'color': AppTheme.accentGreen},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (tabs[_tabController.index]['color'] as Color).withValues(alpha: 0.2),
                (tabs[_tabController.index]['color'] as Color).withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (tabs[_tabController.index]['color'] as Color).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          labelPadding: EdgeInsets.zero,
          dividerColor: Colors.transparent,
          tabs: tabs.map((t) {
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t['emoji'] as String, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    t['label'] as String,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }).toList(),
          labelColor: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
          unselectedLabelColor: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
        ),
      ),
    );
  }

  // ─────────────────────────── DECK LIST ───────────────────────────

  Widget _buildDeckList(List<Deck> decks, FlashcardProvider provider, bool isDark) {
    if (decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              'No decks found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: decks.length,
      itemBuilder: (context, index) => _buildDeckCard(decks[index], provider, isDark, index),
    );
  }

  Widget _buildDeckCard(Deck deck, FlashcardProvider provider, bool isDark, int index) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final accentColor = _getSubjectColor(deck.subject);
    final dueCount = deck.dueCards + deck.newCards;
    final progress = deck.progress;

    return GestureDetector(
      onTap: () => _startDeckReview(context, deck),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? accentColor.withValues(alpha: 0.12)
                : accentColor.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.05 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Subtle accent top-left glow stripe
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accentColor, accentColor.withValues(alpha: 0.3)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    // Subject Icon
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.2),
                            accentColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getSubjectEmoji(deck.subject),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deck.name,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.layers_rounded, size: 11, color: subColor),
                              const SizedBox(width: 3),
                              Text(
                                '${deck.totalCards} cards',
                                style: GoogleFonts.inter(fontSize: 11, color: subColor),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.check_circle_outline_rounded, size: 11, color: AppTheme.accentGreen.withValues(alpha: 0.8)),
                              const SizedBox(width: 3),
                              Text(
                                '${deck.masteredCards} done',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.accentGreen.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          Stack(
                            children: [
                              Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: isDark ? 0.1 : 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: math.max(progress, 0.0),
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [accentColor, accentColor.withValues(alpha: 0.6)],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Right: due badge + arrow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (dueCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$dueCount',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '✓ Done',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentGreen,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: accentColor.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (40 * index).ms).slideY(begin: 0.06, end: 0);
  }

  // ─────────────────────────── SEARCH RESULTS ───────────────────────────

  Widget _buildSearchResults(FlashcardProvider provider, bool isDark) {
    final cards = provider.currentCards;
    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No results for "${_searchController.text}"',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try different keywords',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '${cards.length} results',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'for "${_searchController.text}"',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: cards.length,
            itemBuilder: (context, index) =>
                _buildSearchCard(cards[index], provider, isDark, index),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard(Flashcard card, FlashcardProvider provider, bool isDark, int index) {
    final accentColor = _getSubjectColor(card.subject);
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cleanFront = _cleanCardText(card.front);

    return GestureDetector(
      onTap: () => _startCardReview(context, provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject indicator dot + emoji
            Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(card.subjectEmoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type + difficulty chips
                  Row(
                    children: [
                      _searchChip(card.typeLabel, _getTypeColor(card.type)),
                      const SizedBox(width: 5),
                      _searchChip(card.difficulty.toUpperCase(), _getDifficultyColor(card.difficulty)),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Card question text (cleaned of markdown)
                  Text(
                    cleanFront,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Chapter
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 11, color: accentColor.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          card.chapter,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: accentColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms, delay: (30 * math.min(index, 10)).ms);
  }

  Widget _searchChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─────────────────────────── HELPERS ───────────────────────────

  void _startDueReview(BuildContext context) {
    context.read<FlashcardProvider>().loadDueCards().then((_) {
      if (!mounted) return;
      Navigator.of(this.context).push(MaterialPageRoute(
        builder: (_) => const CardReviewScreen(),
      ));
    });
  }

  void _startDeckReview(BuildContext context, Deck deck) {
    context.read<FlashcardProvider>().loadDeckCards(deck.name).then((_) {
      if (!mounted) return;
      Navigator.of(this.context).push(MaterialPageRoute(
        builder: (_) => const CardReviewScreen(),
      ));
    });
  }

  void _startCardReview(BuildContext context, FlashcardProvider provider) {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const CardReviewScreen(),
    ));
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Physics':    return AppTheme.accentBlue;
      case 'Chemistry':  return AppTheme.accentPurple;
      case 'Biology':    return AppTheme.accentGreen;
      default:           return AppTheme.accentTeal;
    }
  }

  String _getSubjectEmoji(String subject) {
    switch (subject) {
      case 'Physics':   return '⚡';
      case 'Chemistry': return '🧪';
      case 'Biology':   return '🧬';
      default:          return '📚';
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'concept': return AppTheme.accentBlue;
      case 'formula': return AppTheme.accentOrange;
      default:        return AppTheme.accentPurple;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':   return AppTheme.successGreen;
      case 'medium': return AppTheme.warningAmber;
      case 'hard':   return AppTheme.errorRed;
      default:       return AppTheme.textSecondary;
    }
  }
}