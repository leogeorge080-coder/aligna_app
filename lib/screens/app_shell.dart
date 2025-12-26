// lib/screens/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_providers.dart';
import '../theme/aligna_theme.dart';
import 'home_sanctuary_screen.dart';
import 'coach_home_screen.dart';
import 'guidance_screen.dart';
import 'programs_screen.dart';
import 'profile_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomeSanctuaryScreen(),
          GuidanceScreen(),
          CoachHomeScreen(),
          ProgramsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AlignaColors.radiantGold,
                );
              }
              return GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AlignaColors.subtext,
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(shellTabIndexProvider.notifier).state = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome),
              label: 'Guide',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Coach',
            ),
            NavigationDestination(icon: Icon(Icons.list), label: 'Programs'),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
