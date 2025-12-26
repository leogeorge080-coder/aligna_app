import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/app_providers.dart';
import '../utils/haptics.dart';
import 'onboarding_quiz_screen.dart';

class FrequencySelectionScreen extends ConsumerStatefulWidget {
  const FrequencySelectionScreen({super.key});

  @override
  ConsumerState<FrequencySelectionScreen> createState() =>
      _FrequencySelectionScreenState();
}

class _FrequencySelectionScreenState
    extends ConsumerState<FrequencySelectionScreen> {
  final Set<String> _selected = <String>{};
  bool _isSaving = false;

  final List<_FrequencyOption> _options = const [
    _FrequencyOption(
      keyName: 'abundance',
      title: 'Abundance',
      subtitle: 'Call in prosperity and flow.',
      color: Color(0xFFFFD700),
    ),
    _FrequencyOption(
      keyName: 'inner_peace',
      title: 'Inner Peace',
      subtitle: 'Calm your nervous system.',
      color: Color(0xFF22C55E),
    ),
    _FrequencyOption(
      keyName: 'love',
      title: 'Love',
      subtitle: 'Open your heart to connection.',
      color: Color(0xFFFF69B4),
    ),
    _FrequencyOption(
      keyName: 'health',
      title: 'Health',
      subtitle: 'Restore energy and momentum.',
      color: Color(0xFF60A5FA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canContinue = _selected.isNotEmpty && !_isSaving;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              Text(
                'Choose your frequencies',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Select one or more intentions to guide Lumi’s support.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  for (final option in _options)
                    _FrequencyCard(
                      option: option,
                      selected: _selected.contains(option.keyName),
                      onTap: () {
                        setState(() {
                          if (_selected.contains(option.keyName)) {
                            _selected.remove(option.keyName);
                          } else {
                            _selected.add(option.keyName);
                          }
                        });
                        AppHaptics.light();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 32),
              AnimatedOpacity(
                opacity: canContinue ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: canContinue ? _saveAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : const Text('Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final values = _selected.toList();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('user_preferences').upsert({
          'user_id': user.id,
          'selected_frequencies': values,
        });
      }
    } catch (e) {
      debugPrint('Failed to save frequencies: $e');
    }

    ref.read(selectedProgramTypeProvider.notifier).state = null;

    if (!mounted) return;
    await AppHaptics.success();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingQuizScreen()),
    );

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}

class _FrequencyOption {
  final String keyName;
  final String title;
  final String subtitle;
  final Color color;

  const _FrequencyOption({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _FrequencyCard extends StatelessWidget {
  const _FrequencyCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _FrequencyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: selected ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? option.color : Colors.white.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: option.color.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.auto_awesome,
              color: option.color,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              option.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              option.subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
