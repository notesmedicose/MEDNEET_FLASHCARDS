import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<TabConfig> tabs;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 10,
        top: 8,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.navBarGradient,
        border: Border(
          top: BorderSide(
            color: AppTheme.cardBorder.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.cardDark.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.cardBorder.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(tabs.length, (index) {
            final isActive = index == currentIndex;
            return _NavItem(
              icon: isActive ? tabs[index].activeIcon : tabs[index].icon,
              label: tabs[index].label,
              isActive: isActive,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accentGreen.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                size: isActive ? 24 : 22,
                color: isActive ? AppTheme.accentGreen : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: GoogleFonts.inter(
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.accentGreen : AppTheme.textMuted,
                letterSpacing: 0.3,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
