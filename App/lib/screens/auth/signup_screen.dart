import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final success = await auth.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (success && mounted) {
        Navigator.pop(context); // Go back to login screen on success (auth listener will trigger routing)
      } else if (!success && mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleGoogleSignUp() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (success && mounted) {
      Navigator.pop(context); // Return on successful sign in
    } else if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();
    
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark ? AppTheme.cardDark : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.cardBorder : AppTheme.lightCardBorder;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──
          Container(
            decoration: BoxDecoration(
              gradient: isDark ? AppTheme.splashGradient : AppTheme.lightSplashGradient,
            ),
          ),
          
          // ── Back Button ──
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // ── Scrollable Body ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Create Account',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      Text(
                        'Join MEDNEET to sync your flashcard study progress',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: subColor,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      
                      const SizedBox(height: 32),
                      
                      // Glassmorphic Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg.withOpacity(isDark ? 0.85 : 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign Up',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Name Field
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: GoogleFonts.inter(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: GoogleFonts.inter(color: subColor, fontSize: 13),
                                prefixIcon: Icon(Icons.person_outline_rounded, color: subColor, size: 20),
                                filled: true,
                                fillColor: isDark ? AppTheme.primaryDark.withOpacity(0.5) : AppTheme.lightBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.inter(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: GoogleFonts.inter(color: subColor, fontSize: 13),
                                prefixIcon: Icon(Icons.email_outlined, color: subColor, size: 20),
                                filled: true,
                                fillColor: isDark ? AppTheme.primaryDark.withOpacity(0.5) : AppTheme.lightBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: GoogleFonts.inter(color: subColor, fontSize: 13),
                                prefixIcon: Icon(Icons.lock_outlined, color: subColor, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: subColor,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: isDark ? AppTheme.primaryDark.withOpacity(0.5) : AppTheme.lightBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // SignUp Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen,
                                  foregroundColor: isDark ? AppTheme.primaryDark : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: authProvider.isLoading ? null : _handleSignUp,
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : Text(
                                        'Create Account',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: borderColor, thickness: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'or',
                                    style: GoogleFonts.inter(fontSize: 12, color: subColor),
                                  ),
                                ),
                                Expanded(child: Divider(color: borderColor, thickness: 1)),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Google SignUp Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: borderColor, width: 1.5),
                                  backgroundColor: isDark ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.white,
                                  foregroundColor: textColor,
                                ),
                                onPressed: authProvider.isLoading ? null : _handleGoogleSignUp,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: CustomPaint(
                                          painter: GoogleIconPainter(
                                            backgroundColor: isDark ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.white,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      'Continue with Gmail',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Log In Prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: GoogleFonts.inter(fontSize: 13, color: subColor),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Log In',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.accentGreen : AppTheme.lightPrimaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a clean vector Google G logo
class GoogleIconPainter extends CustomPainter {
  final Color backgroundColor;
  GoogleIconPainter({this.backgroundColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    final Paint paint = Paint()..style = PaintingStyle.fill;
    
    // Red quadrant (Top)
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r * 0.707, cy - r * 0.707)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), -math.pi / 4, -math.pi / 2, false)
      ..lineTo(cx, cy);
    canvas.drawPath(redPath, paint);

    // Yellow quadrant (Left)
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - r * 0.707, cy - r * 0.707)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), -3 * math.pi / 4, -math.pi / 2, false)
      ..lineTo(cx, cy);
    canvas.drawPath(yellowPath, paint);

    // Green quadrant (Bottom)
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - r * 0.707, cy + r * 0.707)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), 3 * math.pi / 4, -math.pi / 2, false)
      ..lineTo(cx, cy);
    canvas.drawPath(greenPath, paint);

    // Blue quadrant (Right)
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r * 0.707, cy + r * 0.707)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi / 4, -math.pi / 2, false)
      ..lineTo(cx, cy);
    canvas.drawPath(bluePath, paint);

    // Draw inner circle cut-out matching the parent's background color
    paint.color = backgroundColor;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);

    // Draw Blue central horizontal bar for the "G" shape
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(cx, cy - r * 0.2, r * 0.9, r * 0.4), paint);
  }

  @override
  bool shouldRepaint(covariant GoogleIconPainter oldDelegate) => oldDelegate.backgroundColor != backgroundColor;
}
