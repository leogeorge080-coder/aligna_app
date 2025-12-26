// lib/screens/coach_home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/program_providers.dart';
import '../models/program_session.dart';
import '../providers/program_session_bundle_provider.dart';
import '../providers/program_progress_actions_provider.dart';
import '../providers/program_catalogue_provider.dart';
import '../providers/program_progress_provider.dart';
import '../providers/program_progress_store_provider.dart';
import '../providers/resume_copy_provider.dart';
import '../models/program_progress.dart';
import '../models/program_resume_plan.dart';

// ─────────────────────────────────────────────
// App-level state & providers
// ─────────────────────────────────────────────
import 'package:aligna_app/providers/app_providers.dart' as app;
import '../providers/coach_llm_provider.dart';
import '../providers/micro_action_provider.dart';
import '../providers/coach_enhance_providers.dart';
import '../services/coach_enhance_service.dart';

// ─────────────────────────────────────────────
// App infrastructure
// ─────────────────────────────────────────────
import '../l10n/l10n.dart';
import '../persistence/prefs.dart';

// ─────────────────────────────────────────────
// UI / theme / utilities
// ─────────────────────────────────────────────
import '../theme/aligna_theme.dart';
import '../utils/haptics.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/typing_bubble.dart';
import 'coach_video_screen.dart';
import 'celebration_screen.dart';
import '../services/journal_service.dart';
import '../widgets/calm_cue.dart';
import '../widgets/program_picker_sheet.dart';
import '../widgets/animated_gradient_background.dart';
import '../widgets/coach_widgets.dart';
import '../widgets/staggered_coach_bubbles.dart';
import 'welcome_celebration_screen.dart';
import '../models/program_type.dart';
import '../widgets/reactive_aura_widget.dart';
import '../services/program_service.dart';
import '../providers/daily_content_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class CoachHomeScreen extends ConsumerStatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  ConsumerState<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends ConsumerState<CoachHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  Timer? _expiryTimer;
  bool _expired = false;

  // Reflection controllers (key: 'programId_day')
  final Map<String, TextEditingController> _reflectionControllers = {};

  // Simple UI toggle (fully open mode: both available)
  final ProgramTimeOfDay _timeOfDay = ProgramTimeOfDay.morning;

  // Dynamic greeting state
  String _currentGreeting = '';
  String _currentMotivation = '';
  // late AnimationController _greetingController;
  // late Animation<double> _greetingSlideAnimation;

  // Animation states
  double _greetingOpacity = 0.0;
  double _progressValue = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Daily refresh timer
  Timer? _dailyRefreshTimer;

  @override
  void initState() {
    super.initState();
    // Initialize pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize greeting animation
    // _greetingController = AnimationController(
    //   duration: const Duration(milliseconds: 800),
    //   vsync: this,
    // );
    // _greetingSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
    //   CurvedAnimation(parent: _greetingController, curve: Curves.elasticOut),
    // );

    // Generate dynamic greeting
    _generateDynamicGreeting();

    // Start greeting animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // _greetingController.forward();
        setState(() {
          _greetingOpacity = 1.0;
        });
      }
    });

    // Start progress circle fill animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _progressValue = 0.7; // TODO: Use actual progress
        });
      }
    });

    // Set up daily refresh timer
    _scheduleDailyRefresh();

    // Check for welcome celebration
    _checkAndShowWelcome();

    // Pre-cache audio for active program
    _preCacheAudio();
  }

  void _generateDynamicGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    final userName = ref.read(app.userNameProvider) ?? 'there';

    // Time-based greeting variations
    String timeGreeting;
    String motivation;

    if (hour < 12) {
      timeGreeting = 'Good morning';
      motivation = 'Your vibration is rising beautifully.';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
      motivation = 'You\'re doing amazing work.';
    } else {
      timeGreeting = 'Good evening';
      motivation = 'Your energy is transforming everything.';
    }

    // Add emotional variations based on progress (simplified for now)
    final emotionalVariations = [
      'Your vibration is rising beautifully.',
      'You\'re doing amazing work.',
      'Your energy is transforming everything.',
      'You\'re becoming more aligned every day.',
      'Your presence is making a difference.',
      'You\'re exactly where you need to be.',
    ];

    motivation = emotionalVariations[now.day % emotionalVariations.length];

    _currentGreeting = '$timeGreeting, $userName.';
    _currentMotivation = motivation;
  }

  Future<void> _preCacheAudio() async {
    final activeProgramId = ref.read(app.activeProgramIdProvider);
    if (activeProgramId != null) {
      // Start fetching daily content (including audio URL) in background
      // This will cache the data so it's ready when user starts session
      try {
        await ref.read(dailyContentProvider(activeProgramId).future);
      } catch (e) {
        // Silently fail - pre-caching is best effort
        // User will still get proper error handling when they actually try to play
      }
    }
  }

  Future<void> _checkAndShowWelcome() async {
    final onboardingCompleted = ref.read(app.onboardingCompletedProvider);
    final welcomeShown = await Prefs.getWelcomeShown();
    final userName = ref.read(app.userNameProvider);

    if (onboardingCompleted && !welcomeShown && userName != null && mounted) {
      // Show welcome celebration
      await Future.delayed(
        const Duration(milliseconds: 1500),
      ); // Wait for screen to settle
      if (mounted) {
        await AppHaptics.success();
        await Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) =>
                WelcomeCelebrationScreen(userName: userName),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
        // Mark welcome as shown
        await Prefs.saveWelcomeShown(true);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // _greetingController.dispose();
    _dailyRefreshTimer?.cancel();
    _expiryTimer?.cancel();
    _controller.dispose();
    for (final c in _reflectionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _endSessionUiOnly() async {
    // UI-only cleanup. Do NOT clear mood. Do NOT pop navigation.
    ref.read(coachLlmProvider.notifier).clear();
    resetMicroActionFromWidget(ref);
    _controller.clear();

    _expiryTimer?.cancel();
    setState(() {
      _expired = false;
      ref.read(microActionStatusProvider.notifier).state =
          MicroActionStatus.offered;
    });
  }

  void _scheduleDailyRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
      0,
      0,
      0,
    ); // 12:00 AM tomorrow
    final duration = tomorrow.difference(now);

    _dailyRefreshTimer = Timer(duration, () {
      _refreshDailyIntention(ref);
      // Schedule next refresh
      _scheduleDailyRefresh();
    });
  }

  void _refreshDailyIntention(WidgetRef ref) {
    // TODO: Fetch daily intention from server
    // For now, just invalidate relevant providers to refresh data
    ref.invalidate(programCatalogueProvider);
    ref.invalidate(programProgressProvider);
    // Add any other providers that need daily refresh
  }

  Future<void> _ensureReflectionLoaded(String programId, int day) async {
    final key = '${programId}_$day';
    if (_reflectionControllers.containsKey(key)) return;

    final previous = await Prefs.loadReflection(programId, day);
    if (!mounted) return;

    setState(() {
      _reflectionControllers[key] = TextEditingController(text: previous ?? '');
    });
  }

  Widget _buildReflectionField(String programId, int day) {
    final key = '${programId}_$day';
    final c = _reflectionControllers[key];
    if (c == null) {
      _ensureReflectionLoaded(programId, day);
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: SizedBox(height: 18, child: LinearProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: c,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Your reflection...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () async {
              final value = c.text.trim();
              if (value.isEmpty) return;

              // Save to local prefs as backup
              await Prefs.saveReflection(programId, day, value);

              // Get current user and program IDs
              final userId = JournalService.getCurrentUserId();
              final activeProgramId = ref.read(app.activeProgramIdProvider);

              if (userId != null && activeProgramId != null) {
                // Save to database
                final success = await JournalService.saveJournalEntry(
                  userId: userId,
                  programId: activeProgramId,
                  dayNumber: day,
                  journalEntryText: value,
                );

                if (success && mounted) {
                  // Show celebration screen
                  await Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          CelebrationScreen(journalText: value, dayNumber: day),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Reflection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AlignaColors.radiantGold,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgramSession(
    BuildContext context,
    ProgramSessionBundle bundle,
    ProgramSessionRequest req,
  ) {
    final s = bundle.session;

    final resumeLine =
        bundle.plan.showResumeLine && req.timeOfDay == ProgramTimeOfDay.morning
        ? (bundle.plan.resumeTone == 'warm'
              ? s.resumeCopy.warm
              : s.resumeCopy.neutral)
        : null;

    return const Text('Program Session Placeholder');
  }

  // Robust extractors for both Map-based and typed catalogue models
  String? _catalogueProgramId(dynamic item) {
    if (item == null) return null;
    if (item is Map) {
      final v = item['programId'] ?? item['id'];
      return v is String && v.trim().isNotEmpty ? v : null;
    }
    try {
      // Try programId first (legacy), then id (new Program model)
      final v = (item as dynamic).programId ?? (item as dynamic).id;
      return v is String && v.trim().isNotEmpty ? v : null;
    } catch (_) {
      return null;
    }
  }

  int? _catalogueDurationDays(dynamic item) {
    if (item == null) return null;
    if (item is Map) {
      final v = item['durationDays'];
      return v is int ? v : int.tryParse('$v');
    }
    try {
      final v = (item as dynamic).durationDays;
      return v is int ? v : int.tryParse('$v');
    } catch (_) {
      return null;
    }
  }

  String _extractTitle(dynamic item) {
    if (item == null) return 'Program';
    if (item is Map) {
      final v = item['title'];
      return v is String && v.trim().isNotEmpty ? v : 'Program';
    }
    try {
      final v = (item as dynamic).title;
      return v is String && v.trim().isNotEmpty ? v : 'Program';
    } catch (_) {
      return 'Program';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(ref);

    final appMood = ref.watch(app.moodProvider);
    final heartMood = ref.watch(app.heartMoodProvider);
    final replyState = ref.watch(coachLlmProvider);

    final actionText = ref.watch(microActionTextProvider);
    final actionStatus = ref.watch(microActionStatusProvider);

    final catalogueAsync = ref.watch(programCatalogueProvider);

    // Get user name from onboarding
    final userName = ref.watch(app.userNameProvider) ?? 'User';

    // IMPORTANT: treat empty string as null (common prefs bug source)
    final rawActiveId = ref.watch(app.activeProgramIdProvider);
    final activeId = (rawActiveId == null || rawActiveId.trim().isEmpty)
        ? null
        : rawActiveId;

    final progressAsync = activeId == null
        ? const AsyncValue.data(null)
        : ref.watch(programProgressProvider);

    // Get raw progress data for completion check
    final rawProgressAsync = activeId == null
        ? const AsyncValue.data(null)
        : ref.watch(
            FutureProvider<ProgramProgress?>((ref) async {
              final store = ref.read(programProgressStoreProvider);
              return await store.read(activeId!);
            }),
          );

    final resumeAsync = activeId == null
        ? const AsyncValue.data(
            ResumeCopyResult(text: null, shouldMarkShown: false),
          )
        : ref.watch(resumeCopyProvider);

    // Fetch daily content for day 1 using onboarding data
    final dailyContentAsync = activeId == null
        ? const AsyncValue.data(null)
        : ref.watch(
            dailyContentForProgramDayProvider((
              programId: activeId,
              dayNumber: 1,
            )),
          );

    // Fetch program details for theme color
    final programDetailsAsync = activeId == null
        ? const AsyncValue.data(null)
        : ref.watch(
            FutureProvider<Map<String, dynamic>?>((ref) async {
              return await ProgramService.getProgramById(activeId);
            }),
          );

    // Get theme color for dynamic button styling
    final themeColorAsync = activeId == null
        ? const AsyncValue.data(null)
        : ref.watch(programThemeColorProvider(activeId));

    // Initialize from onboarding data instead of mood
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Section A: The Greeting (Header)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Small profile icon on the top left
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AlignaColors.accent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      // "Notification bell" on the top right
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          // TODO: Implement notification action
                        },
                      ),
                    ],
                  ),
                ),
                // Dynamic greeting with slide animation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedOpacity(
                    opacity: _greetingOpacity,
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _currentGreeting,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w600,
                                  color: AlignaColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentMotivation,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AlignaColors.subtext,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Section B: The Hero Progress Circle
                Flexible(
                  flex: 2,
                  child: progressAsync.when(
                    data: (progress) {
                      final currentProgress = progress != null
                          ? progress.day / progress.totalDays
                          : 0.0;
                      final progressPercent = (currentProgress * 100).round();
                      final dayText = progress != null
                          ? progress.isComplete
                                ? 'Final day · ${progress.totalDays} of ${progress.totalDays}'
                                : 'Day ${progress.day} of ${progress.totalDays}'
                          : 'No progress';

                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Large circular progress bar
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: currentProgress,
                                ),
                                duration: const Duration(seconds: 2),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 8,
                                    backgroundColor: AlignaColors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      themeColorAsync.maybeWhen(
                                        data: (color) =>
                                            color ?? AlignaColors.accent,
                                        orElse: () => AlignaColors.accent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Big Text: "70%"
                            programDetailsAsync.maybeWhen(
                              data: (programDetails) {
                                final secondaryColor =
                                    programDetails != null &&
                                        programDetails['secondary_color'] !=
                                            null
                                    ? Color(
                                        int.parse(
                                          programDetails['secondary_color']
                                              .replaceFirst('#', '0xff'),
                                        ),
                                      )
                                    : AlignaColors.primary;
                                return Text(
                                  '$progressPercent%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                      ),
                                );
                              },
                              orElse: () => Text(
                                '$progressPercent%',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AlignaColors.primary,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Sub-text: "Day 4 of 21"
                            Text(
                              dayText,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AlignaColors.subtext),
                            ),
                            const SizedBox(height: 16),
                            // Streak counter and celebration
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AlignaColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AlignaColors.accent.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_fire_department,
                                    color: AlignaColors.accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '7 day streak! 🔥',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AlignaColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Progress milestone celebration
                            if (progressPercent >= 75) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AlignaColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AlignaColors.gold.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AlignaColors.gold,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      progressPercent >= 90
                                          ? 'Almost there! 🌟'
                                          : 'Great progress! ⭐',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AlignaColors.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Error loading progress')),
                  ),
                ),
                // Section B.5: Reactive Aura (if program details loaded)
                programDetailsAsync.maybeWhen(
                  data: (programDetails) {
                    if (programDetails != null &&
                        programDetails['theme_color'] != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ReactiveAuraWidget(
                          lumiImageUrl: 'assets/coach/aligna_coach.png',
                          programId: activeId,
                          restIntensity: 0.3,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                // Section C: The Primary Action (The "Start" Card)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AlignaColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"Every step forward is a victory worth celebrating."',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AlignaColors.subtext,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: catalogueAsync.when(
                    data: (catalogue) {
                      print(
                        '📊 [CoachHomeScreen] Catalogue loaded: ${catalogue?.length ?? 0} programs',
                      );
                      final matchingItems = catalogue
                          ?.where(
                            (item) => _catalogueProgramId(item) == activeId,
                          )
                          .toList();
                      print(
                        '📊 [CoachHomeScreen] Matching items for activeId $activeId: ${matchingItems?.length ?? 0}',
                      );

                      final activeItem = matchingItems?.isNotEmpty == true
                          ? matchingItems!.first
                          : null;
                      print(
                        '📊 [CoachHomeScreen] Active item: ${activeItem != null ? 'found' : 'null'}',
                      );

                      final dayTitle = progressAsync.maybeWhen(
                        data: (progress) =>
                            progress != null ? 'Day ${progress.day}' : 'Start',
                        orElse: () => 'Start',
                      );
                      final programTitle = dailyContentAsync.maybeWhen(
                        data: (dailyContent) =>
                            dailyContent?.title ?? 'Daily Session',
                        orElse: () => activeItem != null
                            ? _extractTitle(activeItem)
                            : 'Program',
                      );

                      // Check if today's task is completed
                      final isTodayCompleted = progressAsync.maybeWhen(
                        data: (progress) => rawProgressAsync.maybeWhen(
                          data: (rawProgress) =>
                              progress != null &&
                              rawProgress != null &&
                              progress.day <= rawProgress.lastCompletedDay,
                          orElse: () => false,
                        ),
                        orElse: () => false,
                      );

                      return Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0x33FFD700),
                                Color(0x337678ED),
                              ], // 20% opacity versions
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Pulsing button with Hero transition
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Hero(
                                      tag: 'start_button',
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // Haptic feedback: double-pulse heartbeat
                                            await HapticFeedback.mediumImpact();
                                            await Future.delayed(
                                              const Duration(milliseconds: 100),
                                            );
                                            await HapticFeedback.lightImpact();

                                            // Navigate to video player screen with Hero transition
                                            final activeProgramId = ref.read(
                                              app.activeProgramIdProvider,
                                            );
                                            final programDetails =
                                                programDetailsAsync.maybeWhen(
                                                  data: (data) => data,
                                                  orElse: () => null,
                                                );
                                            final programType =
                                                programDetails != null
                                                ? ProgramType.fromString(
                                                    programDetails['track'] ??
                                                        'support',
                                                  )
                                                : ProgramType.support;

                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VideoPlayerScreen(
                                                      programId:
                                                          activeProgramId,
                                                      programType: programType,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeColorAsync
                                                .maybeWhen(
                                                  data: (color) =>
                                                      color ??
                                                      AlignaColors.primary,
                                                  orElse: () =>
                                                      AlignaColors.primary,
                                                ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (isTodayCompleted) ...[
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: AlignaColors.gold,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  isTodayCompleted
                                                      ? 'Rewatch Session'
                                                      : 'Enter $dayTitle: $programTitle',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () {
                      print('⏳ [CoachHomeScreen] Catalogue loading...');
                      return const Center(child: CircularProgressIndicator());
                    },
                    error: (error, stack) {
                      print('❌ [CoachHomeScreen] Catalogue error: $error');
                      print('❌ [CoachHomeScreen] Stack: $stack');
                      return Center(
                        child: Text('Error loading catalogue: $error'),
                      );
                    },
                  ),
                ),
                // Section D: Floating Action Buttons (The Tools)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your transformation toolkit',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AlignaColors.subtext,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Journal (Pen icon) - with emotional tooltip
                          FloatingActionButton(
                            heroTag: 'journal',
                            onPressed: () async {
                              await AppHaptics.light();
                              // TODO: Open blank reflection page
                            },
                            backgroundColor: AlignaColors.accent.withOpacity(
                              0.9,
                            ),
                            child: const Icon(
                              Icons.edit_note,
                              color: Colors.white,
                            ),
                            tooltip: 'Reflect on your journey',
                          ),
                          // Frequency (Soundwave icon) - with emotional tooltip
                          FloatingActionButton(
                            heroTag: 'frequency',
                            onPressed: () async {
                              await AppHaptics.light();
                              // TODO: Open mini-player for 528Hz/432Hz audio
                            },
                            backgroundColor: AlignaColors.primary.withOpacity(
                              0.9,
                            ),
                            child: const Icon(Icons.waves, color: Colors.white),
                            tooltip: 'Tune into healing frequencies',
                          ),
                          // Vision (Image icon) - with emotional tooltip
                          FloatingActionButton(
                            heroTag: 'vision',
                            onPressed: () async {
                              await AppHaptics.light();
                              // TODO: Open user's Vision Board
                            },
                            backgroundColor: AlignaColors.gold.withOpacity(0.9),
                            child: const Icon(
                              Icons.visibility,
                              color: Colors.white,
                            ),
                            tooltip: 'Visualize your dreams',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 24,
                ), // Extra bottom padding for scroll safety
              ],
            ),
          ),
        ),
      ),
    );
  }
}
