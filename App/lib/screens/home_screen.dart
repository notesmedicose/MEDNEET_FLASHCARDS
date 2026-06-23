import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/webview_frame.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/dopamine_strike_widget.dart';
import '../widgets/daily_quiz_card.dart';
import '../widgets/study_boosters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _userXp = 340;
  int _userLevel = 4;
  int _streakCount = 5;
  bool _showScreenConfetti = false;

  static const String _baseUrl = 'https://mednotes-seven.vercel.app';

  // Tab configuration
  static const List<TabConfig> _tabs = [
    TabConfig(
      label: 'Home',
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      url: _baseUrl,
    ),
    TabConfig(
      label: 'Syllabus Tree',
      icon: Icons.menu_book_rounded,
      activeIcon: Icons.menu_book_rounded,
      url: '$_baseUrl/syllabus',
    ),
    TabConfig(
      label: 'Planner',
      icon: Icons.bar_chart_rounded,
      activeIcon: Icons.bar_chart_rounded,
      url: '$_baseUrl/planner',
    ),
    TabConfig(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      url: '$_baseUrl/profile',
    ),
  ];

  // Lazy-loading indicators
  late final List<bool> _initializedTabs;
  late final List<GlobalKey<WebViewFrameState>> _webViewKeys;

  @override
  void initState() {
    super.initState();
    // Initialize first tab (Home is native so it loads instantly), others lazy loaded
    _initializedTabs = [true, false, false, false];
    _webViewKeys = List.generate(
      _tabs.length,
      (_) => GlobalKey<WebViewFrameState>(),
    );

    // Dopamine Strike on login: Show Daily Streak Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => DopamineStreakDialog(streakCount: _streakCount),
          );
        }
      });
    });
  }

  void _onXpGained(int amount) {
    if (!mounted) return;
    setState(() {
      _userXp += amount;
      _showScreenConfetti = true; // Burst confetti!
      
      // Level Up Check
      if (_userXp >= 500) {
        _userLevel += 1;
        _userXp -= 500;
        _showLevelUpAlert();
      }
    });
  }

  void _showLevelUpAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.accentGreen, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Text(
              'LEVEL UP! 🎉',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Congratulations! You have reached Level $_userLevel!',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your ranking has improved. You are now closer to securing a top score in NEET 2026.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'HELL YEA!',
              style: GoogleFonts.inter(
                color: AppTheme.accentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.splashGradient,
            ),
          ),

          // ── Content Area ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Custom App Bar ──
                _buildAppBar(),

                // ── Main Page Content ──
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List.generate(_tabs.length, (index) {
                      if (index == 0) {
                        return _buildNativeDashboard();
                      } else {
                        if (_initializedTabs[index]) {
                          return WebViewFrame(
                            key: _webViewKeys[index],
                            url: _tabs[index].url,
                            tabLabel: _tabs[index].label,
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }
                    }),
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
                  _initializedTabs[index] = true;
                });
              },
            ),
          ),

          // ── Full-Screen Confetti Layer ──
          if (_showScreenConfetti)
            Positioned.fill(
              child: ConfettiOverlayWidget(
                onComplete: () {
                  setState(() {
                    _showScreenConfetti = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Logo
          GestureDetector(
            onTap: () {
              // Trigger a dopamine check-in pop up if they click the logo
              showDialog(
                context: context,
                builder: (context) => DopamineStreakDialog(streakCount: _streakCount),
              );
            },
            child: Container(
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
                    color: AppTheme.accentGreen.withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MedNotes',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                            '$_streakCount d',
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
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accentGreen.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Refresh Button (only visible for WebView tabs)
          if (_currentIndex > 0)
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.cardBorder.withOpacity(0.5),
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onPressed: () {
                  _webViewKeys[_currentIndex].currentState?.reload();
                },
                padding: EdgeInsets.zero,
              ),
            ),

          // XP Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.cardDark.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.cardBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Lvl $_userLevel',
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

  Widget _buildNativeDashboard() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Banner ──
          _buildWelcomeBanner(),
          const SizedBox(height: 24),

          // ── Quick Study Navigation Grid ──
          _buildShortcutGrid(),
          const SizedBox(height: 28),

          // ── Daily NEET Challenge MCQ ──
          Text(
            'Daily NEET Challenge',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          DailyQuizCard(
            onAnswerCorrect: _onXpGained,
          ),
          const SizedBox(height: 28),

          // ── Pomodoro Timer and Mnemonics ──
          StudyBoostersWidget(
            onXpGained: _onXpGained,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.cardDark, AppTheme.cardDark.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder, width: 1.5),
        image: const DecorationImage(
          image: AssetImage('assets/logo.png'),
          opacity: 0.03,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back, Aspirant!',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your streak going to unlock special revision cards.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // XP Mini-Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XP Progress',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              Text(
                '$_userXp / 500 XP',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _userXp / 500,
              backgroundColor: AppTheme.primaryDark,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildShortcutGrid() {
    final List<ShortcutConfig> shortcuts = [
      ShortcutConfig(
        title: 'Syllabus Tree',
        desc: 'Revision notes',
        icon: Icons.account_tree_rounded,
        color: AppTheme.accentGreen,
        tabIndex: 1,
      ),
      ShortcutConfig(
        title: 'Daily Planner',
        desc: 'Study schedule',
        icon: Icons.calendar_today_rounded,
        color: AppTheme.accentTeal,
        tabIndex: 2,
      ),
      ShortcutConfig(
        title: 'Mock Tests',
        desc: 'Solve mock papers',
        icon: Icons.quiz_rounded,
        color: AppTheme.accentBlue,
        tabIndex: 1, // Opens syllabus/notes page which contains tests
      ),
      ShortcutConfig(
        title: 'My Profile',
        desc: 'Rank & progress',
        icon: Icons.person_rounded,
        color: AppTheme.accentPurple,
        tabIndex: 3,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: shortcuts.length,
      itemBuilder: (context, index) {
        final sc = shortcuts[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentIndex = sc.tabIndex;
              _initializedTabs[sc.tabIndex] = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.cardBorder,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: sc.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(sc.icon, color: sc.color, size: 18),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sc.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sc.desc,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShortcutConfig {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final int tabIndex;

  const ShortcutConfig({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.tabIndex,
  });
}

class TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String url;

  const TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.url,
  });
}
