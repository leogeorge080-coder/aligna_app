import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/app_providers.dart';
import '../widgets/choice_card.dart';
import '../utils/haptics.dart';
import '../persistence/prefs.dart';
import '../services/user_events_service.dart';
import 'app_shell.dart';

class MoodSelectScreen extends ConsumerStatefulWidget {
  const MoodSelectScreen({super.key});

  @override
  ConsumerState<MoodSelectScreen> createState() => _MoodSelectScreenState();
}

class _MoodSelectScreenState extends ConsumerState<MoodSelectScreen> {
  AlignaMood? selectedMood;

  Future<void> _confirmMood() async {
    final mood = selectedMood;
    if (mood == null) return;

    // ✅ Save mood for the current greeting window
    await Prefs.saveMoodForNow(mood);
    ref.read(moodProvider.notifier).state = mood;
    await UserEventsService.logEvent(
      eventType: 'mood_log',
      payload: {'mood': mood.name},
    );

    if (!mounted) return;

    // ✅ If this screen was pushed (e.g., "Change mood"), pop it.
    // ✅ If it's the root after Bootstrap, Bootstrap will rebuild automatically.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.howAreYou),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              t.noRightAnswer,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              t.shapeGuidance,
              style: const TextStyle(color: Color(0xFFB6B9C6)),
            ),
            const SizedBox(height: 16),

            ChoiceCard(
              title: 'Calm',
              subtitle: 'Steady and okay',
              selected: selectedMood == AlignaMood.calm,
              onTap: () async {
                await AppHaptics.light();
                setState(() => selectedMood = AlignaMood.calm);
              },
            ),
            ChoiceCard(
              title: 'Stressed',
              subtitle: 'A bit overwhelmed',
              selected: selectedMood == AlignaMood.stressed,
              onTap: () async {
                await AppHaptics.light();
                setState(() => selectedMood = AlignaMood.stressed);
              },
            ),
            ChoiceCard(
              title: 'Tired',
              subtitle: 'Low energy today',
              selected: selectedMood == AlignaMood.tired,
              onTap: () async {
                await AppHaptics.light();
                setState(() => selectedMood = AlignaMood.tired);
              },
            ),
            ChoiceCard(
              title: 'Motivated',
              subtitle: 'Ready to move',
              selected: selectedMood == AlignaMood.motivated,
              onTap: () async {
                await AppHaptics.light();
                setState(() => selectedMood = AlignaMood.motivated);
              },
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedMood != null ? _confirmMood : null,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
