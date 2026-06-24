import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class StudyModeBottomSheet extends StatelessWidget {
  final String title;
  final VoidCallback onStartReview;
  final VoidCallback onStartCarousel;

  const StudyModeBottomSheet({
    super.key,
    required this.title,
    required this.onStartReview,
    required this.onStartCarousel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final bg = isDark ? AppTheme.surfaceDark : AppTheme.lightSurface;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.lightBg;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select how you want to study this deck',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: subColor,
            ),
          ),
          const SizedBox(height: 24),

          // Option 1: Classic Recall Mode
          InkWell(
            onTap: () {
              Navigator.pop(context);
              onStartReview();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppTheme.accentGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recall Mode (SM-2)',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Classspaced repetition review with difficulty rating, streak counts, and XP tracking.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: subColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: subColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option 2: Carousel Mode
          InkWell(
            onTap: () {
              Navigator.pop(context);
              onStartCarousel();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.view_carousel_rounded,
                      color: AppTheme.accentBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carousel Explorer',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swipe back & forth through cards, shuffle in-place, and study at your own pace without ratings.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: subColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: subColor.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
