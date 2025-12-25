// lib/screens/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'coach_home_screen.dart';
import 'programs_screen.dart';
import 'settings_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [CoachHomeScreen(), ProgramsScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(shellTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
