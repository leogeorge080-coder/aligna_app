// lib/screens/bootstrap_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../persistence/prefs.dart';
import '../theme/aligna_theme.dart';

import 'language_select_screen.dart';
import 'mood_select_screen.dart';
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
    // 1) Language: show LanguageSelectScreen only if not chosen yet
    final lang = await Prefs.loadLang();
    ref.read(languageProvider.notifier).state = lang;

    // 2) Mood: valid only for current greeting window
    final mood = await Prefs.loadMoodForNow();
    ref.read(moodProvider.notifier).state = mood;

    // 3) Active program
    final activeProgramId = await Prefs.loadActiveProgramId();
    ref
        .read(activeProgramIdProvider.notifier)
        .state = (activeProgramId == null || activeProgramId.trim().isEmpty)
        ? null
        : activeProgramId;

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
    final mood = ref.watch(moodProvider);

    if (lang == null) return const LanguageSelectScreen();
    if (mood == null) return const MoodSelectScreen();
    return const AppShell();
  }
}
