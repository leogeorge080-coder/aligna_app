// lib/screens/bootstrap_screen.dart  (or lib/screens/aligna_bootstrap_screen.dart)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../persistence/prefs.dart';
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
    _load();
  }

  Future<void> _load() async {
    // 1) Language: persist once, default to English if missing
    final lang = await Prefs.loadLang();
    final resolvedLang = lang ?? const Locale('en');
    ref.read(languageProvider.notifier).state = resolvedLang;

    // If you want to persist the default the first time:
    if (lang == null) {
      await Prefs.saveLang(resolvedLang);
    }

    // 2) Mood: greeting-window scoped (may be null)
    // IMPORTANT: MoodSelect is NOT handled in bootstrap.
    // CoachHomeScreen should show MoodSelect when mood == null.
    final mood = await Prefs.loadMoodForNowOrNull(); // implement or rename
    ref.read(moodProvider.notifier).state = mood;

    if (!mounted) return;
    setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Always enter AppShell. Do not route to Language/Mood screens here.
    return const AppShell();
  }
}
