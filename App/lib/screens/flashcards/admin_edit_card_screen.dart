import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/flashcard_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/flashcard_model.dart';

class AdminEditCardScreen extends StatefulWidget {
  final Flashcard? card;

  const AdminEditCardScreen({super.key, this.card});

  @override
  State<AdminEditCardScreen> createState() => _AdminEditCardScreenState();
}

class _AdminEditCardScreenState extends State<AdminEditCardScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _subject;
  late String _classNum;
  late TextEditingController _chapterController;
  late TextEditingController _chapterNumController;
  late String _type;
  late TextEditingController _frontController;
  late TextEditingController _backController;
  late TextEditingController _ncertRefController;
  late String _difficulty;
  late TextEditingController _tagsController;

  final List<String> _subjects = ['Physics', 'Chemistry', 'Biology'];
  final List<String> _classes = ['11', '12'];
  final List<String> _types = ['concept', 'formula', 'recall'];
  final List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _subject = card?.subject ?? 'Physics';
    _classNum = card?.classNum ?? '11';
    _chapterController = TextEditingController(text: card?.chapter ?? '');
    _chapterNumController = TextEditingController(text: card?.chapterNum.toString() ?? '1');
    _type = card?.type ?? 'concept';
    _frontController = TextEditingController(text: card?.front ?? '');
    _backController = TextEditingController(text: card?.back ?? '');
    _ncertRefController = TextEditingController(text: card?.ncertRef ?? '');
    _difficulty = card?.difficulty ?? 'medium';
    _tagsController = TextEditingController(text: card?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _chapterNumController.dispose();
    _frontController.dispose();
    _backController.dispose();
    _ncertRefController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _saveCard() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<FlashcardProvider>();
      final isEdit = widget.card != null;

      final cardId = isEdit ? widget.card!.id : 'card_${DateTime.now().millisecondsSinceEpoch}';
      
      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final newCard = Flashcard(
        id: cardId,
        subject: _subject,
        classNum: _classNum,
        chapter: _chapterController.text.trim(),
        chapterNum: int.parse(_chapterNumController.text.trim()),
        type: _type,
        front: _frontController.text.trim(),
        back: _backController.text.trim(),
        ncertRef: _ncertRefController.text.trim(),
        difficulty: _difficulty,
        tags: tags,
        // Retain SM-2 properties if editing
        interval: widget.card?.interval ?? 0,
        repetitions: widget.card?.repetitions ?? 0,
        easeFactor: widget.card?.easeFactor ?? 2.5,
        nextReviewDate: widget.card?.nextReviewDate,
        lastReviewDate: widget.card?.lastReviewDate,
        status: widget.card?.status ?? 0,
        timesReviewed: widget.card?.timesReviewed ?? 0,
        timesCorrect: widget.card?.timesCorrect ?? 0,
        bookmarked: widget.card?.bookmarked ?? false,
      );

      await provider.addOrUpdateCard(newCard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Flashcard updated!' : 'Flashcard created!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.card != null ? 'Edit Flashcard' : 'Create Flashcard',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject, Class, Type Row
                Row(
                  children: [
                    // Subject
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Subject', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 6),
                          _buildDropdown(
                            value: _subject,
                            items: _subjects,
                            onChanged: (val) => setState(() => _subject = val!),
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Class
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 6),
                          _buildDropdown(
                            value: _classNum,
                            items: _classes,
                            onChanged: (val) => setState(() => _classNum = val!),
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    // Chapter Number
                    SizedBox(
                      width: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chap No.', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _chapterNumController,
                            hint: '1',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            borderColor: borderColor,
                            textColor: textColor,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              if (int.tryParse(val) == null) return 'Must be int';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Chapter Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chapter Name', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _chapterController,
                            hint: 'e.g. Electric Charges & Fields',
                            isDark: isDark,
                            borderColor: borderColor,
                            textColor: textColor,
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Type, Difficulty
                Row(
                  children: [
                    // Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 6),
                          _buildDropdown(
                            value: _type,
                            items: _types,
                            onChanged: (val) => setState(() => _type = val!),
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Difficulty
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Difficulty', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 6),
                          _buildDropdown(
                            value: _difficulty,
                            items: _difficulties,
                            onChanged: (val) => setState(() => _difficulty = val!),
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Front Text (Question)
                Text('Front Text (Question)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _frontController,
                  hint: 'Enter card question (Markdown/LaTeX supported)',
                  maxLines: 4,
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Back Text (Answer)
                Text('Back Text (Answer)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _backController,
                  hint: 'Enter card answer/solution details',
                  maxLines: 6,
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // NCERT Ref
                Text('NCERT Reference', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _ncertRefController,
                  hint: 'e.g. Page 12, Chapter 2',
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Tags
                Text('Tags (Comma separated)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _tagsController,
                  hint: 'e.g. electric_field, gauss_law',
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen,
                      foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: (isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen).withOpacity(0.3),
                    ),
                    child: Text(
                      widget.card != null ? 'Update Flashcard' : 'Create Flashcard',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: cardBg,
          style: GoogleFonts.inter(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
          items: items.map((val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: textColor, fontSize: 13.5),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted, fontSize: 12.5),
        fillColor: isDark ? AppTheme.cardDark : Colors.white,
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
    );
  }
}
