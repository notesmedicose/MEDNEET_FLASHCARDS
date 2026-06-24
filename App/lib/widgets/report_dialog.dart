import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class ReportCardDialog extends StatefulWidget {
  final String cardId;
  final String cardFront;

  const ReportCardDialog({
    super.key,
    required this.cardId,
    required this.cardFront,
  });

  @override
  State<ReportCardDialog> createState() => _ReportCardDialogState();
}

class _ReportCardDialogState extends State<ReportCardDialog> {
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedReason = 'Typo in question/answer';

  final List<String> _reasons = [
    'Typo in question/answer',
    'Incorrect information',
    'Formatting/LaTeX error',
    'NCERT reference issue',
    'Other',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final provider = context.read<FlashcardProvider>();
      final email = auth.isGuest ? 'Guest' : (auth.currentUser?.email ?? 'Anonymous');

      await provider.submitReport(
        cardId: widget.cardId,
        cardFront: widget.cardFront,
        reason: _selectedReason,
        comment: _commentController.text.trim(),
        reportedBy: email,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Feedback received. Thank you!',
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final colors = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColors = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder;

    return Dialog(
      backgroundColor: cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.report_gmailerrorred_rounded, color: AppTheme.errorRed, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Report Flashcard',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Let us know what is wrong so we can fix it. The authors will review your report.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: subColors,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // Reason Selector
              Text(
                'Reason for report',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    dropdownColor: cardBg,
                    style: GoogleFonts.inter(color: colors, fontSize: 13.5, fontWeight: FontWeight.w600),
                    items: _reasons.map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedReason = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Comment Field
              Text(
                'Details / Comments',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                style: GoogleFonts.inter(color: colors, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Describe the issue (e.g. correct formula, typo fix...)',
                  hintStyle: GoogleFonts.inter(color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted, fontSize: 12.5),
                  fillColor: isDark ? AppTheme.surfaceDark : AppTheme.lightBg,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (_selectedReason == 'Other' && (val == null || val.trim().isEmpty)) {
                    return 'Please enter details for "Other"';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: subColors,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Submit Report',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
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
}
