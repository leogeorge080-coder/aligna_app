import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/user_context_provider.dart';
import 'language_sanctuary_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider) ?? 'Friend';
    final contextAsync = ref.watch(userContextProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome, $userName',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          contextAsync.maybeWhen(
            data: (ctx) => Row(
              children: [
                _StatChip(
                  label: 'Streak',
                  value: '${ctx.streakCount} days',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Last guidance',
                  value: ctx.lastTarotCard == 'neutral'
                      ? 'None yet'
                      : ctx.lastTarotCard,
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Language Sanctuary'),
            subtitle: const Text('Choose your preferred language'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LanguageSanctuaryScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Settings'),
            subtitle: const Text('Account & app controls'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
