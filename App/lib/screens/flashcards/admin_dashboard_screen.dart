import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/flashcard_model.dart';
import 'admin_edit_card_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubject = 'All';
  List<Map<String, dynamic>> _reports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoadingReports = true);
    try {
      final provider = context.read<FlashcardProvider>();
      final reports = await provider.loadReports();
      setState(() {
        _reports = reports;
      });
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }
    setState(() => _isLoadingReports = false);
  }

  void _resolveReport(String reportId) async {
    final provider = context.read<FlashcardProvider>();
    await provider.resolveReport(reportId);
    _loadReports();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report resolved and dismissed.', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteCard(Flashcard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Flashcard?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete this card? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<FlashcardProvider>();
      await provider.deleteCard(card.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Flashcard deleted successfully.', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.accentOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen,
          unselectedLabelColor: subColor,
          indicatorColor: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen,
          tabs: const [
            Tab(icon: Icon(Icons.layers_rounded), text: 'Flashcards'),
            Tab(icon: Icon(Icons.report_gmailerrorred_rounded), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlashcardsTab(isDark, textColor, subColor),
          _buildReportsTab(isDark, textColor, subColor),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: _tabController.animation!.drive(
          CustomIntConverter().chain(CurveTween(curve: Curves.easeIn)),
        ),
        builder: (context, activeIndex, child) {
          // Only show FAB on flashcards tab
          if (activeIndex == 0) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminEditCardScreen()),
                );
              },
              backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen,
              foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
              child: const Icon(Icons.add_rounded, size: 28),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFlashcardsTab(bool isDark, Color textColor, Color subColor) {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        final allCards = provider.currentCards;
        // Filter by subject
        var filteredCards = _selectedSubject == 'All'
            ? allCards
            : allCards.where((c) => c.subject == _selectedSubject).toList();
        // Filter by search query
        final query = _searchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          filteredCards = filteredCards.where((c) {
            return c.front.toLowerCase().contains(query) ||
                c.back.toLowerCase().contains(query) ||
                c.chapter.toLowerCase().contains(query);
          }).toList();
        }

        return Column(
          children: [
            // Search & Filter header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    style: GoogleFonts.inter(color: textColor, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Search cards...',
                      hintStyle: GoogleFonts.inter(color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted, fontSize: 12.5),
                      prefixIcon: Icon(Icons.search_rounded, color: subColor, size: 20),
                      fillColor: isDark ? AppTheme.cardDark : Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subject Selector Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Physics', 'Chemistry', 'Biology'].map((subject) {
                        final isSelected = _selectedSubject == subject;
                        final color = _getSubjectColor(subject);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(subject),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedSubject = subject;
                                });
                              }
                            },
                            selectedColor: color.withOpacity(0.2),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? color : subColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Cards List
            Expanded(
              child: filteredCards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📚', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            'No flashcards found',
                            style: GoogleFonts.inter(fontSize: 15, color: subColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = filteredCards[index];
                        final color = _getSubjectColor(card.subject);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
                          ),
                          child: Row(
                            children: [
                              // Subject icon dot
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(card.subjectEmoji, style: const TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Text snippet
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _cleanCardText(card.front),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${card.subject} • Chapter ${card.chapterNum}: ${card.chapter}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        color: subColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Edit & Delete Actions
                              IconButton(
                                icon: Icon(Icons.edit_rounded, color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AdminEditCardScreen(card: card)),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 20),
                                onPressed: () => _deleteCard(card),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportsTab(bool isDark, Color textColor, Color subColor) {
    if (_isLoadingReports) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 64, color: AppTheme.successGreen),
            const SizedBox(height: 16),
            Text(
              'No pending reports! 🎉',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All user feedback is resolved.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subColor,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      color: AppTheme.accentGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          final reportedAt = DateTime.tryParse(report['reportedAt'] ?? '') ?? DateTime.now();
          final timeStr = '${reportedAt.day}/${reportedAt.month} ${reportedAt.hour.toString().padLeft(2, '0')}:${reportedAt.minute.toString().padLeft(2, '0')}';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                      ),
                      child: Text(
                        report['reason'] ?? 'Error',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(fontSize: 10.5, color: subColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Card preview
                Text(
                  'Card Question:',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: subColor),
                ),
                const SizedBox(height: 2),
                Text(
                  _cleanCardText(report['cardFront'] ?? ''),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // User comment
                if (report['comment'] != null && report['comment'].toString().trim().isNotEmpty) ...[
                  Text(
                    'Feedback:',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: subColor),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : AppTheme.lightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      report['comment'],
                      style: GoogleFonts.inter(fontSize: 12.5, color: textColor, fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Reporter Email
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 12, color: subColor),
                    const SizedBox(width: 4),
                    Text(
                      'Reported by: ${report['reportedBy']}',
                      style: GoogleFonts.inter(fontSize: 11, color: subColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit Card Button
                    TextButton.icon(
                      onPressed: () {
                        // Find the card in provider and edit it
                        final provider = context.read<FlashcardProvider>();
                        final card = provider.currentCards.firstWhere(
                          (c) => c.id == report['cardId'],
                          orElse: () => Flashcard(
                            id: report['cardId'],
                            subject: 'Physics',
                            classNum: '11',
                            chapter: 'Unknown',
                            chapterNum: 1,
                            type: 'concept',
                            front: report['cardFront'],
                            back: '',
                            ncertRef: '',
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminEditCardScreen(card: card),
                          ),
                        ).then((_) => _loadReports());
                      },
                      icon: Icon(Icons.edit_rounded, size: 14, color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen),
                      label: Text(
                        'Fix Card',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Resolve Button
                    ElevatedButton.icon(
                      onPressed: () => _resolveReport(report['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen.withOpacity(0.12),
                        foregroundColor: AppTheme.successGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: Text(
                        'Resolve',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Helper value converter to bind tab animation to custom integer changes
class CustomIntConverter extends Animatable<int> {
  @override
  int transform(double t) {
    return t > 0.5 ? 1 : 0;
  }
}
