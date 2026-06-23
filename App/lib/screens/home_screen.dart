import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../providers/flashcard_provider.dart';
import 'flashcards/deck_list_screen.dart';
import 'flashcards/bookmarked_cards_screen.dart';
import 'flashcards/progress_screen.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Tab configurations
  static const List<TabConfig> _tabs = [
    TabConfig(
      label: 'Decks',
      icon: Icons.style_outlined,
      activeIcon: Icons.style_rounded,
    ),
    TabConfig(
      label: 'Bookmarks',
      icon: Icons.bookmark_border_rounded,
      activeIcon: Icons.bookmark_rounded,
    ),
    TabConfig(
      label: 'Progress',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
  ];

  // Native screens list
  static const List<Widget> _screens = [
    DeckListScreen(),
    BookmarkedCardsScreen(),
    ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final themeProvider = context.read<ThemeProvider>();
    final provider = context.watch<FlashcardProvider>();
    final xpSystem = provider.xpSystem;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──
          Container(
            decoration: BoxDecoration(
              gradient: isDark ? AppTheme.splashGradient : AppTheme.lightSplashGradient,
            ),
          ),

          // ── Content Area ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Global Custom App Bar ──
                _buildAppBar(xpSystem, isDark, themeProvider),

                // ── Main Page Content ──
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Navigation ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(
              currentIndex: _currentIndex,
              tabs: _tabs,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(dynamic xpSystem, bool isDark, ThemeProvider themeProvider) {
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.accentGreen.withOpacity(0.8) : AppTheme.lightPrimaryGreen.withOpacity(0.8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // App Logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/logo.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen).withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Title & Tab Context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MEDNEET',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Streak chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${xpSystem.streakCount} d',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.05, 1.05),
                          duration: 800.ms,
                        ),
                  ],
                ),
                Text(
                  'NEET 2026 • ${_tabs[_currentIndex].label}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Theme Toggle Button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              size: 20,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),

          const SizedBox(width: 4),

          // Level Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.cardDark : AppTheme.lightCard).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Lvl ${xpSystem.level}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
