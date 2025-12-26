// lib/screens/bootstrap_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/app_providers.dart';
import '../persistence/prefs.dart';
import '../services/program_service.dart';
import '../theme/aligna_theme.dart';
import '../models/program.dart';

import 'language_sanctuary_screen.dart';
import 'name_entry_screen.dart';
import 'mood_select_screen.dart';
import 'onboarding_quiz_screen.dart';
import 'app_shell.dart';

class AlignaBootstrapScreen extends ConsumerStatefulWidget {
  const AlignaBootstrapScreen({super.key});

  @override
  ConsumerState<AlignaBootstrapScreen> createState() =>
      _AlignaBootstrapScreenState();
}

class _AlignaBootstrapScreenState extends ConsumerState<AlignaBootstrapScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1) Language: load from prefs first, then check Supabase
    String? lang = await Prefs.loadLang();

    // 2) Load user profile data from Supabase if authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('preferred_language, name')
            .eq('id', user.id)
            .single();

        // Use Supabase language if available, otherwise keep prefs value
        if (response['preferred_language'] != null) {
          lang = response['preferred_language'];
        }

        // Load user name
        if (response['name'] != null) {
          ref.read(userNameProvider.notifier).state = response['name'];
        }
      } catch (e) {
        // Handle error silently - will fall back to prefs/local data
      }
    }

    ref.read(languageProvider.notifier).state = lang;

    // 3) Mood: valid only for current greeting window
    final mood = await Prefs.loadMoodForNow();
    ref.read(moodProvider.notifier).state = mood;

    // 4) Active program
    String? activeProgramId = await Prefs.loadActiveProgramId();
    activeProgramId = (activeProgramId == null || activeProgramId.trim().isEmpty)
        ? null
        : activeProgramId.trim();

    // Ensure we only keep a valid UUID from Supabase, not legacy slugs
    List<Program> programs = const [];
    try {
      programs = await ProgramService.getAllPrograms();
    } catch (_) {
      // If fetch fails, keep whatever is saved and avoid wiping prefs.
    }

    if (programs.isNotEmpty) {
      Program pickAbundance(List<Program> list) {
        for (final p in list) {
          if (p.track == 'money') return p;
        }
        for (final p in list) {
          if (p.slug.contains('money')) return p;
        }
        for (final p in list) {
          final title = p.title.toLowerCase();
          if (title.contains('money') || title.contains('abundance')) {
            return p;
          }
        }
        return list.first;
      }

      final preferred = pickAbundance(programs);
      final programIds = programs.map((p) => p.id).toSet();
      if (activeProgramId != null && !programIds.contains(activeProgramId)) {
        final resolved = await ProgramService.getProgramIdBySlug(activeProgramId);
        if (resolved != null && programIds.contains(resolved)) {
          final nextId = resolved;
          activeProgramId = nextId;
          await Prefs.saveActiveProgramId(nextId);
        } else {
          final nextId = preferred.id;
          activeProgramId = nextId;
          await Prefs.saveActiveProgramId(nextId);
        }
      } else if (activeProgramId == null) {
        final nextId = preferred.id;
        activeProgramId = nextId;
        await Prefs.saveActiveProgramId(nextId);
      }
    }

    ref.read(activeProgramIdProvider.notifier).state = activeProgramId;

    // 5) Onboarding completion
    final onboardingCompleted =
        activeProgramId != null && activeProgramId.isNotEmpty;
    ref.read(onboardingCompletedProvider.notifier).state = onboardingCompleted;

    if (!mounted) return;
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AlignaColors.bg,
        body: SizedBox.expand(),
      );
    }

    final lang = ref.watch(languageProvider);
    final userName = ref.watch(userNameProvider);
    final mood = ref.watch(moodProvider);
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    if (lang == null) return const LanguageSanctuaryScreen();
    if (userName == null) return const NameEntryScreen();
    if (!onboardingCompleted) return const OnboardingQuizScreen();
    if (mood == null) return const MoodSelectScreen();
    return const AppShell();
  }
}

