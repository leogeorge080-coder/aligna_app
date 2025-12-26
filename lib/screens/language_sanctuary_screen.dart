import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../persistence/prefs.dart';
import '../widgets/glass_card.dart';
import '../providers/app_providers.dart';
import '../providers/program_providers.dart';
import 'name_entry_screen.dart';

class Language {
  final String name;
  final String native;
  final String code;
  final String icon;

  const Language({
    required this.name,
    required this.native,
    required this.code,
    required this.icon,
  });
}

class LanguageSanctuaryScreen extends ConsumerStatefulWidget {
  const LanguageSanctuaryScreen({super.key});

  @override
  ConsumerState<LanguageSanctuaryScreen> createState() =>
      _LanguageSanctuaryScreenState();
}

class _LanguageSanctuaryScreenState
    extends ConsumerState<LanguageSanctuaryScreen>
    with TickerProviderStateMixin {
  String? _selectedLanguageCode;
  bool _isLoading = false;

  // Currently supported languages (with audio content)
  final List<Language> _allLanguages = const [
    Language(name: 'English', native: 'English', code: 'en', icon: '🌎'),
    Language(name: 'Spanish', native: 'Español', code: 'es', icon: '💃'),
    Language(name: 'Hindi', native: 'हिन्दी', code: 'hi', icon: '🕉️'),
    Language(name: 'Arabic', native: 'العربية', code: 'ar', icon: '🌙'),
    // Future languages (commented out until content is available):
    // Language(name: 'French', native: 'Français', code: 'fr', icon: '🇫🇷'),
    // Language(name: 'Tamil', native: 'தமிழ்', code: 'ta', icon: '🛕'),
    // Language(name: 'Malayalam', native: 'മലയാളം', code: 'ml', icon: '🌴'),
  ];

  // Get available languages based on database content
  List<Language> get _availableLanguages {
    final availableCodesAsync = ref.watch(availableLanguagesProvider);
    return availableCodesAsync.maybeWhen(
      data: (codes) {
        // If no languages in database, show default supported languages
        final effectiveCodes = codes.isNotEmpty
            ? codes
            : ['en', 'hi', 'ar', 'es'];
        return _allLanguages
            .where((lang) => effectiveCodes.contains(lang.code))
            .toList();
      },
      orElse: () => _allLanguages
          .where((lang) => ['en', 'hi', 'ar', 'es'].contains(lang.code))
          .toList(),
    );
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
                'Language Sanctuary',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'In which language shall we journey?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Language Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _availableLanguages.length,
                  itemBuilder: (context, index) {
                    final language = _availableLanguages[index];
                    final isSelected = _selectedLanguageCode == language.code;

                    return _LanguageCard(
                      language: language,
                      isSelected: isSelected,
                      onTap: () => _selectLanguage(language.code),
                      isLoading: _isLoading,
                    );
                  },
                ),
              ),

              // Continue Button
              if (_selectedLanguageCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continueToNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Continue',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() {
      _selectedLanguageCode = languageCode;
    });
  }

  Future<void> _continueToNextStep() async {
    if (_selectedLanguageCode == null) return;

    setState(() => _isLoading = true);

    try {
      // Try to save to Supabase if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .update({'preferred_language': _selectedLanguageCode})
            .eq('id', user.id);

        if (response.error != null) {
          // Log error but don't fail - continue with local save
          debugPrint('Failed to save language to Supabase: ${response.error}');
        }
      }

      // Always save to local prefs for offline access
      await Prefs.saveLang(_selectedLanguageCode!);

      // Update the global language provider
      ref.read(languageProvider.notifier).state = _selectedLanguageCode!;

      // Navigate to next step (name entry)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NameEntryScreen()),
        );
      }
    } catch (e) {
      // Even if Supabase fails, save locally and continue
      debugPrint('Error saving language: $e');

      // Save to local prefs as fallback
      await Prefs.saveLang(_selectedLanguageCode!);
      ref.read(languageProvider.notifier).state = _selectedLanguageCode!;

      // Continue to next step
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NameEntryScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _LanguageCard extends StatefulWidget {
  final Language language;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLoading;

  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
    required this.isLoading,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.isLoading
          ? null
          : () {
              _scaleController.forward().then(
                (_) => _scaleController.reverse(),
              );
              widget.onTap();
            },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassCard(
              blur: 10,
              opacity: 0.15,
              borderRadius: BorderRadius.circular(16),
              border: widget.isSelected
                  ? Border.all(color: const Color(0xFFFFD700), width: 2)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Text(
                      widget.language.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),

                    // Native name
                    Text(
                      widget.language.native,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // English name
                    Text(
                      widget.language.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
