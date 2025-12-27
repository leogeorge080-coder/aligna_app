import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/user_preferences_provider.dart';
import '../providers/app_providers.dart';
import '../theme/aligna_theme.dart';
import '../theme/sanctuary_theme.dart';
import '../utils/frequency_colors.dart';
import '../providers/user_events_provider.dart';
import '../utils/list_extensions.dart';
import '../widgets/coach_bubble.dart';
import '../services/user_events_service.dart';
import '../providers/program_progress_provider.dart';
import '../widgets/liquid_progress_orb.dart';
import '../widgets/typing_bubble.dart';
import '../models/user_event.dart';

class HomeSanctuaryScreen extends ConsumerStatefulWidget {
  const HomeSanctuaryScreen({super.key});

  @override
  ConsumerState<HomeSanctuaryScreen> createState() =>
      _HomeSanctuaryScreenState();
}

class _HomeSanctuaryScreenState extends ConsumerState<HomeSanctuaryScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bloomController;
  late final AnimationController _breathController;
  late final AnimationController _textController;
  late final AnimationController _buttonController;
  late final AnimationController _listenerController;
  late final AnimationController _ctaPulseController;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Offset _parallaxOffset = Offset.zero;
  SanctuaryState _state = SanctuaryState.twilight;
  final Set<String> _selectedFrequencies = <String>{};
  String? _selectedMood;
  DateTime? _lastMoodSelectionAt;
  String? _bubbleText;
  String? _bubbleTarget;
  DateTime? _bubbleLockUntil;
  bool _showTyping = true;
  Timer? _bubbleTimer;
  final TextEditingController _wishController = TextEditingController();
  String? _currentWish;
  String? _currentWishFrequency;
  bool _isSubmittingWish = false;
  bool _wishGlow = false;
  Timer? _wishGlowTimer;
  final Random _rand = Random();
  bool _shouldPulseCta = false;
  LinearGradient _currentGradient = themeForState(SanctuaryState.twilight)
      .gradient();
  LinearGradient _previousGradient = themeForState(SanctuaryState.twilight)
      .gradient();

  @override
  void initState() {
    super.initState();
    _bloomController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _breathController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _listenerController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _ctaPulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _buttonController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _listenerController.forward();
    });

    _state = resolveSanctuaryState(DateTime.now());
    _currentGradient = themeForState(_state).gradient();
    _previousGradient = _currentGradient;

    _gyroSub = gyroscopeEventStream().listen((event) {
      if (!mounted) return;
      final next = Offset(event.y * 6, event.x * 6);
      setState(() {
        _parallaxOffset = Offset(
          next.dx.clamp(-10.0, 10.0),
          next.dy.clamp(-10.0, 10.0),
        );
      });
    });

    _scheduleStateRefresh();
    _scheduleBubbleAfterDelay(const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _bloomController.dispose();
    _breathController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _listenerController.dispose();
    _ctaPulseController.dispose();
    _wishController.dispose();
    _gyroSub?.cancel();
    _stateTimer?.cancel();
    _bubbleTimer?.cancel();
    _wishGlowTimer?.cancel();
    super.dispose();
  }

  Timer? _stateTimer;

  void _scheduleStateRefresh() {
    _stateTimer?.cancel();
    _stateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final next = resolveSanctuaryState(DateTime.now());
      if (next != _state && mounted) {
        setState(() {
          _state = next;
          _previousGradient = _currentGradient;
          _currentGradient = themeForState(_state).gradient();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selections = ref.watch(selectedFrequenciesProvider).maybeWhen(
      data: (value) => value,
      orElse: () => const <String>[],
    );
    if (_selectedFrequencies.isEmpty && selections.isNotEmpty) {
      _selectedFrequencies.addAll(selections);
    }
    final activeSelections =
        _selectedFrequencies.isNotEmpty ? _selectedFrequencies : selections.toSet();
    final colors = frequencyColorsFromSelections(activeSelections.toList());
    final energyLabel = activeSelections.isNotEmpty
        ? _displayLabel(activeSelections.first)
        : 'Neutral';
    final name = ref.watch(userNameProvider) ?? 'Leo';
    final progressAsync = ref.watch(programProgressProvider);

    final eventsAsync = ref.watch(userEventsProvider);
    final tarot = eventsAsync.maybeWhen(
      data: (events) => events
          .where((e) => e.eventType == 'tarot_draw')
          .map((e) => e.eventPayload['card'])
          .whereType<String>()
          .firstOrNull,
      orElse: () => null,
    );
    final lastMoodEvent = eventsAsync.maybeWhen(
      data: (events) {
        final moods =
            events.where((e) => e.eventType == 'mood_log').toList();
        if (moods.isEmpty) return null;
        moods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return moods.first;
      },
      orElse: () => null,
    );
    final now = DateTime.now().toUtc();
    final recentMood = lastMoodEvent != null &&
        now.difference(lastMoodEvent.createdAt).inHours < 4;
    final existingMood =
        lastMoodEvent?.eventPayload['mood'] as String?;
    final displayedMood = _selectedMood ?? existingMood;
    if (recentMood && displayedMood != null && !_shouldPulseCta) {
      _shouldPulseCta = true;
    }

    final bloom = CurvedAnimation(
      parent: _bloomController,
      curve: Curves.easeOutCubic,
    );
    final breath = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOutSine,
    );
    final scale = Tween<double>(begin: 0.0, end: 1.0).animate(bloom);
    final breathScale = Tween<double>(begin: 1.0, end: 1.03).animate(breath);
    final textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );
    final buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeOut));

    final greeting = tarot != null && tarot.trim().isNotEmpty
        ? '$name, the energy of $tarot is with you tonight.'
        : 'Good evening, $name.\nYour energy is transforming everything.';
    final listenerText = _resolveBubbleText(
      name: name,
      sanctuaryState: _state,
      recentTarot: _findRecentTarot(eventsAsync),
      selectedMood: _selectedMood,
      lastMoodSelectionAt: _lastMoodSelectionAt,
      recentMood: recentMood,
      existingMood: existingMood,
      lastSessionAt: _findLastSession(eventsAsync),
    );
    _ensureBubble(listenerText);
    final recentWish = _findRecentWish(eventsAsync);
    final activeWish = _currentWish ?? recentWish?.wish;
    final activeWishFrequency =
        _currentWishFrequency ?? recentWish?.frequency;
    final wishActive = activeWish != null && activeWish.trim().isNotEmpty;
    final wishGlowColor = _wishGlowColor(
      activeWishFrequency ?? activeSelections.firstOrNull,
    );
    final showMoodChips = !recentMood && displayedMood == null;
    final pulseCta = _shouldPulseCta || displayedMood != null;
    if (pulseCta && !_ctaPulseController.isAnimating) {
      _ctaPulseController.repeat(reverse: true);
    }
    if (!pulseCta && _ctaPulseController.isAnimating) {
      _ctaPulseController.stop();
      _ctaPulseController.value = 1.0;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: _parallaxOffset,
              child: TweenAnimationBuilder<LinearGradient>(
                duration: const Duration(milliseconds: 3000),
                curve: Curves.easeInOutCubic,
                tween: _GradientTween(
                  begin: _previousGradient,
                  end: _currentGradient,
                ),
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(gradient: value),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 0.9,
                    colors: [
                      Color(0x1AFFFFFF),
                      Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (wishActive)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _wishGlow ? 0.35 : 0.18,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: 0.9,
                        colors: [
                          wishGlowColor.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: colors.isNotEmpty
                              ? colors.first
                              : AlignaColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (colors.isNotEmpty
                                      ? colors.first
                                      : AlignaColors.accent)
                                  .withOpacity(0.45),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _stateLabel(_state),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        energyLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (!wishActive)
                  FadeTransition(
                    opacity: textFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        greeting,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          height: 1.55,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                if (wishActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ActiveWishCard(
                      wish: activeWish!,
                      frequency: _displayLabel(
                        activeWishFrequency ?? 'abundance',
                      ),
                      glow: wishGlowColor,
                    ),
                  ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _listenerController,
                    curve: Curves.easeOut,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showTyping) const TypingBubble(),
                          if (!_showTyping && _bubbleText != null)
                            CoachBubble(text: _bubbleText!),
                          if (!_showTyping && !wishActive) ...[
                            const SizedBox(height: 10),
                            _WishInputBubble(
                              controller: _wishController,
                              isSubmitting: _isSubmittingWish,
                              onSend: _submitWish,
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (showMoodChips)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final option in _moodOptions)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: _MoodChip(
                                        label: option,
                                        selected: displayedMood == option,
                                        onTap: () async {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _selectedMood = option;
                                            _shouldPulseCta = true;
                                            _lastMoodSelectionAt =
                                                DateTime.now().toUtc();
                                          });
                                          ref
                                              .read(currentMoodProvider
                                                  .notifier)
                                              .state = option;
                                          await UserEventsService.logEvent(
                                            eventType: 'mood_log',
                                            payload: {'mood': option},
                                          );
                                          _forceBubble(
                                            "I feel you. I've prepared your sanctuary for this energy.",
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (!showMoodChips)
                            progressAsync.maybeWhen(
                              data: (progress) {
                                final current = progress == null
                                    ? 0.0
                                    : progress.day / progress.totalDays;
                                return Center(
                                  child: LiquidProgressOrb(
                                    progress: current,
                                    primary: colors.isNotEmpty
                                        ? colors.first
                                        : AlignaColors.accent,
                                    secondary: Colors.white.withOpacity(0.4),
                                    size: 110,
                                  ),
                                );
                              },
                              orElse: () => Center(
                                child: LiquidProgressOrb(
                                  progress: 0.0,
                                  primary: colors.isNotEmpty
                                      ? colors.first
                                      : AlignaColors.accent,
                                  secondary: Colors.white.withOpacity(0.35),
                                  size: 110,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (!wishActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 26,
                                width: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 0.6,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Choose your frequency',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final option in _homeFrequencyOptions)
                                _HomeFrequencyChip(
                                  label: option.title,
                                  color: option.color,
                                  selected: activeSelections
                                      .contains(option.keyName),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      if (activeSelections
                                          .contains(option.keyName)) {
                                        _selectedFrequencies
                                            .remove(option.keyName);
                                      } else {
                                        _selectedFrequencies
                                            .add(option.keyName);
                                      }
                                    });
                                    _saveFrequencies(
                                      _selectedFrequencies.toList(),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (wishActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WishIdeasSection(
                      wish: activeWish!,
                      frequency: activeWishFrequency,
                      onTapIdea: (idea) {
                        _setWishGlow();
                        ref.read(shellTabIndexProvider.notifier).state = 2;
                        ref.read(startingStateProvider.notifier).state =
                            idea.ideaTitle;
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SlideTransition(
                  position: buttonSlide,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: AnimatedBuilder(
                      animation: _ctaPulseController,
                      builder: (context, child) {
                        final scale =
                            1.0 + (_ctaPulseController.value * 0.03);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: _GlassActionButton(
                        label: wishActive
                            ? 'Fuel This Wish'
                            : "Begin Today's Alignment",
                        onPressed: () async {
                          await HapticFeedback.lightImpact();
                          ref.read(shellTabIndexProvider.notifier).state = 2;
                        },
                      ),
                    ),
                  ),
                ),
              ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFrequencies(List<String> values) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('user_preferences').upsert({
        'user_id': user.id,
        'selected_frequencies': values,
      });
      ref.invalidate(selectedFrequenciesProvider);
    } catch (e) {
      debugPrint('[HomeSanctuary] Failed to save frequencies: $e');
    }
  }

  void _ensureBubble(String nextText) {
    if (_bubbleTarget == nextText) return;
    _bubbleTarget = nextText;
    _bubbleText = null;
    _showTyping = true;
    _scheduleBubbleAfterDelay(const Duration(milliseconds: 1200));
  }

  void _forceBubble(String nextText) {
    _bubbleTarget = nextText;
    _bubbleText = null;
    _showTyping = true;
    _bubbleLockUntil = DateTime.now().toUtc().add(const Duration(minutes: 5));
    _scheduleBubbleAfterDelay(const Duration(milliseconds: 1200));
  }

  void _scheduleBubbleAfterDelay(Duration delay) {
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(delay, () {
      if (!mounted || _bubbleTarget == null) return;
      setState(() {
        _showTyping = false;
        _bubbleText = _bubbleTarget;
      });
      HapticFeedback.selectionClick();
    });
  }

  UserEvent? _findRecentTarot(AsyncValue<List<UserEvent>> eventsAsync) {
    return eventsAsync.maybeWhen(
      data: (events) {
        final recent = events
            .where((e) => e.eventType == 'tarot_draw')
            .where((e) =>
                DateTime.now().toUtc().difference(e.createdAt).inHours < 4)
            .toList();
        if (recent.isEmpty) return null;
        recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return recent.first;
      },
      orElse: () => null,
    );
  }

  DateTime? _findLastSession(AsyncValue<List<UserEvent>> eventsAsync) {
    return eventsAsync.maybeWhen(
      data: (events) {
        final sessions =
            events.where((e) => e.eventType == 'session_start').toList();
        if (sessions.isEmpty) return null;
        sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sessions.first.createdAt;
      },
      orElse: () => null,
    );
  }

  String _resolveBubbleText({
    required String name,
    required SanctuaryState sanctuaryState,
    required UserEvent? recentTarot,
    required String? selectedMood,
    required DateTime? lastMoodSelectionAt,
    required bool recentMood,
    required String? existingMood,
    required DateTime? lastSessionAt,
  }) {
    final mood = selectedMood ?? existingMood;
    final now = DateTime.now().toUtc();
    if (_bubbleLockUntil != null && now.isBefore(_bubbleLockUntil!)) {
      return _bubbleTarget ?? nextTextFallback(name);
    }
    if (recentTarot != null) {
      final card = (recentTarot.eventPayload['card'] as String?) ?? '';
      final map = <String, List<String>>{
        'The Empress': [
          'Since The Empress appeared for you, your creative energy is peak. Shall we manifest?',
          'The Empress is close tonight. Let\'s nurture what wants to grow.',
          'The Empress is with you. Ready to create from abundance?',
        ],
        'The Star': [
          'The Star brought hope into your field today. Let\'s align your heart with that light.',
          'The Star shimmered for you. Shall we keep that light steady?',
          'The Star is guiding you tonight. Let\'s trust the glow.',
        ],
        'The Tower': [
          'Change can be loud, but you are the steady center. Let\'s stay grounded together.',
          'The Tower appeared. We\'ll move gently and keep you rooted.',
          'The Tower is here. We can hold this change with care.',
        ],
      };
      final options = map[card] ??
          [
            'A message arrived in the cards for you. Shall we move with it?',
            'Your guidance is fresh tonight. Let\'s align with it.',
            'The cards spoke softly. Let\'s listen together.',
          ];
      return _pick(options).replaceAll('[Name]', name);
    }

    if (mood != null &&
        lastMoodSelectionAt != null &&
        now.difference(lastMoodSelectionAt).inMinutes < 10) {
      final options = _mirrorMood(mood);
      return _pick(options).replaceAll('[Name]', name);
    }

    if (recentMood && mood != null) {
      final options = _mirrorMood(mood);
      return _pick(options).replaceAll('[Name]', name);
    }

    if (lastSessionAt != null && now.difference(lastSessionAt).inHours > 24) {
      return _pick([
        'You were missed, but your sanctuary never left. Ready to gently resume?',
        'It\'s been a minute, [Name]. Shall we return softly?',
        'Welcome back to the quiet, [Name]. Let\'s ease in.',
      ]).replaceAll('[Name]', name);
    }

    switch (sanctuaryState) {
      case SanctuaryState.sunrise:
        return _pick([
          'The morning light is fresh, [Name]. What intention shall we carry into the day?',
          'Sunrise is here, [Name]. What would you like to cultivate?',
          'A new day opens for you, [Name]. What intention feels right?',
        ]).replaceAll('[Name]', name);
      case SanctuaryState.daylight:
        return _pick([
          'You\'ve returned to your center, [Name]. Shall we continue our rhythm?',
          'The day holds you, [Name]. Ready to keep your momentum?',
          'Welcome back to your center, [Name]. Let\'s move with focus.',
        ]).replaceAll('[Name]', name);
      case SanctuaryState.twilight:
        return _pick([
          'The world is quieting down. What are you ready to release tonight?',
          'Twilight is soft, [Name]. What can we let go of?',
          'Evening settles in, [Name]. What would you like to release?',
        ]).replaceAll('[Name]', name);
    }
  }

  String nextTextFallback(String name) {
    return 'Welcome back, $name.';
  }

  List<String> _mirrorMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'inspired':
        return [
          'I can feel that spark. Let\'s channel this high frequency into your Abundance track.',
          'Your inspiration is bright. Let\'s move it into creation.',
          'That spark is alive. Let\'s pour it into what matters.',
        ];
      case 'overwhelmed':
        return [
          'I hear you. Let\'s keep things very gentle today. No pressure, just breathing.',
          'You\'re carrying a lot. We\'ll move softly and keep it light.',
          'Let\'s slow it all down. I\'m here with you.',
        ];
      case 'calm':
        return [
          'Peace looks good on you. This is the perfect state to deepen your awareness.',
          'Your calm is a gift. Let\'s settle into it together.',
          'You feel steady. Let\'s go deeper with ease.',
        ];
      case 'seeking':
        return [
          'The answers are already within you. Let\'s find a moment of stillness to hear them.',
          'You\'re seeking. Let\'s listen for the quiet truths.',
          'Let\'s create a still space and see what rises.',
        ];
      default:
        return [
          'I feel you. I\'ve prepared your sanctuary for this energy.',
        ];
    }
  }

  String _pick(List<String> options) {
    if (options.isEmpty) return '';
    return options[_rand.nextInt(options.length)];
  }

  void _setWishGlow() {
    _wishGlowTimer?.cancel();
    setState(() => _wishGlow = true);
    _wishGlowTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _wishGlow = false);
    });
  }

  _WishSnapshot? _findRecentWish(AsyncValue<List<UserEvent>> eventsAsync) {
    return eventsAsync.maybeWhen(
      data: (events) {
        final wishes =
            events.where((e) => e.eventType == 'wish_capture').toList();
        if (wishes.isEmpty) return null;
        wishes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final wish = wishes.first;
        return _WishSnapshot(
          wish: (wish.eventPayload['wish'] as String?) ?? '',
          frequency: (wish.eventPayload['frequency'] as String?) ?? '',
          createdAt: wish.createdAt,
        );
      },
      orElse: () => null,
    );
  }

  Color _wishGlowColor(String? frequency) {
    if (frequency == null) return const Color(0xFFFFD700);
    final normalized = frequency.toLowerCase();
    if (normalized.contains('abundance')) {
      return const Color(0xFFFFD700);
    }
    if (normalized.contains('love')) {
      return const Color(0xFFFFB6C1);
    }
    if (normalized.contains('inner') || normalized.contains('peace')) {
      return const Color(0xFF9370DB);
    }
    return const Color(0xFF00CED1);
  }

  Future<void> _submitWish() async {
    if (_isSubmittingWish) return;
    final wish = _wishController.text.trim();
    if (wish.isEmpty) return;
    setState(() => _isSubmittingWish = true);
    final frequency = _selectedFrequencies.isNotEmpty
        ? _selectedFrequencies.first
        : 'abundance';
    try {
      await UserEventsService.logEvent(
        eventType: 'wish_capture',
        payload: {'wish': wish, 'frequency': frequency},
      );
      setState(() {
        _currentWish = wish;
        _currentWishFrequency = frequency;
        _wishController.clear();
        _shouldPulseCta = true;
      });
      _forceBubble(
        "I feel you. I've prepared your sanctuary for this energy.",
      );
      _setWishGlow();
    } finally {
      if (mounted) {
        setState(() => _isSubmittingWish = false);
      }
    }
  }

  String _stateLabel(SanctuaryState state) {
    switch (state) {
      case SanctuaryState.sunrise:
        return 'SUNRISE';
      case SanctuaryState.daylight:
        return 'DAYLIGHT';
      case SanctuaryState.twilight:
        return 'TWILIGHT';
    }
  }

  String _displayLabel(String key) {
    switch (key) {
      case 'abundance':
        return 'Abundance';
      case 'inner_peace':
        return 'Inner Peace';
      case 'love':
        return 'Love';
      case 'health':
        return 'Vitality';
      default:
        return key;
    }
  }
}

class _HomeFrequencyOption {
  const _HomeFrequencyOption({
    required this.keyName,
    required this.title,
    required this.color,
  });

  final String keyName;
  final String title;
  final Color color;
}

const List<_HomeFrequencyOption> _homeFrequencyOptions = [
  _HomeFrequencyOption(
    keyName: 'abundance',
    title: 'Abundance',
    color: Color(0xFFFFD700),
  ),
  _HomeFrequencyOption(
    keyName: 'inner_peace',
    title: 'Inner Peace',
    color: Color(0xFF9370DB),
  ),
  _HomeFrequencyOption(
    keyName: 'love',
    title: 'Love',
    color: Color(0xFFFFB6C1),
  ),
  _HomeFrequencyOption(
    keyName: 'health',
    title: 'Vitality',
    color: Color(0xFF00CED1),
  ),
];

const List<String> _moodOptions = [
  'Calm',
  'Inspired',
  'Overwhelmed',
  'Seeking',
];

class _WishSnapshot {
  _WishSnapshot({
    required this.wish,
    required this.frequency,
    required this.createdAt,
  });

  final String wish;
  final String frequency;
  final DateTime createdAt;
}

class _WishIdea {
  _WishIdea({
    required this.ideaTitle,
    required this.ideaAction,
    required this.frequencyTag,
  });

  final String ideaTitle;
  final String ideaAction;
  final String frequencyTag;
}

class _WishIdeasSection extends StatefulWidget {
  const _WishIdeasSection({
    required this.wish,
    required this.frequency,
    required this.onTapIdea,
  });

  final String wish;
  final String? frequency;
  final ValueChanged<_WishIdea> onTapIdea;

  @override
  State<_WishIdeasSection> createState() => _WishIdeasSectionState();
}

class _WishIdeasSectionState extends State<_WishIdeasSection> {
  late Future<List<_WishIdea>> _ideasFuture;

  @override
  void initState() {
    super.initState();
    _ideasFuture = _fetchIdeas(widget.wish, widget.frequency);
  }

  @override
  void didUpdateWidget(covariant _WishIdeasSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wish != widget.wish ||
        oldWidget.frequency != widget.frequency) {
      _ideasFuture = _fetchIdeas(widget.wish, widget.frequency);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ideas to fuel this wish',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<_WishIdea>>(
            future: _ideasFuture,
            builder: (context, snapshot) {
              final ideas = snapshot.data ?? const <_WishIdea>[];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 110,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (ideas.isEmpty) {
                return Text(
                  'We are preparing ideas for you now.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                );
              }
              return SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final idea = ideas[index];
                    return _WishIdeaCard(
                      idea: idea,
                      onTap: () => widget.onTapIdea(idea),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: ideas.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<_WishIdea>> _fetchIdeas(
    String wish,
    String? frequency,
  ) async {
    final category = _detectCategory(wish);
    final query = Supabase.instance.client.from('wish_templates').select();
    final filtered = query.eq('category', category);
    if (frequency != null && frequency.isNotEmpty) {
      filtered.eq('frequency_tag', frequency);
    }
    final response = await filtered.limit(6);
    final list = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => _WishIdea(
            ideaTitle: (row['idea_title'] as String?) ?? 'Visualize',
            ideaAction: (row['idea_action'] as String?) ?? '',
            frequencyTag: (row['frequency_tag'] as String?) ?? 'abundance',
          ),
        )
        .toList();
    return list.take(3).toList();
  }

  String _detectCategory(String wish) {
    final lower = wish.toLowerCase();
    if (lower.contains('car') ||
        lower.contains('money') ||
        lower.contains('house') ||
        lower.contains('home') ||
        lower.contains('rent') ||
        lower.contains('wealth')) {
      return 'material';
    }
    if (lower.contains('love') ||
        lower.contains('relationship') ||
        lower.contains('partner')) {
      return 'love';
    }
    if (lower.contains('job') ||
        lower.contains('career') ||
        lower.contains('business')) {
      return 'career';
    }
    return 'material';
  }
}

class _WishIdeaCard extends StatelessWidget {
  const _WishIdeaCard({
    required this.idea,
    required this.onTap,
  });

  final _WishIdea idea;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              idea.ideaTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              idea.ideaAction,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  'Start 1-min ritual',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WishInputBubble extends StatelessWidget {
  const _WishInputBubble({
    required this.controller,
    required this.isSubmitting,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 1,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Whisper your wish...',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSubmitting ? null : onSend,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Icon(
                Icons.arrow_upward,
                size: 16,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveWishCard extends StatelessWidget {
  const _ActiveWishCard({
    required this.wish,
    required this.frequency,
    required this.glow,
  });

  final String wish;
  final String frequency;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            glow.withOpacity(0.32),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: glow.withOpacity(0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Wish',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            wish,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            frequency,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientTween extends Tween<LinearGradient> {
  _GradientTween({
    required LinearGradient begin,
    required LinearGradient end,
  }) : super(begin: begin, end: end);

  @override
  LinearGradient lerp(double t) {
    if (begin == null || end == null) return end!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(begin!.colors[0], end!.colors[0], t)!,
        Color.lerp(begin!.colors[1], end!.colors[1], t)!,
      ],
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 0.8,
              ),
            ),
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                textStyle: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 0.6,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HomeFrequencyChip extends StatelessWidget {
  const _HomeFrequencyChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.35),
            width: selected ? 1.3 : 0.6,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: selected ? 1.0 : 0.3,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(selected ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(selected ? 0.5 : 0.2),
              width: selected ? 1.2 : 0.6,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
