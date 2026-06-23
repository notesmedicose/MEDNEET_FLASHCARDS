import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/flashcard_model.dart';
import '../../database/flashcard_database.dart';
import 'card_review_screen.dart';

class BookmarkedCardsScreen extends StatefulWidget {
  const BookmarkedCardsScreen({super.key});

  @override
  State<BookmarkedCardsScreen> createState() => _BookmarkedCardsScreenState();
}

class _BookmarkedCardsScreenState extends State<BookmarkedCardsScreen> {
  late Future<List<Flashcard>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _refreshBookmarks();
  }

  void _refreshBookmarks() {
    setState(() {
      _bookmarksFuture = FlashcardDatabase.instance.getBookmarkedFlashcards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return FutureBuilder<List<Flashcard>>(
      future: _bookmarksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
            ),
          );
        }

        final bookmarkedCards = snapshot.data ?? [];

        if (bookmarkedCards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.cardDark : AppTheme.lightCard).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '🔖',
                    style: TextStyle(fontSize: 48),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Text(
                  'No bookmarks yet',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Tap the bookmark icon during flashcard reviews to save difficult concepts or formulas here for quick reference.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: subColors,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header stats & Review action
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bookmarks',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: colors,
                          ),
                        ),
                        Text(
                          '${bookmarkedCards.length} saved cards',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: subColors,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: AppTheme.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      'Review All',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: _startBookmarksReview,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Bookmarked Cards List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                physics: const BouncingScrollPhysics(),
                itemCount: bookmarkedCards.length,
                itemBuilder: (context, index) {
                  final card = bookmarkedCards[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
                      ),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _reviewSingleCard(card),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subject Badge / Emoji
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getSubjectColor(card.subject, isDark).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      card.subjectEmoji,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Card Snippet Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _cleanSnippet(card.front),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: colors,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder).withAlpha(120),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              card.ncertRef,
                                              style: GoogleFonts.inter(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: subColors,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              card.chapter,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: subColors,
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

                                // Unbookmark Action
                                IconButton(
                                  icon: const Icon(
                                    Icons.bookmark,
                                    color: AppTheme.accentGreen,
                                    size: 20,
                                  ),
                                  onPressed: () => _toggleBookmark(card),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 250.ms, delay: (40 * index).ms).slideX(begin: 0.04, end: 0);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getSubjectColor(String subject, bool isDark) {
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

  void _toggleBookmark(Flashcard card) async {
    await FlashcardDatabase.instance.toggleBookmark(card.id);
    // Refresh parent dashboard deck counts
    if (mounted) {
      context.read<FlashcardProvider>().loadDecks();
      _refreshBookmarks();
    }
  }

  void _startBookmarksReview() {
    final navigator = Navigator.of(context);
    context.read<FlashcardProvider>().loadBookmarkedCards().then((_) {
      if (!mounted) return;
      navigator.push(MaterialPageRoute(
        builder: (_) => const CardReviewScreen(),
      )).then((_) => _refreshBookmarks());
    });
  }

  void _reviewSingleCard(Flashcard card) {
    final navigator = Navigator.of(context);
    // Load bookmarked cards then navigate to review screen
    final provider = context.read<FlashcardProvider>();
    provider.loadBookmarkedCards().then((_) {
      if (!mounted) return;
      navigator.push(MaterialPageRoute(
        builder: (_) => const CardReviewScreen(),
      )).then((_) => _refreshBookmarks());
    });
  }

  String _cleanSnippet(String text) {
    if (text.isEmpty) return text;
    // Strip LaTeX delimiters \(, \), \[, \]
    String cleaned = text.replaceAll(RegExp(r'\\+[\(\[\]\)]'), '');
    // Strip bold/italic symbols
    cleaned = cleaned.replaceAll(RegExp(r'\*\*|\*'), '');
    // Clean HTML space entities
    cleaned = cleaned.replaceAll('&nbsp;', ' ');
    // Remove extra whitespaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.trim();
  }
}
