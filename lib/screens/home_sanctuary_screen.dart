import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

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
import '../widgets/shader_aura_orb.dart';
import '../models/program_type.dart';
import '../persistence/prefs.dart';
import '../theme/frequency_theme.dart';

enum HomeMode { intent, manifestation }

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
  late final AnimationController _wishFillController;
  late final AnimationController _wishShimmerController;
  late final Animation<double> _wishFillAnimation;
  late final AnimationController _ctaShimmerController;
  late final AnimationController _ritualPulseController;
  late final AudioPlayer _ritualPlayer;
  AudioPlayer? _ambiencePlayer;
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
  String? _activeRitualId;
  _WishIdea? _activeRitual;
  Timer? _ritualTimer;
  Duration _ritualRemaining = const Duration(seconds: 59);
  final Duration _ritualDuration = const Duration(seconds: 59);
  Color? _frequencyGlowColor;
  final Random _rand = Random();
  bool _shouldPulseCta = false;
  LinearGradient _currentGradient = themeForState(SanctuaryState.twilight)
      .gradient();
  LinearGradient _previousGradient = themeForState(SanctuaryState.twilight)
      .gradient();
  late final List<_CosmicStar> _cosmicStars;
  HomeMode _currentMode = HomeMode.intent;

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
    _ctaShimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _ritualPulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _wishFillController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    _wishFillAnimation = CurvedAnimation(
      parent: _wishFillController,
      curve: Curves.easeInOutCubic,
    );
    _wishShimmerController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _ritualPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

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
    _cosmicStars = _generateCosmicStars();

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
    _loadStoredWish();
  }

  @override
  void dispose() {
    _bloomController.dispose();
    _breathController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _listenerController.dispose();
    _ctaPulseController.dispose();
    _ctaShimmerController.dispose();
    _ritualPulseController.dispose();
    _wishFillController.dispose();
    _wishShimmerController.dispose();
    _ritualTimer?.cancel();
    _ritualPlayer.dispose();
    _ambiencePlayer?.dispose();
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

  Future<void> _loadStoredWish() async {
    final stored = await Prefs.loadActiveWish();
    if (stored == null || stored.trim().isEmpty) return;
    if (!mounted) return;
    setState(() {
      _currentWish = stored;
      _currentMode = HomeMode.manifestation;
    });
  }

  List<_CosmicStar> _generateCosmicStars() {
    final stars = <_CosmicStar>[];
    for (var i = 0; i < 70; i++) {
      final radius = 0.6 + _rand.nextDouble() * 1.6;
      final alpha = 0.3 + _rand.nextDouble() * 0.7;
      final phase = _rand.nextDouble() * pi * 2;
      stars.add(
        _CosmicStar(
          position: Offset(_rand.nextDouble(), _rand.nextDouble()),
          radius: radius,
          alpha: alpha,
          phase: phase,
        ),
      );
    }
    return stars;
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
    final selectedFrequencyKey =
        _normalizeFrequencyKey(activeSelections.firstOrNull ?? 'abundance');
    final forceAbundanceTheme = selectedFrequencyKey == 'abundance';
    final sanctuaryTheme = forceAbundanceTheme
        ? const SanctuaryThemeData(
            state: SanctuaryState.twilight,
            primary: Color(0xFF1A120D),
            secondary: Color(0xFFC58A32),
            tone: 'calm',
          )
        : themeForState(_state);
    final adaptiveTextColor = forceAbundanceTheme
        ? const Color(0xFFF7E8C8)
        : sanctuaryTheme.adaptiveTextColor;
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

    final recentWish = _findRecentWish(eventsAsync);
    final activeWish = _currentWish ?? recentWish?.wish;
    final activeWishFrequency =
        _currentWishFrequency ?? recentWish?.frequency;
    final wishActive = activeWish != null && activeWish.trim().isNotEmpty;
    final hasFrequency = activeSelections.isNotEmpty;
    final wishCategory =
        wishActive ? _detectCategory(activeWish ?? '') : null;
    final wishGlowColor = wishCategory == 'material'
        ? const Color(0xFFFFD700)
        : _wishGlowColor(activeWishFrequency ?? activeSelections.firstOrNull);
    late final List<RitualOption> activeRituals;
    late final Color activeRitualColor;
    switch (selectedFrequencyKey) {
      case 'love':
        activeRituals = loveRituals;
        activeRitualColor = const Color(0xFFE91E63);
        break;
      case 'inner_peace':
        activeRituals = peaceRituals;
        activeRitualColor = const Color(0xFF009688);
        break;
      case 'vitality':
        activeRituals = vitalityRituals;
        activeRitualColor = const Color(0xFFFF5722);
        break;
      case 'abundance':
      default:
        activeRituals = abundanceRituals;
        activeRitualColor = const Color(0xFFFFD700);
        break;
    }
    final greeting = tarot != null && tarot.trim().isNotEmpty
        ? '$name, the energy of $tarot is with you tonight.'
        : 'Good evening, $name.\nYour energy is transforming everything.';
    final listenerText = wishActive && hasFrequency
        ? 'I have aligned 3 paths for your $activeWish. Which micro-ritual calls to you?'
        : _resolveBubbleText(
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
    if (wishActive && !hasFrequency) {
      _ensureBubble(
        'Through which frequency shall we fuel this, $name?',
      );
    }
    if (wishActive && hasFrequency && _wishFillController.value == 0.0) {
      _wishFillController.forward(from: 0.0);
    }
    if (wishActive && _frequencyGlowColor != wishGlowColor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _applyFrequencyGlow(wishGlowColor);
      });
    }
    final showMoodChips = !recentMood && displayedMood == null;
    final pulseCta = _shouldPulseCta || displayedMood != null;
    if (pulseCta && !_ctaPulseController.isAnimating) {
      _ctaPulseController.repeat(reverse: true);
    }
    if (!pulseCta && _ctaPulseController.isAnimating) {
      _ctaPulseController.stop();
      _ctaPulseController.value = 1.0;
    }

    final displayGradient = forceAbundanceTheme
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFF1A120D),
              Color(0xFF5B3A16),
              Color(0xFFC58A32),
              Color(0xFFF6C76D),
            ],
            stops: const [0.0, 0.45, 0.75, 1.0],
          )
        : _currentGradient;
    final displayPrevGradient =
        forceAbundanceTheme ? displayGradient : _previousGradient;

    if (wishActive && _currentMode == HomeMode.intent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentMode = HomeMode.manifestation;
        });
      });
    }

    final shouldShowNav = false;
    if (ref.read(showBottomNavProvider) != shouldShowNav) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(showBottomNavProvider.notifier).state = shouldShowNav;
      });
    }

    final frequencyMode = _frequencyModeFromKey(
      activeWishFrequency ?? activeSelections.firstOrNull ?? 'abundance',
    );

    SystemChrome.setSystemUIOverlayStyle(
      forceAbundanceTheme || _state != SanctuaryState.daylight
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    Widget buildManifestation() {
      return LayoutBuilder(
        builder: (context, constraints) {
          Widget buildAura() {
            final size = constraints.maxHeight * 0.18;
            final combined = scale.value * breathScale.value;
            return AnimatedBuilder(
              animation: Listenable.merge([
                scale,
                breathScale,
                _wishFillController,
                _wishShimmerController,
              ]),
              builder: (context, child) {
                return Center(
                  child: Transform.scale(
                    scale: combined,
                    child: SizedBox(
                      height: size,
                      width: size,
                      child: CustomPaint(
                        painter: _WishOrbFillPainter(
                          fill: wishActive ? _wishFillAnimation.value : 0.0,
                          glow: wishGlowColor,
                          shimmer: _wishShimmerController.value,
                        ),
                        child: ShaderAuraOrb(
                          primary: wishActive
                              ? const Color(0xFFFFD700)
                              : (colors.isNotEmpty
                                  ? colors.first
                                  : AlignaColors.accent),
                          secondary: wishActive
                              ? const Color(0xFFFFD700)
                              : (colors.length > 1
                                  ? colors[1]
                                  : AlignaColors.primary),
                          intensity: 1.0,
                          size: size,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          Widget buildManifestStage() {
            final carouselHeight = (constraints.maxHeight * 0.26)
                .clamp(150.0, 210.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                buildAura(),
                const SizedBox(height: 10),
                ActiveWishHeader(wish: activeWish!),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Your ${_displayLabel(activeSelections.firstOrNull ?? 'abundance')} Rituals',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: adaptiveTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: carouselHeight,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeRituals.length,
                    itemBuilder: (context, index) {
                      final ritual = activeRituals[index];
                      return RitualGlassCard(
                        ritual: ritual,
                        frequencyColor: activeRitualColor,
                        onTap: () {
                          _setWishGlow();
                          _startRitualFromOption(ritual);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }

          Widget buildCta() {
            return SlideTransition(
              position: buttonSlide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
                child: AnimatedBuilder(
                  animation: _ctaPulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_ctaPulseController.value * 0.03);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _activeRitualId == null
                        ? _ShimmerButton(
                            key: const ValueKey('fuel'),
                            shimmer: wishActive,
                            controller: _ctaShimmerController,
                            child: _GlassActionButton(
                              label: 'Fuel This ${_displayLabel(activeSelections.firstOrNull ?? 'abundance')}',
                              onPressed: wishActive && !hasFrequency
                                  ? null
                                  : () async {
                                      await HapticFeedback.lightImpact();
                                      if (wishActive && hasFrequency) {
                                        final freq =
                                            activeSelections.firstOrNull ?? 'abundance';
                                        ref
                                            .read(selectedProgramTypeProvider.notifier)
                                            .state = _frequencyToProgramType(freq);
                                      }
                                      ref
                                          .read(shellTabIndexProvider.notifier)
                                          .state = 2;
                                    },
                            ),
                          )
                        : _RitualPlayerBar(
                            key: const ValueKey('ritual'),
                            icon: _ritualIconForIdea(
                              _activeRitual?.ideaAction ?? '',
                            ),
                            title: _activeRitual?.ideaTitle ?? 'Visualizing...',
                            remaining: _ritualRemaining,
                            progress: _ritualProgress(),
                            glow: wishGlowColor,
                            pulse: _ritualPulseController,
                            onStop: _stopRitual,
                          ),
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(child: buildManifestStage()),
              buildCta(),
            ],
          );
        },
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedNebulaBackground(currentMode: frequencyMode),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    const Color(0xFF050510).withOpacity(0.8),
                  ],
                  stops: const [0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CosmicStardust(starCount: 60),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                if (_currentMode == HomeMode.intent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Text(
                      'Whisper your wish, $name...',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w100,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  flex: 6,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeInQuart,
                  child: _currentMode == HomeMode.intent
                      ? PremiumGlassInput(
                          key: const ValueKey('Input'),
                          userName: name,
                          onSubmitted: (wish) async {
                            HapticFeedback.heavyImpact();
                            await _handleWishCommit(wish);
                          },
                          onSkip: _handleWishSkip,
                        )
                      : buildManifestation(),
                  ),
                ),
                const Spacer(flex: 2),
              ],
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

  void _forceBubble(String nextText, {Duration delay = const Duration(milliseconds: 1200)}) {
    _bubbleTarget = nextText;
    _bubbleText = null;
    _showTyping = true;
    _bubbleLockUntil = DateTime.now().toUtc().add(const Duration(minutes: 5));
    _scheduleBubbleAfterDelay(delay);
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

  void _applyFrequencyGlow(Color color) {
    if (_frequencyGlowColor == color) return;
    final base = themeForState(_state).gradient();
    final strength = _state == SanctuaryState.twilight ? 0.55 : 0.75;
    final blended = Color.lerp(base.colors[1], color, strength) ?? color;
    setState(() {
      _frequencyGlowColor = color;
      _previousGradient = _currentGradient;
      _currentGradient = LinearGradient(
        begin: base.begin,
        end: base.end,
        colors: [
          base.colors.first,
          blended,
        ],
      );
    });
  }

  Future<void> _startRitual(_WishIdea idea) async {
    _ritualTimer?.cancel();
    setState(() {
      _activeRitualId = idea.id;
      _activeRitual = idea;
      _ritualRemaining = _ritualDuration;
    });
    await _fadeAmbience(0.0);
    await _playRitualAudio(idea);
    _ritualTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_ritualRemaining.inSeconds <= 1) {
        _completeRitual();
        return;
      }
      setState(() {
        _ritualRemaining =
            Duration(seconds: _ritualRemaining.inSeconds - 1);
      });
    });
  }

  Future<void> _completeRitual() async {
    _ritualTimer?.cancel();
    await _ritualPlayer.stop();
    await _fadeAmbience(1.0);
    if (!mounted) return;
    setState(() {
      _activeRitualId = null;
      _activeRitual = null;
      _ritualRemaining = _ritualDuration;
    });
  }

  Future<void> _stopRitual() async {
    _ritualTimer?.cancel();
    await _ritualPlayer.stop();
    await _fadeAmbience(1.0);
    if (!mounted) return;
    setState(() {
      _activeRitualId = null;
      _activeRitual = null;
      _ritualRemaining = _ritualDuration;
    });
  }

  Future<void> _playRitualAudio(_WishIdea idea) async {
    final source = _ritualAssetForIdea(idea.ideaAction);
    try {
      await _ritualPlayer.stop();
      await _ritualPlayer.play(AssetSource(source), volume: 0.9);
    } catch (e) {
      debugPrint('[HomeSanctuary] Ritual audio failed: $e');
    }
  }

  Future<void> _fadeAmbience(double target) async {
    final ambience = _ambiencePlayer;
    if (ambience == null) return;
    const steps = 5;
    final current = 1.0;
    final delta = (target - current) / steps;
    for (var i = 1; i <= steps; i++) {
      await ambience.setVolume(current + delta * i);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  String _ritualAssetForIdea(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('feel') ||
        lower.contains('smell') ||
        lower.contains('touch') ||
        lower.contains('hear')) {
      return 'audio/rituals/visualize_texture.mp3';
    }
    if (lower.contains('research') ||
        lower.contains('find') ||
        lower.contains('list') ||
        lower.contains('update')) {
      return 'audio/rituals/focus_drone.mp3';
    }
    return 'audio/rituals/affirmation_echo.mp3';
  }

  IconData _ritualIconForIdea(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('feel') ||
        lower.contains('smell') ||
        lower.contains('touch') ||
        lower.contains('hear')) {
      return Icons.diamond;
    }
    if (lower.contains('research') ||
        lower.contains('find') ||
        lower.contains('list') ||
        lower.contains('update')) {
      return Icons.psychology;
    }
    return Icons.emoji_objects;
  }

  double _ritualProgress() {
    final remaining = _ritualRemaining.inSeconds.toDouble();
    final total = _ritualDuration.inSeconds.toDouble();
    if (total == 0) return 0.0;
    return (1.0 - (remaining / total)).clamp(0.0, 1.0);
  }

  void _setWishGlow() {
    _wishGlowTimer?.cancel();
    setState(() => _wishGlow = true);
    _wishGlowTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _wishGlow = false);
    });
  }

  String _normalizeFrequencyKey(String value) {
    return value.toLowerCase().replaceAll(' ', '_');
  }

  void _startRitualFromOption(RitualOption ritual) {
    final idea = _WishIdea(
      id: ritual.title.toLowerCase().replaceAll(' ', '-'),
      ideaTitle: ritual.title,
      ideaAction: ritual.description,
      frequencyTag: 'abundance',
      category: 'material',
    );
    _startRitual(idea);
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

  ProgramType _frequencyToProgramType(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'abundance':
        return ProgramType.money;
      case 'love':
        return ProgramType.love;
      case 'inner_peace':
        return ProgramType.support;
      case 'health':
      case 'vitality':
        return ProgramType.health;
      default:
        return ProgramType.support;
    }
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
      await Prefs.saveActiveWish(wish);
      setState(() {
        _currentWish = wish;
        _currentWishFrequency = frequency;
        _wishController.clear();
        _shouldPulseCta = true;
      });
      _forceBubble(
        'I am aligning the field for your $wish...',
        delay: const Duration(milliseconds: 1500),
      );
      _setWishGlow();
      await _wishFillController.forward(from: 0.0);
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
        await _wishShimmerController.forward(from: 0.0);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingWish = false);
      }
    }
  }

  Future<void> _handleWishCommit(String wish) async {
    _wishController.text = wish;
    await _submitWish();
    if (!mounted) return;
    setState(() {
      _currentMode = HomeMode.manifestation;
    });
  }

  void _handleWishSkip() {
    if ((_currentWish ?? '').trim().isEmpty) {
      setState(() {
        _currentWish = 'Your intention';
        _currentWishFrequency = _selectedFrequencies.isNotEmpty
            ? _selectedFrequencies.first
            : 'abundance';
      });
    }
    setState(() {
      _currentMode = HomeMode.manifestation;
    });
  }

  FrequencyMode _frequencyModeFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'love':
        return FrequencyMode.love;
      case 'vitality':
      case 'health':
        return FrequencyMode.vitality;
      case 'inner_peace':
      case 'peace':
        return FrequencyMode.peace;
      case 'abundance':
      default:
        return FrequencyMode.abundance;
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

class _WishOrbFillPainter extends CustomPainter {
  _WishOrbFillPainter({
    required this.fill,
    required this.glow,
    required this.shimmer,
  });

  final double fill;
  final Color glow;
  final double shimmer;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final circleRect = Rect.fromCircle(center: center, radius: radius);

    if (fill > 0) {
      canvas.save();
      canvas.clipPath(Path()..addOval(circleRect));
      final fillHeight = size.height * fill.clamp(0.0, 1.0);
      final fillRect = Rect.fromLTWH(
        0,
        size.height - fillHeight,
        size.width,
        fillHeight,
      );
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            glow.withOpacity(0.1),
            glow.withOpacity(0.65),
          ],
        ).createShader(fillRect);
      canvas.drawRect(fillRect, fillPaint);
      canvas.restore();
    }

    if (shimmer > 0) {
      final shimmerPaint = Paint()
        ..color = Colors.white.withOpacity(0.6 * (1 - shimmer))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final start = -pi / 2 + shimmer * pi * 2;
      canvas.drawArc(
        circleRect.deflate(4),
        start,
        pi / 5,
        false,
        shimmerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WishOrbFillPainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.glow != glow ||
        oldDelegate.shimmer != shimmer;
  }
}

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

String _detectCategory(String wish) {
  final lower = wish.toLowerCase();
  if (lower.contains('car') ||
      lower.contains('money') ||
      lower.contains('house') ||
      lower.contains('home') ||
      lower.contains('rent') ||
      lower.contains('wealth') ||
      lower.contains('business') ||
      lower.contains('job') ||
      lower.contains('career') ||
      lower.contains('promotion')) {
    return 'material';
  }
  if (lower.contains('love') ||
      lower.contains('relationship') ||
      lower.contains('partner') ||
      lower.contains('friend') ||
      lower.contains('family')) {
    return 'love';
  }
  return 'career';
}

class _WishIdea {
  _WishIdea({
    required this.id,
    required this.ideaTitle,
    required this.ideaAction,
    required this.frequencyTag,
    required this.category,
  });

  final String id;
  final String ideaTitle;
  final String ideaAction;
  final String frequencyTag;
  final String category;
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

class _WishIdeasSectionState extends State<_WishIdeasSection>
    with SingleTickerProviderStateMixin {
  late Future<List<_WishIdea>> _ideasFuture;
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _ideasFuture = _fetchIdeas(widget.wish, widget.frequency);
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _WishIdeasSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wish != widget.wish ||
        oldWidget.frequency != widget.frequency) {
      _ideasFuture = _fetchIdeas(widget.wish, widget.frequency);
      _staggerController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
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
                    final animation = CurvedAnimation(
                      parent: _staggerController,
                      curve: Interval(
                        0.05 * index,
                        0.5 + 0.05 * index,
                        curve: Curves.easeOutBack,
                      ),
                    );
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: animation.value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - animation.value)),
                            child: child,
                          ),
                        );
                      },
                      child: _WishIdeaCard(
                        idea: idea,
                        onTap: () => widget.onTapIdea(idea),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: ideas.length,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<List<_WishIdea>> _fetchIdeas(
    String wish,
    String? frequency,
  ) async {
    final category = _detectCategory(wish);
    try {
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
              id: (row['id'] as String?) ??
                  (row['idea_title'] as String?) ??
                  'idea',
              ideaTitle: (row['idea_title'] as String?) ?? 'Visualize',
              ideaAction: (row['idea_action'] as String?) ?? '',
              frequencyTag: (row['frequency_tag'] as String?) ?? 'abundance',
              category: category,
            ),
          )
          .toList();
      if (list.isNotEmpty) {
        return list.take(3).toList();
      }
    } catch (_) {
      // Fall through to defaults.
    }
    return _defaultIdeas(category);
  }

  List<_WishIdea> _defaultIdeas(String category) {
    if (category == 'love') {
      return [
        _WishIdea(
          id: 'love-warmth',
          ideaTitle: 'Warmth of a hand',
          ideaAction: 'Feel the warmth of a hand holding yours.',
          frequencyTag: 'love',
          category: 'love',
        ),
        _WishIdea(
          id: 'love-traits',
          ideaTitle: 'Traits you offer',
          ideaAction: 'List 3 traits you offer to a partner.',
          frequencyTag: 'love',
          category: 'love',
        ),
        _WishIdea(
          id: 'love-affirm',
          ideaTitle: 'Identity affirmation',
          ideaAction: 'I am a magnet for healthy, deep love.',
          frequencyTag: 'love',
          category: 'love',
        ),
      ];
    }
    if (category == 'career') {
      return [
        _WishIdea(
          id: 'career-email',
          ideaTitle: 'Hear the email',
          ideaAction: "Hear the sound of a 'Congratulations' email.",
          frequencyTag: 'career',
          category: 'career',
        ),
        _WishIdea(
          id: 'career-title',
          ideaTitle: 'Title update',
          ideaAction: 'Update one word in your bio to your new title.',
          frequencyTag: 'career',
          category: 'career',
        ),
        _WishIdea(
          id: 'career-affirm',
          ideaTitle: 'Identity affirmation',
          ideaAction: 'My expertise is valued and rewarded.',
          frequencyTag: 'career',
          category: 'career',
        ),
      ];
    }
    return [
      _WishIdea(
        id: 'material-keys',
        ideaTitle: 'Sense the keys',
        ideaAction: 'Feel the texture of the keys in your palm.',
        frequencyTag: 'abundance',
        category: 'material',
      ),
      _WishIdea(
        id: 'material-color',
        ideaTitle: 'Find the color',
        ideaAction: 'Find the exact model\'s hex-color code.',
        frequencyTag: 'abundance',
        category: 'material',
      ),
      _WishIdea(
        id: 'material-affirm',
        ideaTitle: 'Identity affirmation',
        ideaAction: 'I embody the success this item represents.',
        frequencyTag: 'abundance',
        category: 'material',
      ),
    ];
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
    final icon = _ideaIcon(idea.ideaAction);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                Row(
                  children: [
                    Icon(icon, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        idea.ideaTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
        ),
      ),
    );
  }

  IconData _ideaIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('feel') ||
        lower.contains('smell') ||
        lower.contains('touch') ||
        lower.contains('hear')) {
      return Icons.diamond;
    }
    if (lower.contains('find') ||
        lower.contains('research') ||
        lower.contains('list') ||
        lower.contains('update')) {
      return Icons.psychology;
    }
    return Icons.emoji_objects;
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
    final champagneLight = Color.lerp(Colors.white, glow, 0.65) ?? glow;
    final champagneMid = Color.lerp(champagneLight, glow, 0.4) ?? glow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            champagneLight.withOpacity(0.38),
            const Color(0xFF2B1B12).withOpacity(0.35),
          ],
        ),
        border: Border.all(
          color: champagneMid.withOpacity(0.45),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: champagneMid.withOpacity(0.35),
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
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            wish,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            frequency,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class RitualOption {
  final String title;
  final String description;
  final IconData icon;
  final String duration;

  const RitualOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.duration,
  });
}

const List<RitualOption> abundanceRituals = [
  RitualOption(
    title: 'Sense the Keys',
    description:
        'Close your eyes. Feel the cool metal and weight of the keys in your palm.',
    icon: Icons.diamond_outlined,
    duration: '1 min',
  ),
  RitualOption(
    title: 'Find the Color',
    description: 'Search for the exact hex-code of your dream car paint.',
    icon: Icons.psychology_outlined,
    duration: '2 min',
  ),
  RitualOption(
    title: 'Claim Upgrade',
    description: "Speak aloud: 'I am fully ready for this safety.'",
    icon: Icons.candlestick_chart_outlined,
    duration: '1 min',
  ),
];

const List<RitualOption> loveRituals = [
  RitualOption(
    title: 'Open the Heart',
    description:
        'Visualize a soft pink light expanding from your chest with every breath.',
    icon: Icons.favorite_border,
    duration: '1 min',
  ),
  RitualOption(
    title: 'Release Barriers',
    description: 'Identify one wall you\'ve built. Watch it dissolve into mist.',
    icon: Icons.lock_open_rounded,
    duration: '2 min',
  ),
  RitualOption(
    title: 'Send Gratitude',
    description:
        'Picture someone you love. Send them a silent wave of thanks.',
    icon: Icons.send_rounded,
    duration: '1 min',
  ),
];

const List<RitualOption> peaceRituals = [
  RitualOption(
    title: 'Breathe Blue',
    description: 'Inhale calm blue energy. Exhale grey static noise.',
    icon: Icons.air,
    duration: '1 min',
  ),
  RitualOption(
    title: 'The Still Point',
    description: 'Find the silence between your thoughts. Rest there.',
    icon: Icons.nights_stay_outlined,
    duration: '2 min',
  ),
  RitualOption(
    title: 'Grounding Cord',
    description: 'Visualize a root connecting you to the center of the earth.',
    icon: Icons.nature,
    duration: '1 min',
  ),
];

const List<RitualOption> vitalityRituals = [
  RitualOption(
    title: 'Ignite the Spark',
    description: 'Feel a golden fire starting in your solar plexus.',
    icon: Icons.bolt,
    duration: '1 min',
  ),
  RitualOption(
    title: 'Body Scan',
    description:
        'Sweep your attention from toes to head, waking up every cell.',
    icon: Icons.accessibility_new,
    duration: '2 min',
  ),
  RitualOption(
    title: 'Morning Sun',
    description: 'Visualize sunlight filling your bones with strength.',
    icon: Icons.wb_sunny_outlined,
    duration: '1 min',
  ),
];

class RitualGlassCard extends StatelessWidget {
  const RitualGlassCard({
    super.key,
    required this.ritual,
    required this.onTap,
    required this.frequencyColor,
  });

  final RitualOption ritual;
  final VoidCallback onTap;
  final Color frequencyColor;

  @override
  Widget build(BuildContext context) {
    final glowLight = Color.lerp(Colors.white, frequencyColor, 0.7) ??
        frequencyColor;
    final glowMedium = Color.lerp(glowLight, frequencyColor, 0.45) ??
        frequencyColor;
    final glowDark = Color.lerp(frequencyColor, const Color(0xFF6B4A1F), 0.25) ??
        frequencyColor;
    const glassBase = Color(0xFF2B1B12);

    return Container(
      width: 250,
      height: 300,
      margin: const EdgeInsets.only(right: 16),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glowLight.withOpacity(0.8),
                  glowMedium.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.5),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    decoration: BoxDecoration(
                      color: glassBase.withOpacity(0.68),
                      borderRadius: BorderRadius.circular(28.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(ritual.icon, size: 48, color: glowLight),
                        const SizedBox(height: 16),
                        Text(
                          ritual.title,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ritual.description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 0.9,
                    colors: [
                      glowLight,
                      glowMedium,
                      glowDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowDark.withOpacity(0.6),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Positioned(
                      top: 10,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x66FFFFFF),
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF1A1A2E),
                      size: 36,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualPlayerBar extends StatelessWidget {
  const _RitualPlayerBar({
    super.key,
    required this.icon,
    required this.title,
    required this.remaining,
    required this.progress,
    required this.glow,
    required this.onStop,
    required this.pulse,
  });

  final IconData icon;
  final String title;
  final Duration remaining;
  final double progress;
  final Color glow;
  final VoidCallback onStop;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.6,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: glow.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: pulse,
                  builder: (context, child) {
                    final scale = 1.0 + (pulse.value * 0.08);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visualizing... ${_formatCountdown(remaining)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onStop,
                  icon: const Icon(Icons.cancel, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCountdown(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
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

class _GoldRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.18);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x66F6C76D);

    final rings = [
      size.width * 0.55,
      size.width * 0.8,
      size.width * 1.05,
    ];
    for (final radius in rings) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ActiveWishHeader extends StatelessWidget {
  const ActiveWishHeader({super.key, required this.wish});

  final String wish;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CURRENT FOCUS',
            style: GoogleFonts.manrope(
              fontSize: 10,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            wish,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 15,
                )
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class RichNebulaBackground extends StatefulWidget {
  const RichNebulaBackground({super.key});

  @override
  State<RichNebulaBackground> createState() => _RichNebulaBackgroundState();
}

class _RichNebulaBackgroundState extends State<RichNebulaBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F0C29),
                Color(0xFF302B63),
                Color(0xFF24243E),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * pi;
            return Stack(
              children: [
                _buildBlob(
                  color: const Color(0xFFFF00CC).withOpacity(0.35),
                  alignment: _getAlignment(t, 1.0, 0, 0.5),
                  radius: 350,
                ),
                _buildBlob(
                  color: const Color(0xFF6E00FF).withOpacity(0.4),
                  alignment: _getAlignment(t, 0.8, 2.0, 0.7),
                  radius: 400,
                ),
                _buildBlob(
                  color: const Color(0xFF00F2FF).withOpacity(0.3),
                  alignment: _getAlignment(t, 1.2, 4.0, 0.6),
                  radius: 300,
                ),
                _buildBlob(
                  color: const Color(0xFF000428).withOpacity(0.6),
                  alignment: _getAlignment(t, 0.5, 1.0, 0.4),
                  radius: 450,
                ),
                _buildBlob(
                  color: const Color(0xFF00FF99).withOpacity(0.15),
                  alignment: _getAlignment(t, 0.9, 5.0, 0.8),
                  radius: 250,
                ),
              ],
            );
          },
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90.0, sigmaY: 90.0),
          child: Container(color: Colors.transparent),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Alignment _getAlignment(
    double time,
    double speed,
    double offset,
    double range,
  ) {
    final x = sin((time * speed) + offset) * range;
    final y = cos((time * (speed * 0.7)) + offset) * range;
    return Alignment(x, y);
  }

  Widget _buildBlob({
    required Color color,
    required Alignment alignment,
    required double radius,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class CosmicStardust extends StatefulWidget {
  const CosmicStardust({super.key, required this.starCount});

  final int starCount;

  @override
  State<CosmicStardust> createState() => _CosmicStardustState();
}

class _CosmicStardustState extends State<CosmicStardust>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_StardustParticle> _particles;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _particles = List.generate(widget.starCount, (_) {
      return _StardustParticle(
        position: Offset(_rand.nextDouble(), _rand.nextDouble()),
        radius: 0.8 + _rand.nextDouble() * 1.4,
        twinkleSpeed: 2 + _rand.nextDouble() * 4,
        driftSpeed: 0.3 + _rand.nextDouble() * 0.7,
        phase: _rand.nextDouble() * pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _StardustPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _StardustParticle {
  const _StardustParticle({
    required this.position,
    required this.radius,
    required this.twinkleSpeed,
    required this.driftSpeed,
    required this.phase,
  });

  final Offset position;
  final double radius;
  final double twinkleSpeed;
  final double driftSpeed;
  final double phase;
}

class _StardustPainter extends CustomPainter {
  const _StardustPainter({
    required this.particles,
    required this.progress,
  });

  final List<_StardustParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final star in particles) {
      final twinkle = (sin(progress * pi * 2 * star.twinkleSpeed + star.phase) +
              1) *
          0.5;
      final alpha = 0.2 + (twinkle * 0.6);
      paint.color = Colors.white.withOpacity(alpha);
      final dyShift = -10 * progress * star.driftSpeed;
      final position = Offset(
        size.width * star.position.dx,
        size.height * star.position.dy + dyShift,
      );
      canvas.drawCircle(position, star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StardustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class PremiumGlassInput extends StatefulWidget {
  const PremiumGlassInput({
    super.key,
    required this.userName,
    required this.onSubmitted,
    required this.onSkip,
  });

  final String userName;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSkip;

  @override
  State<PremiumGlassInput> createState() => _PremiumGlassInputState();
}

class AnimatedNebulaBackground extends StatelessWidget {
  const AnimatedNebulaBackground({super.key, required this.currentMode});

  final FrequencyMode currentMode;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1200),
      switchInCurve: Curves.easeInOutSine,
      switchOutCurve: Curves.easeInOutSine,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<String>(FrequencyTheme.getAsset(currentMode)),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(FrequencyTheme.getAsset(currentMode)),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2),
              BlendMode.darken,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumGlassInputState extends State<PremiumGlassInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showArrow = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final shouldShow = _controller.text.trim().isNotEmpty;
      if (shouldShow != _showArrow) {
        setState(() => _showArrow = shouldShow);
      }
    });
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 24,
          child: GestureDetector(
            onTap: widget.onSkip,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 340,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  color: _focusNode.hasFocus
                      ? Colors.white.withOpacity(0.12)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white.withOpacity(0.15),
                    width: 0.8,
                  ),
                  boxShadow: _focusNode.hasFocus
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.05),
                            blurRadius: 20,
                            spreadRadius: 0,
                          )
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    hintText: 'Whisper your wish...',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 20,
                      fontWeight: FontWeight.w200,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: AnimatedOpacity(
                      opacity: _showArrow ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: GestureDetector(
                        onTap: _submit,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CosmicStar {
  const _CosmicStar({
    required this.position,
    required this.radius,
    required this.alpha,
    required this.phase,
  });

  final Offset position;
  final double radius;
  final double alpha;
  final double phase;
}

class _CosmicBackdropPainter extends CustomPainter {
  const _CosmicBackdropPainter({
    required this.stars,
    required this.twinkle,
    required this.drift,
  });

  final List<_CosmicStar> stars;
  final double twinkle;
  final Offset drift;

  @override
  void paint(Canvas canvas, Size size) {
    final hazePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 0.9,
        colors: [
          const Color(0x33C9D3FF),
          const Color(0x00232738),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.2),
        radius: size.width * 0.9,
      ));
    canvas.drawRect(Offset.zero & size, hazePaint);

    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in stars) {
      final twinklePhase = (sin(twinkle * pi * 2 + star.phase) + 1) * 0.5;
      final alpha = (star.alpha * (0.6 + (twinklePhase * 0.4)))
          .clamp(0.0, 1.0);
      starPaint.color = Colors.white.withOpacity(alpha);
      final position = Offset(
            size.width * star.position.dx,
            size.height * star.position.dy,
          ) +
          drift;
      canvas.drawCircle(position, star.radius, starPaint);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0x33E7E7FF);
    for (var i = 0; i < stars.length - 2; i += 12) {
      final p1 = Offset(
            size.width * stars[i].position.dx,
            size.height * stars[i].position.dy,
          ) +
          drift;
      final p2 = Offset(
            size.width * stars[i + 1].position.dx,
            size.height * stars[i + 1].position.dy,
          ) +
          drift;
      final p3 = Offset(
            size.width * stars[i + 2].position.dx,
            size.height * stars[i + 2].position.dy,
          ) +
          drift;
      canvas.drawLine(p1, p2, linePaint);
      canvas.drawLine(p2, p3, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBackdropPainter oldDelegate) {
    return oldDelegate.twinkle != twinkle || oldDelegate.drift != drift;
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

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
                foregroundColor: onPressed == null
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white,
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

class _ShimmerButton extends StatelessWidget {
  const _ShimmerButton({
    super.key,
    required this.shimmer,
    required this.controller,
    required this.child,
  });

  final bool shimmer;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!shimmer) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1 + t * 2, -1),
              end: Alignment(1 + t * 2, 1),
              colors: const [
                Color(0x00FFFFFF),
                Color(0x66FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
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
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipBackground =
        selected ? color.withOpacity(0.2) : backgroundColor;
    final chipBorder = selected ? color : borderColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: chipBorder,
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
            color: textColor,
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
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipBackground =
        selected ? backgroundColor.withOpacity(0.6) : backgroundColor;
    final chipBorder =
        selected ? borderColor.withOpacity(0.7) : borderColor;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: selected ? 1.0 : 0.3,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: chipBorder,
              width: selected ? 1.2 : 0.6,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.25),
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
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}


