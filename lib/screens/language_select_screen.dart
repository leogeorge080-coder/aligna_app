import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/app_providers.dart';
import '../persistence/prefs.dart';
import '../widgets/choice_card.dart';
import '../utils/haptics.dart';

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = L10n.of(ref);

    Future<void> setLang(String lang) async {
      ref.read(languageProvider.notifier).state = lang;
      await Prefs.saveLang(lang);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.appName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              t.chooseLanguage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              t.changeLater,
              style: const TextStyle(color: Color(0xFFB6B9C6)),
            ),
            const SizedBox(height: 16),
            ChoiceCard(
              title: 'English',
              subtitle: 'Recommended',
              onTap: () async {
                await AppHaptics.tap();
                await setLang('en');
              },
            ),
            ChoiceCard(
              title: 'العربية',
              subtitle: 'Arabic (RTL)',
              onTap: () async {
                await AppHaptics.tap();
                await setLang('ar');
              },
            ),
            ChoiceCard(
              title: 'हिन्दी',
              subtitle: 'Hindi',
              onTap: () async {
                await AppHaptics.tap();
                await setLang('hi');
              },
            ),
            ChoiceCard(
              title: 'Español',
              subtitle: 'Spanish',
              onTap: () async {
                await AppHaptics.tap();
                await setLang('es');
              },
            ),
          ],
        ),
      ),
    );
  }
}
