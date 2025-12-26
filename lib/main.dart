import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/app_providers.dart';
import 'theme/aligna_theme.dart';
import 'screens/bootstrap_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://tfyzjqrgwjiturirjrpt.supabase.co', // Live Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmeXpqcXJnd2ppdHVyaXJqcnB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzODU4NTQsImV4cCI6MjA4MTk2MTg1NH0.2GQt7Nu2XnhLNHaAm8BZ16-GM37vVzBay1ROxrs8inY', // Live Supabase anon key
    );
  } catch (e) {
    // Supabase initialization failed, continue without it for UI testing
    print('Supabase initialization failed: $e');
  }

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


