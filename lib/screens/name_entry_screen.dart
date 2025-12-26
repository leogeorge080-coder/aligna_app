import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_providers.dart';
import '../utils/haptics.dart';
import 'frequency_selection_screen.dart';

class NameEntryScreen extends ConsumerStatefulWidget {
  const NameEntryScreen({super.key});

  @override
  ConsumerState<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends ConsumerState<NameEntryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _underlineAnimationController;
  late Animation<double> _underlineWidthAnimation;
  late Animation<double> _underlineGlowAnimation;
  late AnimationController _buttonPulseController;
  late Animation<double> _buttonPulseAnimation;

  @override
  void initState() {
    super.initState();
    _underlineAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _underlineWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _underlineAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _underlineGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _underlineAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _buttonPulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _underlineAnimationController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Header
              Text(
                'Welcome to Aligna',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'What shall Lumi call you?',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Name Input
              Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    _underlineAnimationController.forward();
                  } else if (_nameController.text.isEmpty) {
                    _underlineAnimationController.reverse();
                  }
                },
                child: TextField(
                  controller: _nameController,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    setState(() {}); // Trigger rebuild for button state
                    if (value.isNotEmpty &&
                        !_underlineAnimationController.isCompleted) {
                      _underlineAnimationController.forward();
                    } else if (value.isEmpty &&
                        !_underlineAnimationController.isDismissed) {
                      _underlineAnimationController.reverse();
                    }
                  },
                  onSubmitted: (_) => _continueToQuiz(),
                ),
              ),

              const SizedBox(height: 16),

              // Animated Underline
              Container(
                height: 3,
                width: 220,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: Stack(
                  children: [
                    // Base line
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    // Animated fill
                    AnimatedBuilder(
                      animation: _underlineWidthAnimation,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _underlineWidthAnimation.value,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFD700),
                                  const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(
                                    alpha: _underlineGlowAnimation.value * 0.5,
                                  ),
                                  blurRadius: 8 * _underlineGlowAnimation.value,
                                  spreadRadius:
                                      2 * _underlineGlowAnimation.value,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue Button
              AnimatedOpacity(
                opacity: _nameController.text.trim().isNotEmpty ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 300),
                child: AnimatedBuilder(
                  animation: _buttonPulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _nameController.text.trim().isNotEmpty
                          ? _buttonPulseAnimation.value
                          : 1.0,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _nameController.text.trim().isNotEmpty
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFD700,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _nameController.text.trim().isNotEmpty
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: _nameController.text.trim().isNotEmpty
                                      ? const Color(
                                          0xFFFFD700,
                                        ).withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap:
                                      _nameController.text.trim().isNotEmpty &&
                                          !_isLoading
                                      ? _continueToQuiz
                                      : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFFFD700),
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Continue',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  _nameController.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? const Color(0xFFFFD700)
                                                  : Colors.white.withValues(
                                                      alpha: 0.6,
                                                    ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continueToQuiz() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Add haptic feedback for soul connection
    await AppHaptics.success();

    setState(() => _isLoading = true);

    try {
      // Try to save to Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .update({'name': name})
            .eq('id', user.id);

        if (response.error != null) {
          // Log error but don't fail
          debugPrint('Failed to save name to Supabase: ${response.error}');
        }
      }

      // Update the global name provider
      ref.read(userNameProvider.notifier).state = name;

      // Navigate to frequency selection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FrequencySelectionScreen()),
        );
      }
    } catch (e) {
      // Even if Supabase fails, continue with local state
      debugPrint('Error saving name: $e');

      // Update provider and continue
      ref.read(userNameProvider.notifier).state = name;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FrequencySelectionScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
