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

class _DeckListScreenState extends State<DeckListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        final decks = provider.decks;
        final filteredDecks = provider.selectedSubject == 'All'
            ? decks
            : decks.where((d) => d.subject == provider.selectedSubject).toList();

        return Column(
          children: [
            _buildStatsHeader(provider, isDark),
            _buildSearchBar(isDark),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppTheme.accentGreen,
                unselectedLabelColor: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                tabs: const [
                  Tab(text: 'All'), Tab(text: 'Physics'), Tab(text: 'Chemistry'), Tab(text: 'Biology'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults(provider, isDark)
                  : _buildDeckList(filteredDecks, provider, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsHeader(FlashcardProvider provider, bool isDark) {
    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flashcards', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: colors)),
                Text('${provider.getTotalCards()} total cards', style: GoogleFonts.inter(fontSize: 13, color: subColors)),
              ],
            ),
          ),
          _buildStatChip(provider.getDueCountForSubject('Physics'), '⚡', isDark),
          const SizedBox(width: 6),
          _buildStatChip(provider.getDueCountForSubject('Chemistry'), '🧪', isDark),
          const SizedBox(width: 6),
          _buildStatChip(provider.getDueCountForSubject('Biology'), '🧬', isDark),
        ],
      ),
    );
  }

  Widget _buildStatChip(int count, String emoji, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.cardDark : AppTheme.lightCard).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('$count', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
              color: count > 0 ? AppTheme.accentGreen : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted))),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (q) => context.read<FlashcardProvider>().search(q),
        style: TextStyle(color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
        decoration: InputDecoration(
          hintText: 'Search flashcards...',
          hintStyle: TextStyle(color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted),
          prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted),
          filled: true,
          fillColor: isDark ? AppTheme.cardDark : AppTheme.lightCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDeckList(List<Deck> decks, FlashcardProvider provider, bool isDark) {
    if (decks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📚', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No decks found', style: GoogleFonts.inter(fontSize: 16, color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final deck = decks[index];
        return _buildDeckCard(deck, provider, isDark, index);
      },
    );
  }

  Widget _buildDeckCard(Deck deck, FlashcardProvider provider, bool isDark, int index) {
    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startDeckReview(context, deck),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _getSubjectColor(deck.subject, isDark).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(_getSubjectEmoji(deck.subject), style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: colors)),
                    const SizedBox(height: 4),
                    Text('${deck.totalCards} cards • ${deck.masteredCards} mastered', style: GoogleFonts.inter(fontSize: 12, color: subColors)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: deck.progress,
                        backgroundColor: (isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder).withOpacity(0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (deck.dueCards + deck.newCards > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${deck.dueCards + deck.newCards}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.accentGreen)),
                ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted, size: 20),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildSearchResults(FlashcardProvider provider, bool isDark) {
    final cards = provider.currentCards;
    if (cards.isEmpty) {
      return Center(child: Text('No results found', style: GoogleFonts.inter(color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Card(
          color: isDark ? AppTheme.cardDark : AppTheme.lightCard,
          child: ListTile(
            leading: Text(card.subjectEmoji, style: const TextStyle(fontSize: 20)),
            title: Text(card.front, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(card.chapter, style: GoogleFonts.inter(fontSize: 11,
                color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _startCardReview(context, provider),
          ),
        );
      },
    );
  }

  void _startDeckReview(BuildContext context, Deck deck) {
    context.read<FlashcardProvider>().loadDeckCards(deck.name).then((_) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const CardReviewScreen(),
      ));
    });
  }

  void _startCardReview(BuildContext context, FlashcardProvider provider) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const CardReviewScreen(),
    ));
  }

  Color _getSubjectColor(String subject, bool isDark) {
    switch (subject) {
      case 'Physics': return AppTheme.accentBlue;
      case 'Chemistry': return AppTheme.accentPurple;
      case 'Biology': return AppTheme.accentGreen;
      default: return AppTheme.accentTeal;
    }
  }

  String _getSubjectEmoji(String subject) {
    switch (subject) {
      case 'Physics': return '⚡';
      case 'Chemistry': return '🧪';
      case 'Biology': return '🧬';
      default: return '📚';
    }
  }
}