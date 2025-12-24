import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'theme/aligna_theme.dart';
import 'screens/bootstrap_screen.dart';

void main() {
  runApp(const ProviderScope(child: AlignaApp()));
}

class AlignaApp extends ConsumerWidget {
  const AlignaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAlignaTheme(),
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('hi'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AlignaBootstrapScreen(),
    );
  }
}
